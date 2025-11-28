'use strict';

/**
 * New Relic agent configuration.
 *
 * See lib/config/default.js in the agent distribution for a more complete
 * description of configuration variables and their potential values.
 */
exports.config = {
  /**
   * Array of application names.
   */
  app_name: [process.env.NEW_RELIC_APP_NAME || 'Indulink E-commerce API'],
  /**
   * Your New Relic license key.
   */
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  /**
   * This setting controls distributed tracing.
   * Set to `true` to enable distributed tracing.
   * Set to `false` to disable distributed tracing.
   *
   * @default true
   */
  distributed_tracing: {
    enabled: true
  },
  /**
   * This setting controls the use of high-security mode.
   * Set to `true` to enable high-security mode.
   * Set to `false` to disable high-security mode.
   *
   * @default false
   */
  high_security: false,
  /**
   * This setting controls the use of logging.
   * Set to `true` to enable logging.
   * Set to `false` to disable logging.
   *
   * @default true
   */
  logging: {
    enabled: true,
    level: process.env.NEW_RELIC_LOG_LEVEL || 'info',
    filepath: 'logs/newrelic_agent.log'
  },
  /**
   * This setting controls the use of error collector.
   * Set to `true` to enable error collector.
   * Set to `false` to disable error collector.
   *
   * @default true
   */
  error_collector: {
    enabled: true,
    ignore_status_codes: [404]
  },
  /**
   * This setting controls the use of transaction tracer.
   * Set to `true` to enable transaction tracer.
   * Set to `false` to disable transaction tracer.
   *
   * @default true
   */
  transaction_tracer: {
    enabled: true,
    transaction_threshold: 'apdex_f',
    record_sql: 'obfuscated',
    explain_threshold: 500
  },
  /**
   * This setting controls the use of slow query tracing.
   * Set to `true` to enable slow query tracing.
   * Set to `false` to disable slow query tracing.
   *
   * @default true
   */
  slow_sql: {
    enabled: true,
    max_samples: 10
  },
  /**
   * This setting controls the use of datastore tracer.
   * Set to `true` to enable datastore tracer.
   * Set to `false` to disable datastore tracer.
   *
   * @default true
   */
  datastore_tracer: {
    instance_reporting: {
      enabled: true
    },
    database_name_reporting: {
      enabled: true
    }
  },
  /**
   * This setting controls the use of attributes.
   * Set to `true` to enable attributes.
   * Set to `false` to disable attributes.
   *
   * @default true
   */
  attributes: {
    enabled: true,
    include: [
      'request.parameters.*',
      'response.statusCode',
      'response.headers.contentLength',
      'response.headers.contentType'
    ],
    exclude: [
      'request.headers.authorization',
      'request.headers.cookie',
      'request.headers.proxyAuthorization'
    ]
  },
  /**
   * This setting controls the use of custom events.
   * Set to `true` to enable custom events.
   * Set to `false` to disable custom events.
   *
   * @default true
   */
  custom_events: {
    enabled: true,
    max_samples_stored: 3000
  },
  /**
   * This setting controls the use of custom insights events.
   * Set to `true` to enable custom insights events.
   * Set to `false` to disable custom insights events.
   *
   * @default true
   */
  custom_insights_events: {
    enabled: true
  },
  /**
   * This setting controls the use of transaction events.
   * Set to `true` to enable transaction events.
   * Set to `false` to disable transaction events.
   *
   * @default true
   */
  transaction_events: {
    enabled: true
  },
  /**
   * This setting controls the use of application logging.
   * Set to `true` to enable application logging.
   * Set to `false` to disable application logging.
   *
   * @default true
   */
  application_logging: {
    enabled: true,
    forwarding: {
      enabled: true,
      max_samples_stored: 10000
    },
    metrics: {
      enabled: true
    },
    local_decorating: {
      enabled: process.env.NODE_ENV === 'development'
    }
  },
  /**
   * This setting controls the use of AI monitoring.
   * Set to `true` to enable AI monitoring.
   * Set to `false` to disable AI monitoring.
   *
   * @default true
   */
  ai_monitoring: {
    enabled: true
  },
  /**
   * This setting controls the use of code level metrics.
   * Set to `true` to enable code level metrics.
   * Set to `false` to disable code level metrics.
   *
   * @default true
   */
  code_level_metrics: {
    enabled: true
  }
};