const mongoose = require('mongoose');

const notificationTemplateSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Template name is required'],
    trim: true,
    unique: true,
    maxlength: 100
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500
  },
  category: {
    type: String,
    enum: ['system', 'marketing', 'transactional', 'alert', 'promotional'],
    default: 'system'
  },
  type: {
    type: String,
    enum: ['email', 'sms', 'push', 'in_app', 'multi_channel'],
    default: 'email'
  },
  subject: {
    type: String,
    required: function() { return this.type === 'email' || this.type === 'multi_channel'; },
    trim: true,
    maxlength: 200
  },
  content: {
    type: String,
    required: [true, 'Template content is required'],
    trim: true
  },
  variables: [{
    type: String,
    trim: true
  }],
  defaultValues: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  language: {
    type: String,
    enum: ['en', 'ne', 'hi', 'fr', 'es', 'de'],
    default: 'en'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  version: {
    type: Number,
    default: 1
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  lastUsed: {
    type: Date
  },
  usageCount: {
    type: Number,
    default: 0
  },
  // Email-specific fields
  emailSettings: {
    fromName: String,
    fromEmail: String,
    replyTo: String,
    cc: [String],
    bcc: [String]
  },
  // SMS-specific fields
  smsSettings: {
    senderId: String,
    maxLength: Number,
    encoding: {
      type: String,
      enum: ['gsm', 'unicode'],
      default: 'gsm'
    }
  },
  // Push notification-specific fields
  pushSettings: {
    sound: String,
    channelId: String,
    priority: {
      type: String,
      enum: ['low', 'normal', 'high'],
      default: 'normal'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for performance
notificationTemplateSchema.index({ category: 1 });
notificationTemplateSchema.index({ type: 1 });
notificationTemplateSchema.index({ language: 1 });
notificationTemplateSchema.index({ isActive: 1 });
notificationTemplateSchema.index({ createdBy: 1 });

// Virtual for template preview
notificationTemplateSchema.virtual('preview').get(function() {
  return this.content.substring(0, 100) + (this.content.length > 100 ? '...' : '');
});

// Pre-save middleware
notificationTemplateSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Static method to find templates by category and type
notificationTemplateSchema.statics.findByCategoryAndType = async function(category, type) {
  return this.find({
    category,
    type,
    isActive: true
  }).sort({ usageCount: -1 });
};

// Instance method to render template with variables
notificationTemplateSchema.methods.render = function(variables = {}) {
  let renderedContent = this.content;

  // Replace variables in content
  this.variables.forEach(variable => {
    const regex = new RegExp(`\\{\\{${variable}\\}\\}`, 'g');
    const value = variables[variable] || this.defaultValues[variable] || '';
    renderedContent = renderedContent.replace(regex, value);
  });

  // Also replace in subject if it's an email template
  if (this.type === 'email' || this.type === 'multi_channel') {
    let renderedSubject = this.subject;
    this.variables.forEach(variable => {
      const regex = new RegExp(`\\{\\{${variable}\\}\\}`, 'g');
      const value = variables[variable] || this.defaultValues[variable] || '';
      renderedSubject = renderedSubject.replace(regex, value);
    });
    return { subject: renderedSubject, content: renderedContent };
  }

  return renderedContent;
};

module.exports = mongoose.model('NotificationTemplate', notificationTemplateSchema);