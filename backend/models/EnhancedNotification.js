const mongoose = require('mongoose');

const deliveryStatusSchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ['pending', 'sent', 'delivered', 'failed', 'read', 'clicked'],
    default: 'pending'
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  error: {
    type: String,
    trim: true
  },
  retryCount: {
    type: Number,
    default: 0
  },
  lastAttempt: {
    type: Date
  },
  nextAttempt: {
    type: Date
  }
}, { _id: false });

const engagementMetricsSchema = new mongoose.Schema({
  opened: {
    type: Boolean,
    default: false
  },
  openedAt: {
    type: Date
  },
  clicked: {
    type: Boolean,
    default: false
  },
  clickedAt: {
    type: Date
  },
  actionTaken: {
    type: String,
    trim: true
  },
  actionTakenAt: {
    type: Date
  },
  readDuration: {
    type: Number // in seconds
  }
}, { _id: false });

const enhancedNotificationSchema = new mongoose.Schema({
  // Basic notification info
  title: {
    type: String,
    required: [true, 'Notification title is required'],
    trim: true,
    maxlength: 200
  },
  body: {
    type: String,
    required: [true, 'Notification body is required'],
    trim: true,
    maxlength: 1000
  },
  type: {
    type: String,
    enum: [
      'system', 'order_status', 'new_message', 'product_available',
      'rfq_response', 'promotion', 'maintenance', 'alert', 'security'
    ],
    default: 'system'
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },

  // Multi-channel support
  channels: [{
    type: String,
    enum: ['email', 'sms', 'push', 'in_app'],
    required: [true, 'At least one channel is required']
  }],
  templateId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'NotificationTemplate'
  },
  templateVariables: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },

  // Channel-specific content
  emailContent: {
    subject: {
      type: String,
      trim: true,
      maxlength: 200
    },
    htmlBody: {
      type: String,
      trim: true
    },
    textBody: {
      type: String,
      trim: true
    },
    from: {
      type: String,
      trim: true
    },
    replyTo: {
      type: String,
      trim: true
    }
  },
  smsContent: {
    message: {
      type: String,
      trim: true,
      maxlength: 1600 // Support for long SMS
    },
    senderId: {
      type: String,
      trim: true
    },
    parts: {
      type: Number,
      default: 1
    }
  },
  pushContent: {
    title: {
      type: String,
      trim: true,
      maxlength: 100
    },
    body: {
      type: String,
      trim: true,
      maxlength: 200
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {}
    },
    sound: {
      type: String,
      trim: true
    },
    channelId: {
      type: String,
      trim: true
    },
    priority: {
      type: String,
      enum: ['low', 'normal', 'high'],
      default: 'normal'
    }
  },
  inAppContent: {
    message: {
      type: String,
      trim: true,
      maxlength: 500
    },
    action: {
      type: String,
      trim: true
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'critical'],
      default: 'medium'
    },
    expiration: {
      type: Date
    }
  },

  // Recipients and targeting
  targetUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  targetRole: {
    type: String,
    enum: ['customer', 'supplier', 'admin', 'all']
  },
  targetCriteria: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },

  // Scheduling and timing
  scheduledTime: {
    type: Date
  },
  timeZone: {
    type: String,
    trim: true
  },
  optimalDeliveryWindow: {
    start: {
      type: String,
      trim: true
    },
    end: {
      type: String,
      trim: true
    }
  },

  // Delivery tracking by channel
  deliveryStatus: {
    email: deliveryStatusSchema,
    sms: deliveryStatusSchema,
    push: deliveryStatusSchema,
    inApp: deliveryStatusSchema
  },

  // Engagement metrics
  engagementMetrics: engagementMetricsSchema,

  // Routing and priority
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'medium'
  },
  routingRules: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  fallbackChannels: [{
    type: String,
    enum: ['email', 'sms', 'push', 'in_app']
  }],
  requireConfirmation: {
    type: Boolean,
    default: false
  },

  // Metadata
  sentBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'processing', 'sent', 'partially_sent', 'failed', 'delivered', 'expired'],
    default: 'draft'
  },
  isArchived: {
    type: Boolean,
    default: false
  },
  tags: [{
    type: String,
    trim: true
  }],
  notes: {
    type: String,
    trim: true,
    maxlength: 1000
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for performance
enhancedNotificationSchema.index({ status: 1, scheduledTime: 1 });
enhancedNotificationSchema.index({ priority: 1 });
enhancedNotificationSchema.index({ type: 1 });
enhancedNotificationSchema.index({ targetRole: 1 });
enhancedNotificationSchema.index({ createdBy: 1 });
enhancedNotificationSchema.index({ channels: 1 });
enhancedNotificationSchema.index({ 'deliveryStatus.email.status': 1 });
enhancedNotificationSchema.index({ 'deliveryStatus.sms.status': 1 });

// Virtual for overall delivery status
enhancedNotificationSchema.virtual('overallStatus').get(function() {
  const statuses = Object.values(this.deliveryStatus).map(status => status.status);
  if (statuses.includes('failed')) return 'failed';
  if (statuses.includes('delivered')) return 'delivered';
  if (statuses.includes('sent')) return 'sent';
  return 'pending';
});

// Virtual for delivery rate
enhancedNotificationSchema.virtual('deliveryRate').get(function() {
  const totalChannels = this.channels.length;
  if (totalChannels === 0) return 0;

  const successfulDeliveries = Object.values(this.deliveryStatus)
    .filter(status => status.status === 'delivered' || status.status === 'read').length;

  return (successfulDeliveries / totalChannels) * 100;
});

// Static method to get notification stats
enhancedNotificationSchema.statics.getStats = async function(timeframe = '30d') {
  const startDate = this.getStartDate(timeframe);

  const stats = await this.aggregate([
    { $match: { createdAt: { $gte: startDate } } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        emailSuccess: {
          $sum: {
            $cond: [{ $eq: ['$deliveryStatus.email.status', 'delivered'] }, 1, 0]
          }
        },
        smsSuccess: {
          $sum: {
            $cond: [{ $eq: ['$deliveryStatus.sms.status', 'delivered'] }, 1, 0]
          }
        },
        pushSuccess: {
          $sum: {
            $cond: [{ $eq: ['$deliveryStatus.push.status', 'delivered'] }, 1, 0]
          }
        },
        inAppSuccess: {
          $sum: {
            $cond: [{ $eq: ['$deliveryStatus.inApp.status', 'delivered'] }, 1, 0]
          }
        }
      }
    }
  ]);

  const result = {
    total: 0,
    sent: 0,
    scheduled: 0,
    failed: 0,
    delivered: 0,
    emailSuccess: 0,
    smsSuccess: 0,
    pushSuccess: 0,
    inAppSuccess: 0,
    timeframe
  };

  stats.forEach(stat => {
    result[stat._id] = stat.count;
    result.total += stat.count;
    result.emailSuccess += stat.emailSuccess || 0;
    result.smsSuccess += stat.smsSuccess || 0;
    result.pushSuccess += stat.pushSuccess || 0;
    result.inAppSuccess += stat.inAppSuccess || 0;
  });

  result.overallDeliveryRate = result.total > 0
    ? ((result.emailSuccess + result.smsSuccess + result.pushSuccess + result.inAppSuccess) / (result.total * 4)) * 100
    : 0;

  return result;
};

// Helper method to get start date
enhancedNotificationSchema.statics.getStartDate = function(timeframe) {
  const now = new Date();
  const units = {
    '1h': 1 * 60 * 60 * 1000,
    '24h': 24 * 60 * 60 * 1000,
    '7d': 7 * 24 * 60 * 60 * 1000,
    '30d': 30 * 24 * 60 * 60 * 1000,
    '90d': 90 * 24 * 60 * 60 * 1000,
    '1y': 365 * 24 * 60 * 60 * 1000
  };

  return new Date(now.getTime() - (units[timeframe] || units['30d']));
};

// Pre-save middleware
enhancedNotificationSchema.pre('save', function(next) {
  // Ensure channels array is not empty
  if (!this.channels || this.channels.length === 0) {
    this.channels = ['email']; // Default to email if no channels specified
  }

  // Set default delivery status for each channel
  this.channels.forEach(channel => {
    if (!this.deliveryStatus[channel]) {
      this.deliveryStatus[channel] = {
        status: 'pending',
        timestamp: new Date(),
        error: null,
        retryCount: 0
      };
    }
  });

  next();
});

// Instance method to mark channel as sent
enhancedNotificationSchema.methods.markChannelAsSent = function(channel, details = {}) {
  if (this.deliveryStatus[channel]) {
    this.deliveryStatus[channel] = {
      ...this.deliveryStatus[channel],
      status: 'sent',
      timestamp: new Date(),
      ...details
    };
  }
  return this.save();
};

// Instance method to mark channel as delivered
enhancedNotificationSchema.methods.markChannelAsDelivered = function(channel, details = {}) {
  if (this.deliveryStatus[channel]) {
    this.deliveryStatus[channel] = {
      ...this.deliveryStatus[channel],
      status: 'delivered',
      timestamp: new Date(),
      ...details
    };
  }
  return this.save();
};

// Instance method to mark channel as failed
enhancedNotificationSchema.methods.markChannelAsFailed = function(channel, error, details = {}) {
  if (this.deliveryStatus[channel]) {
    this.deliveryStatus[channel] = {
      ...this.deliveryStatus[channel],
      status: 'failed',
      error,
      timestamp: new Date(),
      retryCount: (this.deliveryStatus[channel].retryCount || 0) + 1,
      ...details
    };
  }
  return this.save();
};

// Instance method to update engagement metrics
enhancedNotificationSchema.methods.updateEngagement = function(metrics = {}) {
  this.engagementMetrics = {
    ...this.engagementMetrics,
    ...metrics,
    ...(metrics.opened && { openedAt: new Date() }),
    ...(metrics.clicked && { clickedAt: new Date() }),
    ...(metrics.actionTaken && { actionTakenAt: new Date() })
  };
  return this.save();
};

module.exports = mongoose.model('EnhancedNotification', enhancedNotificationSchema);