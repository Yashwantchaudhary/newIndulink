let newrelic;
try {
  newrelic = require('newrelic');
} catch (error) {
  console.log('New Relic not available, running without monitoring');
  newrelic = {
    recordMetric: () => {},
    recordCustomEvent: () => {}
  };
}
const alertService = require('../services/alertService');

/**
 * API Monitoring Middleware
 * Tracks response times, error rates, throughput, and other API metrics
 */
class APIMonitor {
  constructor() {
    this.metrics = {
      totalRequests: 0,
      totalErrors: 0,
      responseTimes: [],
      statusCodes: {},
      endpoints: {},
      throughput: {
        current: 0,
        history: []
      }
    };

    // Reset throughput counter every minute and check for alerts
    setInterval(() => {
      this.metrics.throughput.history.push({
        timestamp: new Date().toISOString(),
        requests: this.metrics.throughput.current
      });

      // Keep only last 60 minutes
      if (this.metrics.throughput.history.length > 60) {
        this.metrics.throughput.history.shift();
      }

      this.metrics.throughput.current = 0;

      // Check for alerts every minute
      this.checkAlerts();
    }, 60000);
  }

  /**
   * Middleware function to track API metrics
   */
  middleware() {
    return (req, res, next) => {
      const startTime = Date.now();
      const endpoint = `${req.method} ${req.route?.path || req.path}`;
      const userAgent = req.get('User-Agent') || 'Unknown';
      const ip = req.ip || req.connection.remoteAddress;

      // Increment request counter
      this.metrics.totalRequests++;
      this.metrics.throughput.current++;

      // Track endpoint usage
      if (!this.metrics.endpoints[endpoint]) {
        this.metrics.endpoints[endpoint] = {
          count: 0,
          errors: 0,
          avgResponseTime: 0,
          responseTimes: []
        };
      }
      this.metrics.endpoints[endpoint].count++;

      // Override res.end to capture response metrics
      const originalEnd = res.end;
      res.end = (...args) => {
        const duration = Date.now() - startTime;

        // Record response time
        this.metrics.responseTimes.push(duration);
        this.metrics.endpoints[endpoint].responseTimes.push(duration);

        // Keep only last 1000 response times for memory efficiency
        if (this.metrics.responseTimes.length > 1000) {
          this.metrics.responseTimes.shift();
        }
        if (this.metrics.endpoints[endpoint].responseTimes.length > 100) {
          this.metrics.endpoints[endpoint].responseTimes.shift();
        }

        // Update average response time
        const endpointTimes = this.metrics.endpoints[endpoint].responseTimes;
        this.metrics.endpoints[endpoint].avgResponseTime =
          endpointTimes.reduce((a, b) => a + b, 0) / endpointTimes.length;

        // Track status codes
        const statusCode = res.statusCode;
        this.metrics.statusCodes[statusCode] = (this.metrics.statusCodes[statusCode] || 0) + 1;

        // Track errors
        if (statusCode >= 400) {
          this.metrics.totalErrors++;
          this.metrics.endpoints[endpoint].errors++;
        }

        // Send metrics to New Relic
        this.sendMetricsToNewRelic(req, res, duration, endpoint);

        // Call original end method
        originalEnd.apply(res, args);
      };

      next();
    };
  }

  /**
   * Send metrics to New Relic
   */
  sendMetricsToNewRelic(req, res, duration, endpoint) {
    try {
      // Record transaction
      newrelic.recordMetric(`API/ResponseTime/${endpoint}`, duration);
      newrelic.recordMetric(`API/StatusCode/${res.statusCode}`, 1);

      // Record custom event for detailed analysis
      newrelic.recordCustomEvent('API_Request', {
        method: req.method,
        endpoint: endpoint,
        statusCode: res.statusCode,
        responseTime: duration,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        timestamp: new Date().toISOString()
      });

      // Record error if status code indicates error
      if (res.statusCode >= 400) {
        newrelic.recordCustomEvent('API_Error', {
          method: req.method,
          endpoint: endpoint,
          statusCode: res.statusCode,
          responseTime: duration,
          error: res.locals?.error?.message || 'Unknown error',
          timestamp: new Date().toISOString()
        });
      }
    } catch (error) {
      console.error('Failed to send metrics to New Relic:', error.message);
    }
  }

  /**
   * Get current metrics summary
   */
  getMetricsSummary() {
    const avgResponseTime = this.metrics.responseTimes.length > 0
      ? this.metrics.responseTimes.reduce((a, b) => a + b, 0) / this.metrics.responseTimes.length
      : 0;

    const errorRate = this.metrics.totalRequests > 0
      ? (this.metrics.totalErrors / this.metrics.totalRequests) * 100
      : 0;

    const throughput = this.metrics.throughput.history.length > 0
      ? this.metrics.throughput.history[this.metrics.throughput.history.length - 1].requests
      : 0;

    return {
      totalRequests: this.metrics.totalRequests,
      totalErrors: this.metrics.totalErrors,
      averageResponseTime: Math.round(avgResponseTime),
      errorRate: Math.round(errorRate * 100) / 100,
      throughput: throughput,
      statusCodes: this.metrics.statusCodes,
      topEndpoints: Object.entries(this.metrics.endpoints)
        .sort(([,a], [,b]) => b.count - a.count)
        .slice(0, 10)
        .map(([endpoint, data]) => ({
          endpoint,
          count: data.count,
          errors: data.errors,
          avgResponseTime: Math.round(data.avgResponseTime)
        })),
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Check for alerts and trigger notifications
   */
  async checkAlerts() {
    try {
      const summary = this.getMetricsSummary();

      // Check error rate threshold (3%)
      if (summary.errorRate > 3) {
        await alertService.sendAlert(
          'HIGH_API_ERROR_RATE',
          'high',
          `API error rate is ${summary.errorRate}% (threshold: 3%)`,
          {
            errorRate: summary.errorRate,
            totalRequests: summary.totalRequests,
            totalErrors: summary.totalErrors,
            timestamp: summary.timestamp
          }
        );
      }

      // Check response time threshold (1.5 seconds)
      if (summary.averageResponseTime > 1500) {
        await alertService.sendAlert(
          'HIGH_API_RESPONSE_TIME',
          'medium',
          `API average response time is ${summary.averageResponseTime}ms (threshold: 1500ms)`,
          {
            averageResponseTime: summary.averageResponseTime,
            totalRequests: summary.totalRequests,
            timestamp: summary.timestamp
          }
        );
      }

      // Check for endpoint-specific issues
      for (const endpoint of summary.topEndpoints) {
        const endpointErrorRate = endpoint.count > 0 ? (endpoint.errors / endpoint.count) * 100 : 0;

        // High error rate for specific endpoint
        if (endpointErrorRate > 5 && endpoint.count > 10) {
          await alertService.sendAlert(
            'HIGH_ENDPOINT_ERROR_RATE',
            'medium',
            `Endpoint ${endpoint.endpoint} has ${endpointErrorRate.toFixed(1)}% error rate`,
            {
              endpoint: endpoint.endpoint,
              errorRate: endpointErrorRate,
              errors: endpoint.errors,
              totalRequests: endpoint.count,
              timestamp: summary.timestamp
            }
          );
        }

        // Slow endpoint
        if (endpoint.avgResponseTime > 2000 && endpoint.count > 5) {
          await alertService.sendAlert(
            'SLOW_ENDPOINT',
            'low',
            `Endpoint ${endpoint.endpoint} is slow (${endpoint.avgResponseTime}ms average)`,
            {
              endpoint: endpoint.endpoint,
              avgResponseTime: endpoint.avgResponseTime,
              requestCount: endpoint.count,
              timestamp: summary.timestamp
            }
          );
        }
      }

    } catch (error) {
      console.error('Failed to check API alerts:', error.message);
    }
  }

  /**
   * Health check endpoint middleware
   */
  healthCheck() {
    return (req, res) => {
      const summary = this.getMetricsSummary();

      // Determine health status based on metrics
      const isHealthy = summary.errorRate < 5 && summary.averageResponseTime < 2000;

      res.status(isHealthy ? 200 : 503).json({
        status: isHealthy ? 'healthy' : 'degraded',
        timestamp: summary.timestamp,
        metrics: summary,
        uptime: process.uptime(),
        memory: process.memoryUsage()
      });
    };
  }
}

// Export singleton instance
const apiMonitor = new APIMonitor();

module.exports = {
  apiMonitoring: apiMonitor.middleware(),
  getMetricsSummary: () => apiMonitor.getMetricsSummary(),
  healthCheck: apiMonitor.healthCheck()
};
