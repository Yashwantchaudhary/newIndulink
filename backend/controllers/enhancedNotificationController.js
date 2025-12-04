const EnhancedNotification = require('../models/EnhancedNotification');
const NotificationTemplate = require('../models/NotificationTemplate');
const enhancedNotificationService = require('../services/enhancedNotificationService');
const User = require('../models/User');

// @desc    Create a new notification
// @route   POST /api/notifications/enhanced
// @access  Private (Admin only)
exports.createNotification = async (req, res, next) => {
  try {
    const {
      title, body, type, data,
      channels, templateId, templateVariables,
      emailContent, smsContent, pushContent, inAppContent,
      targetUsers, targetRole, targetCriteria,
      scheduledTime, priority, routingRules, fallbackChannels
    } = req.body;

    // Validate required fields
    if (!title || !body || !channels || channels.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Title, body, and at least one channel are required'
      });
    }

    // Create notification data
    const notificationData = {
      title,
      body,
      type: type || 'system',
      data: data || {},
      channels,
      templateId,
      templateVariables: templateVariables || {},
      emailContent: emailContent || {},
      smsContent: smsContent || {},
      pushContent: pushContent || {},
      inAppContent: inAppContent || {},
      targetUsers,
      targetRole,
      targetCriteria: targetCriteria || {},
      scheduledTime: scheduledTime ? new Date(scheduledTime) : null,
      priority: priority || 'medium',
      routingRules: routingRules || {},
      fallbackChannels: fallbackChannels || [],
      createdBy: req.user.id,
      status: scheduledTime ? 'scheduled' : 'draft'
    };

    // Create notification
    const notification = await enhancedNotificationService.createNotification(notificationData);

    // Send immediately if not scheduled
    if (!scheduledTime) {
      const result = await enhancedNotificationService.sendNotification(notification._id);
      return res.status(200).json({
        success: true,
        message: 'Notification created and sent successfully',
        data: { notification, result }
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification created and scheduled successfully',
      data: notification
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Send a notification immediately
// @route   POST /api/notifications/enhanced/:id/send
// @access  Private (Admin only)
exports.sendNotification = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await enhancedNotificationService.sendNotification(id);

    res.status(200).json({
      success: true,
      message: 'Notification sent successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all notifications
// @route   GET /api/notifications/enhanced
// @access  Private (Admin only)
exports.getNotifications = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      type,
      channel,
      priority,
      startDate,
      endDate,
      search
    } = req.query;

    const query = {};

    if (status) query.status = status;
    if (type) query.type = type;
    if (priority) query.priority = priority;
    if (channel) query.channels = channel;

    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { body: { $regex: search, $options: 'i' } },
        { 'data.keyword': { $regex: search, $options: 'i' } }
      ];
    }

    const notifications = await EnhancedNotification.find(query)
      .populate('createdBy', 'firstName lastName email')
      .populate('templateId', 'name category type')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await EnhancedNotification.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        notifications,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get notification by ID
// @route   GET /api/notifications/enhanced/:id
// @access  Private
exports.getNotification = async (req, res, next) => {
  try {
    const { id } = req.params;

    const notification = await EnhancedNotification.findById(id)
      .populate('createdBy', 'firstName lastName email')
      .populate('templateId', 'name category type content variables')
      .populate('targetUsers', 'firstName lastName email phone');

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      data: notification
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update notification
// @route   PUT /api/notifications/enhanced/:id
// @access  Private (Admin only)
exports.updateNotification = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const notification = await EnhancedNotification.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification updated successfully',
      data: notification
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/enhanced/:id
// @access  Private (Admin only)
exports.deleteNotification = async (req, res, next) => {
  try {
    const { id } = req.params;

    const notification = await EnhancedNotification.findByIdAndDelete(id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get notification delivery status
// @route   GET /api/notifications/enhanced/:id/status
// @access  Private
exports.getNotificationStatus = async (req, res, next) => {
  try {
    const { id } = req.params;

    const notification = await EnhancedNotification.findById(id)
      .select('status deliveryStatus engagementMetrics channels');

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      success: true,
      data: {
        overallStatus: notification.overallStatus,
        deliveryStatus: notification.deliveryStatus,
        engagementMetrics: notification.engagementMetrics,
        channelPerformance: this.calculateChannelPerformance(notification)
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get notification statistics
// @route   GET /api/notifications/enhanced/stats
// @access  Private (Admin only)
exports.getNotificationStats = async (req, res, next) => {
  try {
    const { timeframe = '30d' } = req.query;

    const stats = await enhancedNotificationService.getNotificationStats(timeframe);
    const channelPerformance = await enhancedNotificationService.getChannelPerformance();

    res.status(200).json({
      success: true,
      data: { stats, channelPerformance }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get detailed analytics
// @route   GET /api/notifications/enhanced/analytics
// @access  Private (Admin only)
exports.getDetailedAnalytics = async (req, res, next) => {
  try {
    const { timeframe = '30d' } = req.query;

    const analytics = await enhancedNotificationService.getDetailedAnalytics(timeframe);

    res.status(200).json({
      success: true,
      data: analytics
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get performance trends
// @route   GET /api/notifications/enhanced/trends
// @access  Private (Admin only)
exports.getPerformanceTrends = async (req, res, next) => {
  try {
    const trends = await enhancedNotificationService.getPerformanceTrends();

    res.status(200).json({
      success: true,
      data: trends
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get notification effectiveness
// @route   GET /api/notifications/enhanced/effectiveness
// @access  Private (Admin only)
exports.getNotificationEffectiveness = async (req, res, next) => {
  try {
    const effectiveness = await enhancedNotificationService.getNotificationEffectiveness();

    res.status(200).json({
      success: true,
      data: effectiveness
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Process scheduled notifications (Admin only)
// @route   POST /api/notifications/enhanced/process-scheduled
// @access  Private (Admin only)
exports.processScheduledNotifications = async (req, res, next) => {
  try {
    const result = await enhancedNotificationService.processScheduledNotifications();

    res.status(200).json({
      success: true,
      message: `Processed ${result.processed} scheduled notifications`,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

// ==================== TEMPLATE MANAGEMENT ====================

// @desc    Create notification template
// @route   POST /api/notifications/templates
// @access  Private (Admin only)
exports.createTemplate = async (req, res, next) => {
  try {
    const {
      name, description, category, type,
      subject, content, variables, defaultValues,
      language, emailSettings, smsSettings, pushSettings
    } = req.body;

    // Validate required fields
    if (!name || !content) {
      return res.status(400).json({
        success: false,
        message: 'Name and content are required'
      });
    }

    if (type === 'email' && !subject) {
      return res.status(400).json({
        success: false,
        message: 'Subject is required for email templates'
      });
    }

    // Create template
    const template = await enhancedNotificationService.createTemplate({
      name,
      description: description || '',
      category: category || 'system',
      type: type || 'email',
      subject: subject || '',
      content,
      variables: variables || [],
      defaultValues: defaultValues || {},
      language: language || 'en',
      createdBy: req.user.id,
      emailSettings: emailSettings || {},
      smsSettings: smsSettings || {},
      pushSettings: pushSettings || {}
    });

    res.status(201).json({
      success: true,
      message: 'Template created successfully',
      data: template
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all templates
// @route   GET /api/notifications/templates
// @access  Private
exports.getTemplates = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      category,
      type,
      language,
      search,
      activeOnly = true
    } = req.query;

    const query = {};
    if (category) query.category = category;
    if (type) query.type = type;
    if (language) query.language = language;
    if (activeOnly === 'true') query.isActive = true;

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { content: { $regex: search, $options: 'i' } }
      ];
    }

    const templates = await NotificationTemplate.find(query)
      .populate('createdBy', 'firstName lastName email')
      .sort({ usageCount: -1, createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await NotificationTemplate.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        templates,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get template by ID
// @route   GET /api/notifications/templates/:id
// @access  Private
exports.getTemplate = async (req, res, next) => {
  try {
    const { id } = req.params;

    const template = await NotificationTemplate.findById(id)
      .populate('createdBy', 'firstName lastName email');

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Template not found'
      });
    }

    res.status(200).json({
      success: true,
      data: template
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update template
// @route   PUT /api/notifications/templates/:id
// @access  Private (Admin only)
exports.updateTemplate = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const template = await NotificationTemplate.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Template not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Template updated successfully',
      data: template
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete template
// @route   DELETE /api/notifications/templates/:id
// @access  Private (Admin only)
exports.deleteTemplate = async (req, res, next) => {
  try {
    const { id } = req.params;

    const template = await NotificationTemplate.findByIdAndDelete(id);

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Template not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Template deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Test template rendering
// @route   POST /api/notifications/templates/:id/test
// @access  Private
exports.testTemplate = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { variables = {} } = req.body;

    const rendered = await enhancedNotificationService.renderTemplate(id, variables);

    res.status(200).json({
      success: true,
      data: {
        rendered,
        variablesUsed: Object.keys(variables)
      }
    });
  } catch (error) {
    next(error);
  }
};

// ==================== CHANNEL-SPECIFIC ENDPOINTS ====================

// @desc    Send email notification
// @route   POST /api/notifications/email
// @access  Private (Admin only)
exports.sendEmailNotification = async (req, res, next) => {
  try {
    const { templateId, variables, targetUsers, targetRole, subject, content } = req.body;

    if (!templateId && (!subject || !content)) {
      return res.status(400).json({
        success: false,
        message: 'Either templateId or subject/content must be provided'
      });
    }

    // Create notification
    const notificationData = {
      title: subject || 'Email Notification',
      body: content || 'Email notification content',
      type: 'system',
      channels: ['email'],
      templateId,
      templateVariables: variables || {},
      emailContent: {
        subject: subject || '',
        htmlBody: content || '',
        textBody: content || ''
      },
      targetUsers,
      targetRole,
      createdBy: req.user.id
    };

    const result = await enhancedNotificationService.sendMultiChannelNotification(notificationData);

    res.status(200).json({
      success: true,
      message: 'Email notification sent successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Send SMS notification
// @route   POST /api/notifications/sms
// @access  Private (Admin only)
exports.sendSmsNotification = async (req, res, next) => {
  try {
    const { templateId, variables, targetUsers, targetRole, message } = req.body;

    if (!templateId && !message) {
      return res.status(400).json({
        success: false,
        message: 'Either templateId or message must be provided'
      });
    }

    // Create notification
    const notificationData = {
      title: 'SMS Notification',
      body: message || 'SMS notification',
      type: 'system',
      channels: ['sms'],
      templateId,
      templateVariables: variables || {},
      smsContent: {
        message: message || ''
      },
      targetUsers,
      targetRole,
      createdBy: req.user.id
    };

    const result = await enhancedNotificationService.sendMultiChannelNotification(notificationData);

    res.status(200).json({
      success: true,
      message: 'SMS notification sent successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Send push notification
// @route   POST /api/notifications/push
// @access  Private (Admin only)
exports.sendPushNotification = async (req, res, next) => {
  try {
    const { templateId, variables, targetUsers, targetRole, title, body, data } = req.body;

    if (!templateId && (!title || !body)) {
      return res.status(400).json({
        success: false,
        message: 'Either templateId or title/body must be provided'
      });
    }

    // Create notification
    const notificationData = {
      title: title || 'Push Notification',
      body: body || 'Push notification',
      type: 'system',
      channels: ['push'],
      templateId,
      templateVariables: variables || {},
      pushContent: {
        title: title || '',
        body: body || '',
        data: data || {}
      },
      targetUsers,
      targetRole,
      createdBy: req.user.id
    };

    const result = await enhancedNotificationService.sendMultiChannelNotification(notificationData);

    res.status(200).json({
      success: true,
      message: 'Push notification sent successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Send in-app notification
// @route   POST /api/notifications/in-app
// @access  Private (Admin only)
exports.sendInAppNotification = async (req, res, next) => {
  try {
    const { templateId, variables, targetUsers, targetRole, message, action } = req.body;

    if (!templateId && !message) {
      return res.status(400).json({
        success: false,
        message: 'Either templateId or message must be provided'
      });
    }

    // Create notification
    const notificationData = {
      title: 'In-App Notification',
      body: message || 'In-app notification',
      type: 'system',
      channels: ['inApp'],
      templateId,
      templateVariables: variables || {},
      inAppContent: {
        message: message || '',
        action: action || null
      },
      targetUsers,
      targetRole,
      createdBy: req.user.id
    };

    const result = await enhancedNotificationService.sendMultiChannelNotification(notificationData);

    res.status(200).json({
      success: true,
      message: 'In-app notification sent successfully',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

// ==================== UTILITY METHODS ====================

// Calculate channel performance for a notification
exports.calculateChannelPerformance = (notification) => {
  const performance = {};

  notification.channels.forEach(channel => {
    const status = notification.deliveryStatus[channel] || {};
    performance[channel] = {
      status: status.status || 'pending',
      success: status.status === 'delivered' || status.status === 'read',
      timestamp: status.timestamp,
      error: status.error
    };
  });

  return performance;
};