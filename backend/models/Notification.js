/// 🔔 Notification Model
/// Handles all types of notifications including push notifications

const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  // Basic notification info
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  body: {
    type: String,
    required: true,
    trim: true,
    maxlength: 500
  },

  // Notification type and data
  type: {
    type: String,
    enum: [
      'system',
      'order_status',
      'new_message',
      'product_available',
      'rfq_response',
      'promotion',
      'maintenance',
      'test'
    ],
    default: 'system'
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },

  // Recipients
  targetUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  targetRole: {
    type: String,
    enum: ['customer', 'supplier', 'admin'],
  },

  // Scheduling
  scheduledTime: {
    type: Date
  },
  status: {
    type: String,
    enum: ['scheduled', 'sent', 'failed'],
    default: 'sent'
  },

  // Delivery tracking
  deliveryStats: {
    successCount: {
      type: Number,
      default: 0
    },
    failureCount: {
      type: Number,
      default: 0
    },
    totalTokens: {
      type: Number,
      default: 0
    }
  },

  // Metadata
  sentBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  sentAt: {
    type: Date,
    default: Date.now
  },
  error: {
    type: String
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for performance
notificationSchema.index({ status: 1, scheduledTime: 1 });
notificationSchema.index({ sentBy: 1 });
notificationSchema.index({ targetRole: 1 });
notificationSchema.index({ createdAt: -1 });
notificationSchema.index({ type: 1 });

// Virtual for delivery rate
notificationSchema.virtual('deliveryRate').get(function() {
  if (this.deliveryStats.totalTokens === 0) return 0;
  return (this.deliveryStats.successCount / this.deliveryStats.totalTokens) * 100;
});

// Static method to get notification stats
notificationSchema.statics.getStats = async function(timeframe = '30d') {
  const startDate = this.getStartDate(timeframe);

  const stats = await this.aggregate([
    { $match: { createdAt: { $gte: startDate } } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalSuccess: { $sum: '$deliveryStats.successCount' },
        totalFailure: { $sum: '$deliveryStats.failureCount' }
      }
    }
  ]);

  const result = {
    total: 0,
    sent: 0,
    scheduled: 0,
    failed: 0,
    totalSuccess: 0,
    totalFailure: 0,
    timeframe
  };

  stats.forEach(stat => {
    result[stat._id] = stat.count;
    result.total += stat.count;
    result.totalSuccess += stat.totalSuccess || 0;
    result.totalFailure += stat.totalFailure || 0;
  });

  result.deliveryRate = result.totalSuccess + result.totalFailure > 0
    ? (result.totalSuccess / (result.totalSuccess + result.totalFailure)) * 100
    : 0;

  return result;
};

// Helper method to get start date
notificationSchema.statics.getStartDate = function(timeframe) {
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
notificationSchema.pre('save', function(next) {
  // Calculate total tokens if delivery stats exist
  if (this.deliveryStats && this.deliveryStats.successCount !== undefined && this.deliveryStats.failureCount !== undefined) {
    this.deliveryStats.totalTokens = this.deliveryStats.successCount + this.deliveryStats.failureCount;
  }
  next();
});

// Instance method to mark as sent
notificationSchema.methods.markAsSent = function(stats) {
  this.status = 'sent';
  this.sentAt = new Date();
  this.deliveryStats = stats;
  return this.save();
};

// Instance method to mark as failed
notificationSchema.methods.markAsFailed = function(error) {
  this.status = 'failed';
  this.error = error;
  return this.save();
};

module.exports = mongoose.model('Notification', notificationSchema);
