const os = require('os');
const fs = require('fs').promises;
const path = require('path');
const alertService = require('./alertService');

/**
 * Infrastructure Monitoring Service
 * Monitors server resources, system health, and scaling events
 */
class InfrastructureMonitor {
  constructor() {
    this.metrics = {
      cpu: [],
      memory: [],
      disk: [],
      network: [],
      uptime: 0,
      loadAverage: []
    };

    this.previousNetworkStats = null;
    this.alertThresholds = {
      cpuUsage: 80, // 80%
      memoryUsage: 85, // 85%
      diskUsage: 90, // 90%
      loadAverage: os.cpus().length * 2, // 2x CPU cores
    };

    // Collect metrics every 30 seconds
    setInterval(() => {
      this.collectMetrics();
    }, 30000);

    // Check alerts every 2 minutes
    setInterval(() => {
      this.checkAlerts();
    }, 120000);
  }

  /**
   * Collect current system metrics
   */
  async collectMetrics() {
    try {
      const timestamp = new Date().toISOString();

      // CPU metrics
      const cpuUsage = this.getCpuUsage();
      this.metrics.cpu.push({
        timestamp,
        usage: cpuUsage,
        cores: os.cpus().length
      });

      // Memory metrics
      const totalMemory = os.totalmem();
      const freeMemory = os.freemem();
      const usedMemory = totalMemory - freeMemory;
      const memoryUsagePercent = (usedMemory / totalMemory) * 100;

      this.metrics.memory.push({
        timestamp,
        total: totalMemory,
        used: usedMemory,
        free: freeMemory,
        usagePercent: memoryUsagePercent
      });

      // Disk metrics
      const diskStats = await this.getDiskUsage();
      this.metrics.disk.push({
        timestamp,
        ...diskStats
      });

      // Network metrics
      const networkStats = this.getNetworkStats();
      this.metrics.network.push({
        timestamp,
        ...networkStats
      });

      // System load
      const loadAverage = os.loadavg();
      this.metrics.loadAverage.push({
        timestamp,
        '1min': loadAverage[0],
        '5min': loadAverage[1],
        '15min': loadAverage[2]
      });

      // Update uptime
      this.metrics.uptime = os.uptime();

      // Keep only last 120 data points (1 hour of 30-second intervals)
      ['cpu', 'memory', 'disk', 'network', 'loadAverage'].forEach(metric => {
        if (this.metrics[metric].length > 120) {
          this.metrics[metric] = this.metrics[metric].slice(-120);
        }
      });

    } catch (error) {
      console.error('Failed to collect infrastructure metrics:', error.message);
    }
  }

  /**
   * Get CPU usage percentage
   */
  getCpuUsage() {
    const cpus = os.cpus();
    let totalIdle = 0;
    let totalTick = 0;

    cpus.forEach(cpu => {
      for (const type in cpu.times) {
        totalTick += cpu.times[type];
      }
      totalIdle += cpu.times.idle;
    });

    return 100 - ~~(100 * totalIdle / totalTick);
  }

  /**
   * Get disk usage statistics
   */
  async getDiskUsage() {
    try {
      // For simplicity, check the root filesystem
      // In production, you might want to check specific mount points
      const stats = await fs.statvfs ? fs.statvfs('/') : { blocks: 1, bfree: 1, bsize: 1 };

      if (stats.blocks && stats.bfree !== undefined) {
        const total = stats.blocks * stats.bsize;
        const free = stats.bfree * stats.bsize;
        const used = total - free;
        const usagePercent = (used / total) * 100;

        return {
          total,
          used,
          free,
          usagePercent
        };
      }

      // Fallback for systems without statvfs
      return {
        total: 0,
        used: 0,
        free: 0,
        usagePercent: 0
      };
    } catch (error) {
      console.error('Failed to get disk usage:', error.message);
      return {
        total: 0,
        used: 0,
        free: 0,
        usagePercent: 0
      };
    }
  }

  /**
   * Get network statistics
   */
  getNetworkStats() {
    const networkInterfaces = os.networkInterfaces();
    let rxBytes = 0;
    let txBytes = 0;

    // Sum up all network interfaces
    Object.values(networkInterfaces).forEach(interfaces => {
      interfaces?.forEach(iface => {
        // Only count IPv4 interfaces
        if (iface.family === 'IPv4' && !iface.internal) {
          // Note: Node.js doesn't provide network byte counts directly
          // This is a simplified version
        }
      });
    });

    return {
      rxBytes,
      txBytes,
      interfaces: Object.keys(networkInterfaces).length
    };
  }

  /**
   * Check for infrastructure alerts
   */
  async checkAlerts() {
    try {
      const latestMetrics = this.getLatestMetrics();

      // CPU usage alert
      if (latestMetrics.cpu.usage > this.alertThresholds.cpuUsage) {
        await alertService.sendAlert(
          'HIGH_CPU_USAGE',
          'high',
          `CPU usage is ${latestMetrics.cpu.usage.toFixed(1)}% (threshold: ${this.alertThresholds.cpuUsage}%)`,
          {
            cpuUsage: latestMetrics.cpu.usage,
            cores: latestMetrics.cpu.cores,
            threshold: this.alertThresholds.cpuUsage,
            timestamp: new Date().toISOString()
          }
        );
      }

      // Memory usage alert
      if (latestMetrics.memory.usagePercent > this.alertThresholds.memoryUsage) {
        await alertService.sendAlert(
          'HIGH_MEMORY_USAGE',
          'high',
          `Memory usage is ${latestMetrics.memory.usagePercent.toFixed(1)}% (threshold: ${this.alertThresholds.memoryUsage}%)`,
          {
            memoryUsage: latestMetrics.memory.usagePercent,
            usedMemory: latestMetrics.memory.used,
            totalMemory: latestMetrics.memory.total,
            threshold: this.alertThresholds.memoryUsage,
            timestamp: new Date().toISOString()
          }
        );
      }

      // Disk usage alert
      if (latestMetrics.disk.usagePercent > this.alertThresholds.diskUsage) {
        await alertService.sendAlert(
          'HIGH_DISK_USAGE',
          'medium',
          `Disk usage is ${latestMetrics.disk.usagePercent.toFixed(1)}% (threshold: ${this.alertThresholds.diskUsage}%)`,
          {
            diskUsage: latestMetrics.disk.usagePercent,
            usedDisk: latestMetrics.disk.used,
            totalDisk: latestMetrics.disk.total,
            threshold: this.alertThresholds.diskUsage,
            timestamp: new Date().toISOString()
          }
        );
      }

      // Load average alert
      if (latestMetrics.loadAverage['1min'] > this.alertThresholds.loadAverage) {
        await alertService.sendAlert(
          'HIGH_LOAD_AVERAGE',
          'medium',
          `System load average (1min) is ${latestMetrics.loadAverage['1min'].toFixed(2)} (threshold: ${this.alertThresholds.loadAverage})`,
          {
            loadAverage1m: latestMetrics.loadAverage['1min'],
            loadAverage5m: latestMetrics.loadAverage['5min'],
            loadAverage15m: latestMetrics.loadAverage['15min'],
            threshold: this.alertThresholds.loadAverage,
            timestamp: new Date().toISOString()
          }
        );
      }

    } catch (error) {
      console.error('Failed to check infrastructure alerts:', error.message);
    }
  }

  /**
   * Get latest metrics summary
   */
  getLatestMetrics() {
    return {
      cpu: this.metrics.cpu[this.metrics.cpu.length - 1] || { usage: 0, cores: os.cpus().length },
      memory: this.metrics.memory[this.metrics.memory.length - 1] || { usagePercent: 0, total: 0, used: 0, free: 0 },
      disk: this.metrics.disk[this.metrics.disk.length - 1] || { usagePercent: 0, total: 0, used: 0, free: 0 },
      network: this.metrics.network[this.metrics.network.length - 1] || { rxBytes: 0, txBytes: 0, interfaces: 0 },
      loadAverage: this.metrics.loadAverage[this.metrics.loadAverage.length - 1] || { '1min': 0, '5min': 0, '15min': 0 },
      uptime: this.metrics.uptime
    };
  }

  /**
   * Get comprehensive infrastructure report
   */
  getInfrastructureReport() {
    const latest = this.getLatestMetrics();

    return {
      timestamp: new Date().toISOString(),
      system: {
        platform: os.platform(),
        arch: os.arch(),
        release: os.release(),
        hostname: os.hostname(),
        uptime: latest.uptime
      },
      cpu: {
        cores: latest.cpu.cores,
        usagePercent: Math.round(latest.cpu.usage * 10) / 10,
        loadAverage: {
          '1min': Math.round(latest.loadAverage['1min'] * 100) / 100,
          '5min': Math.round(latest.loadAverage['5min'] * 100) / 100,
          '15min': Math.round(latest.loadAverage['15min'] * 100) / 100
        }
      },
      memory: {
        totalGB: Math.round((latest.memory.total / (1024 ** 3)) * 100) / 100,
        usedGB: Math.round((latest.memory.used / (1024 ** 3)) * 100) / 100,
        freeGB: Math.round((latest.memory.free / (1024 ** 3)) * 100) / 100,
        usagePercent: Math.round(latest.memory.usagePercent * 10) / 10
      },
      disk: {
        totalGB: Math.round((latest.disk.total / (1024 ** 3)) * 100) / 100,
        usedGB: Math.round((latest.disk.used / (1024 ** 3)) * 100) / 100,
        freeGB: Math.round((latest.disk.free / (1024 ** 3)) * 100) / 100,
        usagePercent: Math.round(latest.disk.usagePercent * 10) / 10
      },
      network: {
        interfaces: latest.network.interfaces,
        rxMB: Math.round((latest.network.rxBytes / (1024 ** 2)) * 100) / 100,
        txMB: Math.round((latest.network.txBytes / (1024 ** 2)) * 100) / 100
      },
      alerts: {
        thresholds: this.alertThresholds,
        status: this.getHealthStatus()
      }
    };
  }

  /**
   * Get system health status
   */
  getHealthStatus() {
    const latest = this.getLatestMetrics();
    const issues = [];

    if (latest.cpu.usage > this.alertThresholds.cpuUsage) {
      issues.push('high_cpu');
    }
    if (latest.memory.usagePercent > this.alertThresholds.memoryUsage) {
      issues.push('high_memory');
    }
    if (latest.disk.usagePercent > this.alertThresholds.diskUsage) {
      issues.push('high_disk');
    }
    if (latest.loadAverage['1min'] > this.alertThresholds.loadAverage) {
      issues.push('high_load');
    }

    return {
      status: issues.length === 0 ? 'healthy' : 'degraded',
      issues: issues,
      issueCount: issues.length
    };
  }

  /**
   * Get historical metrics for charting
   */
  getHistoricalMetrics(minutes = 30) {
    const dataPoints = (minutes * 60) / 30; // 30-second intervals
    const recentData = {};

    ['cpu', 'memory', 'disk', 'loadAverage'].forEach(metric => {
      recentData[metric] = this.metrics[metric].slice(-dataPoints);
    });

    return {
      period: `${minutes} minutes`,
      dataPoints: dataPoints,
      metrics: recentData
    };
  }
}

// Export singleton instance
const infrastructureMonitor = new InfrastructureMonitor();

module.exports = infrastructureMonitor;