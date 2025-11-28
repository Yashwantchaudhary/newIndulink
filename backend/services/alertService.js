const nodemailer = require('nodemailer');
const { MongoClient } = require('mongodb');
require('dotenv').config();

/**
 * Alert Service for real-time notifications
 * Sends alerts via email, Slack, or other channels when performance thresholds are exceeded
 */
class AlertService {
  constructor() {
    this.transporter = null;
    this.alertHistory = new Map(); // Track alerts to prevent spam
    this.alertCooldown = 5 * 60 * 1000; // 5 minutes cooldown between similar alerts

    this.thresholds = {
      // Backend thresholds
      responseTime: 2000, // 2 seconds
      errorRate: 5, // 5%
      memoryUsage: 85, // 85%
      cpuUsage: 80, // 80%

      // Database thresholds
      connectionCount: 100,
      slowQueryCount: 10,
      storageUsage: 85, // 85%

      // API thresholds
      apiErrorRate: 3, // 3%
      apiResponseTime: 1500, // 1.5 seconds
    };

    this.initializeEmailTransporter();
  }

  /**
   * Initialize email transporter for sending alerts
   */
  initializeEmailTransporter() {
    if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
      this.transporter = nodemailer.createTransporter({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: false, // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
    }
  }

  /**
   * Check if alert should be sent (prevent spam)
   */
  shouldSendAlert(alertKey, severity = 'medium') {
    const now = Date.now();
    const lastAlert = this.alertHistory.get(alertKey);

    if (!lastAlert) return true;

    const cooldownPeriod = severity === 'high' ? this.alertCooldown / 2 : this.alertCooldown;
    return (now - lastAlert) > cooldownPeriod;
  }

  /**
   * Record alert in history
   */
  recordAlert(alertKey) {
    this.alertHistory.set(alertKey, Date.now());

    // Clean up old entries (keep only last 24 hours)
    const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000);
    for (const [key, timestamp] of this.alertHistory.entries()) {
      if (timestamp < oneDayAgo) {
        this.alertHistory.delete(key);
      }
    }
  }

  /**
   * Send alert via email
   */
  async sendEmailAlert(subject, message, details = {}) {
    if (!this.transporter) {
      console.warn('Email transporter not configured. Skipping email alert.');
      return;
    }

    try {
      const mailOptions = {
        from: process.env.SMTP_USER,
        to: process.env.ALERT_EMAIL_RECIPIENTS || process.env.SMTP_USER,
        subject: `[Indulink Alert] ${subject}`,
        html: this.formatEmailTemplate(subject, message, details),
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Alert email sent:', info.messageId);
    } catch (error) {
      console.error('Failed to send alert email:', error.message);
    }
  }

  /**
   * Send alert via webhook (for Slack, Discord, etc.)
   */
  async sendWebhookAlert(message, details = {}) {
    if (!process.env.ALERT_WEBHOOK_URL) return;

    try {
      const payload = {
        text: `🚨 Indulink Alert: ${message}`,
        attachments: [{
          color: details.severity === 'high' ? 'danger' : 'warning',
          fields: Object.entries(details).map(([key, value]) => ({
            title: key,
            value: String(value),
            short: true
          }))
        }],
        timestamp: new Date().toISOString()
      };

      // Using fetch if available, otherwise skip
      if (typeof fetch !== 'undefined') {
        const response = await fetch(process.env.ALERT_WEBHOOK_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        });

        if (response.ok) {
          console.log('Webhook alert sent successfully');
        } else {
          console.error('Failed to send webhook alert:', response.status);
        }
      }
    } catch (error) {
      console.error('Failed to send webhook alert:', error.message);
    }
  }

  /**
   * Send alert via New Relic (if configured)
   */
  async sendNewRelicAlert(message, details = {}) {
    if (!process.env.NEW_RELIC_LICENSE_KEY) return;

    try {
      // This would integrate with New Relic's alerting API
      // For now, we'll log it as New Relic events are already being sent
      console.log('New Relic alert logged:', message, details);
    } catch (error) {
      console.error('Failed to send New Relic alert:', error.message);
    }
  }

  /**
   * Send comprehensive alert through all configured channels
   */
  async sendAlert(alertType, severity, message, details = {}) {
    const alertKey = `${alertType}_${severity}`;

    if (!this.shouldSendAlert(alertKey, severity)) {
      console.log(`Alert suppressed (cooldown): ${alertType}`);
      return;
    }

    console.log(`🚨 Sending ${severity.toUpperCase()} alert: ${message}`);

    // Send through all configured channels
    await Promise.allSettled([
      this.sendEmailAlert(`${severity.toUpperCase()}: ${alertType}`, message, { ...details, severity }),
      this.sendWebhookAlert(message, { ...details, severity, alertType }),
      this.sendNewRelicAlert(message, { ...details, severity, alertType }),
    ]);

    this.recordAlert(alertKey);
  }

  /**
   * Check backend performance metrics and send alerts
   */
  async checkBackendAlerts(metrics) {
    const { averageResponseTime, errorRate, memoryUsage, cpuUsage } = metrics;

    // Response time alert
    if (averageResponseTime > this.thresholds.responseTime) {
      await this.sendAlert(
        'HIGH_RESPONSE_TIME',
        'high',
        `Backend response time is ${averageResponseTime}ms (threshold: ${this.thresholds.responseTime}ms)`,
        { responseTime: averageResponseTime, threshold: this.thresholds.responseTime }
      );
    }

    // Error rate alert
    if (errorRate > this.thresholds.errorRate) {
      await this.sendAlert(
        'HIGH_ERROR_RATE',
        'high',
        `Backend error rate is ${errorRate}% (threshold: ${this.thresholds.errorRate}%)`,
        { errorRate, threshold: this.thresholds.errorRate }
      );
    }

    // Memory usage alert
    if (memoryUsage > this.thresholds.memoryUsage) {
      await this.sendAlert(
        'HIGH_MEMORY_USAGE',
        'medium',
        `Memory usage is ${memoryUsage}% (threshold: ${this.thresholds.memoryUsage}%)`,
        { memoryUsage, threshold: this.thresholds.memoryUsage }
      );
    }

    // CPU usage alert
    if (cpuUsage > this.thresholds.cpuUsage) {
      await this.sendAlert(
        'HIGH_CPU_USAGE',
        'medium',
        `CPU usage is ${cpuUsage}% (threshold: ${this.thresholds.cpuUsage}%)`,
        { cpuUsage, threshold: this.thresholds.cpuUsage }
      );
    }
  }

  /**
   * Check database performance metrics and send alerts
   */
  async checkDatabaseAlerts(metrics) {
    const { connections, slowQueries, storageUsage } = metrics;

    // Connection count alert
    if (connections > this.thresholds.connectionCount) {
      await this.sendAlert(
        'HIGH_CONNECTION_COUNT',
        'medium',
        `Database connections: ${connections} (threshold: ${this.thresholds.connectionCount})`,
        { connections, threshold: this.thresholds.connectionCount }
      );
    }

    // Slow queries alert
    if (slowQueries > this.thresholds.slowQueryCount) {
      await this.sendAlert(
        'HIGH_SLOW_QUERIES',
        'medium',
        `Slow queries count: ${slowQueries} (threshold: ${this.thresholds.slowQueryCount})`,
        { slowQueries, threshold: this.thresholds.slowQueryCount }
      );
    }

    // Storage usage alert
    if (storageUsage > this.thresholds.storageUsage) {
      await this.sendAlert(
        'HIGH_STORAGE_USAGE',
        'high',
        `Storage usage: ${storageUsage}% (threshold: ${this.thresholds.storageUsage}%)`,
        { storageUsage, threshold: this.thresholds.storageUsage }
      );
    }
  }

  /**
   * Check API performance metrics and send alerts
   */
  async checkApiAlerts(metrics) {
    const { errorRate, averageResponseTime } = metrics;

    // API error rate alert
    if (errorRate > this.thresholds.apiErrorRate) {
      await this.sendAlert(
        'HIGH_API_ERROR_RATE',
        'high',
        `API error rate: ${errorRate}% (threshold: ${this.thresholds.apiErrorRate}%)`,
        { errorRate, threshold: this.thresholds.apiErrorRate }
      );
    }

    // API response time alert
    if (averageResponseTime > this.thresholds.apiResponseTime) {
      await this.sendAlert(
        'HIGH_API_RESPONSE_TIME',
        'medium',
        `API response time: ${averageResponseTime}ms (threshold: ${this.thresholds.apiResponseTime}ms)`,
        { averageResponseTime, threshold: this.thresholds.apiResponseTime }
      );
    }
  }

  /**
   * Send uptime/downtime alerts
   */
  async sendServiceStatusAlert(service, status, details = {}) {
    const severity = status === 'down' ? 'high' : 'medium';
    const message = `${service} is ${status}`;

    await this.sendAlert(
      `${service.toUpperCase()}_STATUS`,
      severity,
      message,
      details
    );
  }

  /**
   * Format email template
   */
  formatEmailTemplate(subject, message, details) {
    const detailsHtml = Object.entries(details)
      .map(([key, value]) => `<li><strong>${key}:</strong> ${value}</li>`)
      .join('');

    return `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #d32f2f;">🚨 Indulink Monitoring Alert</h2>
        <h3>${subject}</h3>
        <p>${message}</p>

        ${detailsHtml ? `
          <h4>Details:</h4>
          <ul>${detailsHtml}</ul>
        ` : ''}

        <hr>
        <p style="color: #666; font-size: 12px;">
          This alert was generated at ${new Date().toISOString()}<br>
          Environment: ${process.env.NODE_ENV || 'development'}
        </p>
      </div>
    `;
  }

  /**
   * Get alert statistics
   */
  getAlertStats() {
    return {
      totalAlertsSent: this.alertHistory.size,
      recentAlerts: Array.from(this.alertHistory.entries())
        .sort(([,a], [,b]) => b - a)
        .slice(0, 10)
        .map(([key, timestamp]) => ({
          alert: key,
          timestamp: new Date(timestamp).toISOString()
        }))
    };
  }
}

// Export singleton instance
const alertService = new AlertService();

module.exports = alertService;