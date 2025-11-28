const mongoose = require('mongoose');
const { MongoClient } = require('mongodb');
require('dotenv').config();

/**
 * Database Monitoring and Alerting System
 * Monitors MongoDB Atlas performance, sets up alerts, and provides insights
 */

class DatabaseMonitor {
  constructor() {
    this.client = null;
    this.db = null;
    this.alerts = [];
    this.metrics = {
      connections: 0,
      operations: 0,
      memory: 0,
      storage: 0,
      slowQueries: []
    };
    this.thresholds = {
      maxConnections: 100,
      maxSlowQueries: 10,
      maxMemoryUsage: 80, // percentage
      maxStorageUsage: 85, // percentage
      slowQueryThreshold: 1000 // ms
    };
  }

  async connect() {
    try {
      this.client = new MongoClient(process.env.MONGODB_URI);
      await this.client.connect();
      this.db = this.client.db();
      console.log('✅ Connected to MongoDB Atlas for monitoring');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect to MongoDB Atlas:', error.message);
      return false;
    }
  }

  async collectMetrics() {
    console.log('📊 Collecting database metrics...');

    try {
      // Get server status
      const serverStatus = await this.db.admin().serverStatus();

      // Connection metrics
      this.metrics.connections = serverStatus.connections?.current || 0;

      // Operation counters
      this.metrics.operations = {
        insert: serverStatus.opcounters?.insert || 0,
        query: serverStatus.opcounters?.query || 0,
        update: serverStatus.opcounters?.update || 0,
        delete: serverStatus.opcounters?.delete || 0,
        getmore: serverStatus.opcounters?.getmore || 0,
        command: serverStatus.opcounters?.command || 0
      };

      // Memory metrics
      this.metrics.memory = {
        resident: serverStatus.mem?.resident || 0,
        virtual: serverStatus.mem?.virtual || 0,
        mapped: serverStatus.mem?.mapped || 0
      };

      // Storage metrics
      const dbStats = await this.db.stats();
      this.metrics.storage = {
        dataSize: dbStats.dataSize || 0,
        storageSize: dbStats.storageSize || 0,
        indexSize: dbStats.indexSize || 0,
        collections: dbStats.collections || 0,
        objects: dbStats.objects || 0
      };

      // Slow queries (if profiling is enabled)
      try {
        const slowQueries = await this.db.collection('system.profile')
          .find({ millis: { $gt: this.thresholds.slowQueryThreshold } })
          .sort({ ts: -1 })
          .limit(20)
          .toArray();

        this.metrics.slowQueries = slowQueries.map(query => ({
          timestamp: query.ts,
          duration: query.millis,
          operation: query.op,
          collection: query.ns,
          query: query.command
        }));
      } catch (error) {
        // Profiling might not be enabled
        this.metrics.slowQueries = [];
      }

      // Collection-specific metrics
      this.metrics.collections = {};
      const collections = await this.db.listCollections().toArray();

      for (const collection of collections) {
        if (collection.name.startsWith('system.')) continue;

        try {
          const coll = this.db.collection(collection.name);
          const stats = await coll.stats();

          this.metrics.collections[collection.name] = {
            documentCount: stats.count || 0,
            size: stats.size || 0,
            avgObjSize: stats.avgObjSize || 0,
            storageSize: stats.storageSize || 0,
            indexes: stats.nindexes || 0,
            indexSize: stats.totalIndexSize || 0
          };
        } catch (error) {
          console.error(`❌ Failed to get stats for collection ${collection.name}:`, error.message);
        }
      }

      return this.metrics;

    } catch (error) {
      console.error('❌ Failed to collect metrics:', error.message);
      return null;
    }
  }

  checkAlerts() {
    console.log('🚨 Checking for alerts...');
    this.alerts = [];

    // Connection alerts
    if (this.metrics.connections > this.thresholds.maxConnections) {
      this.alerts.push({
        type: 'CONNECTION_SPIKE',
        severity: 'HIGH',
        message: `High connection count: ${this.metrics.connections} (threshold: ${this.thresholds.maxConnections})`,
        value: this.metrics.connections,
        threshold: this.thresholds.maxConnections
      });
    }

    // Slow query alerts
    if (this.metrics.slowQueries.length > this.thresholds.maxSlowQueries) {
      this.alerts.push({
        type: 'SLOW_QUERIES',
        severity: 'MEDIUM',
        message: `High number of slow queries: ${this.metrics.slowQueries.length} (threshold: ${this.thresholds.maxSlowQueries})`,
        value: this.metrics.slowQueries.length,
        threshold: this.thresholds.maxSlowQueries
      });
    }

    // Memory usage alerts (if available)
    if (this.metrics.memory.resident > 0) {
      const memoryUsagePercent = (this.metrics.memory.resident / (this.metrics.memory.virtual || 1)) * 100;
      if (memoryUsagePercent > this.thresholds.maxMemoryUsage) {
        this.alerts.push({
          type: 'HIGH_MEMORY_USAGE',
          severity: 'HIGH',
          message: `High memory usage: ${memoryUsagePercent.toFixed(1)}% (threshold: ${this.thresholds.maxMemoryUsage}%)`,
          value: memoryUsagePercent,
          threshold: this.thresholds.maxMemoryUsage
        });
      }
    }

    // Storage alerts
    const totalSize = this.metrics.storage.dataSize + this.metrics.storage.indexSize;
    const storageLimit = 5368709120; // 5GB example limit - adjust based on your plan
    const storageUsagePercent = (totalSize / storageLimit) * 100;

    if (storageUsagePercent > this.thresholds.maxStorageUsage) {
      this.alerts.push({
        type: 'HIGH_STORAGE_USAGE',
        severity: 'HIGH',
        message: `High storage usage: ${storageUsagePercent.toFixed(1)}% (threshold: ${this.thresholds.maxStorageUsage}%)`,
        value: storageUsagePercent,
        threshold: this.thresholds.maxStorageUsage
      });
    }

    // Collection-specific alerts
    for (const [collectionName, stats] of Object.entries(this.metrics.collections || {})) {
      // Large collection alert
      if (stats.documentCount > 100000) { // Example threshold
        this.alerts.push({
          type: 'LARGE_COLLECTION',
          severity: 'LOW',
          message: `Large collection detected: ${collectionName} (${stats.documentCount} documents)`,
          collection: collectionName,
          value: stats.documentCount
        });
      }

      // Index efficiency check
      const dataToIndexRatio = stats.size / (stats.indexSize || 1);
      if (dataToIndexRatio < 5) { // Low ratio might indicate over-indexing
        this.alerts.push({
          type: 'INDEX_EFFICIENCY',
          severity: 'MEDIUM',
          message: `Potential over-indexing in ${collectionName} (data:index ratio: ${dataToIndexRatio.toFixed(1)})`,
          collection: collectionName,
          value: dataToIndexRatio
        });
      }
    }

    return this.alerts;
  }

  async generateReport() {
    console.log('📋 Generating monitoring report...');

    const report = {
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      metrics: this.metrics,
      alerts: this.alerts,
      recommendations: []
    };

    // Generate recommendations based on metrics and alerts
    if (this.alerts.length > 0) {
      report.recommendations.push('Address the alerts listed above');
    }

    // Connection recommendations
    if (this.metrics.connections > this.thresholds.maxConnections * 0.8) {
      report.recommendations.push('Consider increasing connection pool size or implementing connection pooling');
    }

    // Index recommendations
    if (this.metrics.slowQueries.length > 0) {
      report.recommendations.push('Review and optimize slow queries - consider adding indexes');
      report.recommendations.push('Enable query profiling for detailed analysis');
    }

    // Storage recommendations
    const totalDataSize = this.metrics.storage.dataSize || 0;
    const totalIndexSize = this.metrics.storage.indexSize || 0;
    const indexToDataRatio = totalIndexSize / (totalDataSize || 1);

    if (indexToDataRatio > 1) {
      report.recommendations.push('High index-to-data ratio detected - review index usage');
    }

    // Performance recommendations
    if (this.metrics.operations.query > this.metrics.operations.insert * 10) {
      report.recommendations.push('High read-to-write ratio - consider read replicas for better performance');
    }

    return report;
  }

  async saveMetricsToFile(filename = null) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename_final = filename || `metrics-${timestamp}.json`;

    try {
      const fs = require('fs').promises;
      const report = await this.generateReport();
      await fs.writeFile(filename_final, JSON.stringify(report, null, 2));
      console.log(`✅ Metrics saved to: ${filename_final}`);
      return filename_final;
    } catch (error) {
      console.error('❌ Failed to save metrics:', error.message);
      return null;
    }
  }

  async enableProfiling(options = {}) {
    const {
      slowms = 1000,
      sampleRate = 1.0
    } = options;

    console.log(`🔧 Enabling query profiling (slowms: ${slowms}ms, sampleRate: ${sampleRate})`);

    try {
      const result = await this.db.setProfilingLevel(1, {
        slowms,
        sampleRate
      });

      console.log('✅ Query profiling enabled');
      return result;
    } catch (error) {
      console.error('❌ Failed to enable profiling:', error.message);
      return null;
    }
  }

  async disableProfiling() {
    console.log('🔧 Disabling query profiling');

    try {
      const result = await this.db.setProfilingLevel(0);
      console.log('✅ Query profiling disabled');
      return result;
    } catch (error) {
      console.error('❌ Failed to disable profiling:', error.message);
      return null;
    }
  }

  async analyzeQueryPerformance(query, options = {}) {
    console.log('🔍 Analyzing query performance...');

    try {
      const startTime = Date.now();

      // Execute the query with explain
      const explanation = await query.explain('executionStats');

      const executionTime = Date.now() - startTime;

      const analysis = {
        executionTime,
        totalDocsExamined: explanation.executionStats?.totalDocsExamined || 0,
        totalDocsReturned: explanation.executionStats?.totalDocsReturned || 0,
        indexesUsed: explanation.executionStats?.winningPlan?.inputStage?.indexName || 'No index',
        executionStages: explanation.executionStats?.executionStages || [],
        recommendations: []
      };

      // Generate recommendations
      if (analysis.totalDocsExamined > analysis.totalDocsReturned * 10) {
        analysis.recommendations.push('Query is examining too many documents - consider adding an index');
      }

      if (analysis.indexesUsed === 'No index') {
        analysis.recommendations.push('Query is not using any index - performance may be poor');
      }

      if (executionTime > 1000) {
        analysis.recommendations.push('Query execution time is high - optimization needed');
      }

      return analysis;

    } catch (error) {
      console.error('❌ Query analysis failed:', error.message);
      return null;
    }
  }

  async setupAutomatedMonitoring(intervalMinutes = 5) {
    console.log(`⏰ Setting up automated monitoring (every ${intervalMinutes} minutes)`);

    const monitoringInterval = setInterval(async () => {
      try {
        await this.collectMetrics();
        const alerts = this.checkAlerts();

        if (alerts.length > 0) {
          console.log(`🚨 ${alerts.length} alert(s) detected:`);
          alerts.forEach(alert => {
            const severityIcon = alert.severity === 'HIGH' ? '🔴' :
                               alert.severity === 'MEDIUM' ? '🟡' : '🟢';
            console.log(`   ${severityIcon} ${alert.type}: ${alert.message}`);
          });
        }

        // Auto-save metrics periodically
        const timestamp = new Date().toISOString().slice(0, 16).replace(/[:-]/g, '');
        await this.saveMetricsToFile(`metrics-${timestamp}.json`);

      } catch (error) {
        console.error('❌ Automated monitoring error:', error.message);
      }
    }, intervalMinutes * 60 * 1000);

    // Graceful shutdown
    process.on('SIGINT', () => {
      console.log('🛑 Stopping automated monitoring...');
      clearInterval(monitoringInterval);
      this.disconnect();
      process.exit(0);
    });

    console.log('✅ Automated monitoring started');
    return monitoringInterval;
  }

  async disconnect() {
    if (this.client) {
      await this.client.close();
      console.log('✅ Disconnected from MongoDB Atlas');
    }
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  if (!command || args.includes('--help') || args.includes('-h')) {
    console.log(`
MongoDB Atlas Monitoring & Alerting System

Usage:
  node monitoring-alerts.js <command> [options]

Commands:
  monitor                  Collect and display current metrics
  alerts                   Check for alerts and display them
  report                   Generate and display full monitoring report
  save [filename]          Save metrics to file
  profile-enable [slowms]  Enable query profiling (default slowms: 1000)
  profile-disable          Disable query profiling
  auto [minutes]           Start automated monitoring (default: 5 minutes)

Options:
  --help, -h              Show this help

Examples:
  node monitoring-alerts.js monitor
  node monitoring-alerts.js alerts
  node monitoring-alerts.js report
  node monitoring-alerts.js save my-metrics.json
  node monitoring-alerts.js profile-enable 500
  node monitoring-alerts.js auto 10
`);
    return;
  }

  const monitor = new DatabaseMonitor();
  const connected = await monitor.connect();
  if (!connected) process.exit(1);

  try {
    switch (command) {
      case 'monitor':
        const metrics = await monitor.collectMetrics();
        if (metrics) {
          console.log('\n📊 Current Metrics:');
          console.log(`   Connections: ${metrics.connections}`);
          console.log(`   Operations: ${JSON.stringify(metrics.operations, null, 2)}`);
          console.log(`   Memory: ${JSON.stringify(metrics.memory, null, 2)}`);
          console.log(`   Storage: ${JSON.stringify(metrics.storage, null, 2)}`);
          console.log(`   Slow Queries: ${metrics.slowQueries.length}`);
        }
        break;

      case 'alerts':
        await monitor.collectMetrics();
        const alerts = monitor.checkAlerts();
        if (alerts.length === 0) {
          console.log('✅ No alerts detected');
        } else {
          console.log(`🚨 ${alerts.length} alert(s) found:`);
          alerts.forEach(alert => {
            console.log(`   ${alert.severity}: ${alert.message}`);
          });
        }
        break;

      case 'report':
        await monitor.collectMetrics();
        monitor.checkAlerts();
        const report = await monitor.generateReport();
        console.log('\n📋 Monitoring Report:');
        console.log(JSON.stringify(report, null, 2));
        break;

      case 'save':
        await monitor.collectMetrics();
        monitor.checkAlerts();
        const filename = args[1];
        await monitor.saveMetricsToFile(filename);
        break;

      case 'profile-enable':
        const slowms = parseInt(args[1]) || 1000;
        await monitor.enableProfiling({ slowms });
        break;

      case 'profile-disable':
        await monitor.disableProfiling();
        break;

      case 'auto':
        const interval = parseInt(args[1]) || 5;
        await monitor.setupAutomatedMonitoring(interval);
        // Keep the process running
        return;

      default:
        console.error(`❌ Unknown command: ${command}`);
        console.log('Use --help for available commands');
        process.exit(1);
    }
  } catch (error) {
    console.error('❌ Command failed:', error.message);
    process.exit(1);
  } finally {
    await monitor.disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = DatabaseMonitor;