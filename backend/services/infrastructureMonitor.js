// services/infrastructureMonitor.js
'use strict';

const os = require('os');
const fs = require('fs').promises;
const fsSync = require('fs');
const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const alertService = require('./alertService');

const COLLECT_INTERVAL_MS = parseInt(process.env.INFRA_COLLECT_INTERVAL_MS || '30000', 10);
const ALERT_INTERVAL_MS = parseInt(process.env.INFRA_ALERT_INTERVAL_MS || '120000', 10);
const RETENTION_POINTS = parseInt(process.env.INFRA_RETENTION_POINTS || '120', 10);

class InfrastructureMonitor {
  constructor() {
    this.metrics = { cpu: [], memory: [], disk: [], network: [], uptime: 0, loadAverage: [] };
    this.previousNetwork = null;
    this.alertThresholds = {
      cpuUsage: parseFloat(process.env.ALERT_CPU_USAGE || '80'),
      memoryUsage: parseFloat(process.env.ALERT_MEMORY_USAGE || '85'),
      diskUsage: parseFloat(process.env.ALERT_DISK_USAGE || '90'),
      loadAverage: os.cpus().length * 2,
    };
    this.lastAlertAt = {}; // key -> timestamp
    this.collectTimer = null;
    this.alertTimer = null;
    this.start();
  }

  start() {
    if (!this.collectTimer) this.collectTimer = setInterval(() => this.collectMetrics(), COLLECT_INTERVAL_MS);
    if (!this.alertTimer) this.alertTimer = setInterval(() => this.checkAlerts(), ALERT_INTERVAL_MS);
    // initial collect
    this.collectMetrics().catch((e) => console.error('Initial collect failed', e));
  }

  stop() {
    if (this.collectTimer) clearInterval(this.collectTimer);
    if (this.alertTimer) clearInterval(this.alertTimer);
    this.collectTimer = null;
    this.alertTimer = null;
  }

  async collectMetrics() {
    try {
      const timestamp = Date.now();
      const cpuUsage = this.getCpuUsage();
      this.metrics.cpu.push({ timestamp, usage: cpuUsage, cores: os.cpus().length });

      const totalMemory = os.totalmem();
      const freeMemory = os.freemem();
      const usedMemory = totalMemory - freeMemory;
      const memoryUsagePercent = totalMemory ? (usedMemory / totalMemory) * 100 : 0;
      this.metrics.memory.push({ timestamp, total: totalMemory, used: usedMemory, free: freeMemory, usagePercent: memoryUsagePercent });

      const diskStats = await this.getDiskUsage();
      this.metrics.disk.push({ timestamp, ...diskStats });

      const networkStats = await this.getNetworkStats();
      this.metrics.network.push({ timestamp, ...networkStats });

      const load = os.loadavg();
      this.metrics.loadAverage.push({ timestamp, '1min': load[0], '5min': load[1], '15min': load[2] });

      this.metrics.uptime = os.uptime();

      // retention
      ['cpu', 'memory', 'disk', 'network', 'loadAverage'].forEach((m) => {
        if (this.metrics[m].length > RETENTION_POINTS) this.metrics[m] = this.metrics[m].slice(-RETENTION_POINTS);
      });
    } catch (err) {
      console.error('collectMetrics error:', err && err.message ? err.message : err);
    }
  }

  getCpuUsage() {
    const cpus = os.cpus();
    let totalIdle = 0;
    let totalTick = 0;
    cpus.forEach((cpu) => {
      for (const t in cpu.times) totalTick += cpu.times[t];
      totalIdle += cpu.times.idle;
    });
    return totalTick ? 100 - (100 * totalIdle) / totalTick : 0;
  }

  async getDiskUsage() {
    try {
      // Linux: parse 'df -k /' output
      if (process.platform !== 'win32') {
        const { stdout } = await execAsync('df -k /');
        const lines = stdout.trim().split('\n');
        if (lines.length >= 2) {
          const parts = lines[1].split(/\s+/);
          const total = parseInt(parts[1], 10) * 1024;
          const used = parseInt(parts[2], 10) * 1024;
          const free = parseInt(parts[3], 10) * 1024;
          const usagePercent = total ? (used / total) * 100 : 0;
          return { total, used, free, usagePercent };
        }
      } else {
        // Windows fallback using wmic
        const { stdout } = await execAsync('wmic logicaldisk get size,freespace,caption');
        const lines = stdout.trim().split('\n').slice(1).map(l => l.trim()).filter(Boolean);
        // pick C: or first
        for (const line of lines) {
          const cols = line.split(/\s+/);
          if (cols.length >= 3) {
            const free = parseInt(cols[1], 10);
            const total = parseInt(cols[2], 10);
            const used = total - free;
            const usagePercent = total ? (used / total) * 100 : 0;
            return { total, used, free, usagePercent };
          }
        }
      }
    } catch (err) {
      console.warn('getDiskUsage fallback:', err && err.message ? err.message : err);
    }
    return { total: 0, used: 0, free: 0, usagePercent: 0 };
  }

  async getNetworkStats() {
    try {
      if (process.platform === 'linux' && fsSync.existsSync('/proc/net/dev')) {
        const raw = await fs.readFile('/proc/net/dev', 'utf8');
        const lines = raw.split('\n').slice(2);
        let rx = 0, tx = 0, ifaceCount = 0;
        for (const line of lines) {
          const parts = line.trim().split(/\s+/);
          if (parts.length >= 17) {
            const name = parts[0].replace(':', '');
            if (name && !name.startsWith('lo')) {
              ifaceCount++;
              rx += parseInt(parts[1], 10) || 0;
              tx += parseInt(parts[9], 10) || 0;
            }
          }
        }
        // compute delta if previous exists
        const now = Date.now();
        let rxDelta = 0, txDelta = 0;
        if (this.previousNetwork) {
          const dt = Math.max(1, (now - this.previousNetwork.ts) / 1000);
          rxDelta = Math.max(0, (rx - this.previousNetwork.rx) / dt);
          txDelta = Math.max(0, (tx - this.previousNetwork.tx) / dt);
        }
        this.previousNetwork = { rx, tx, ts: now };
        return { rxBytes: rx, txBytes: tx, rxPerSec: rxDelta, txPerSec: txDelta, interfaces: ifaceCount };
      }
    } catch (err) {
      console.warn('getNetworkStats fallback:', err && err.message ? err.message : err);
    }
    return { rxBytes: 0, txBytes: 0, rxPerSec: 0, txPerSec: 0, interfaces: 0 };
  }

  async checkAlerts() {
    try {
      const latest = this.getLatestMetrics();
      await this._maybeAlert('HIGH_CPU_USAGE', latest.cpu.usage, this.alertThresholds.cpuUsage, 'high', {
        cpuUsage: latest.cpu.usage, cores: latest.cpu.cores,
      });
      await this._maybeAlert('HIGH_MEMORY_USAGE', latest.memory.usagePercent, this.alertThresholds.memoryUsage, 'high', {
        memoryUsage: latest.memory.usagePercent, usedMemory: latest.memory.used, totalMemory: latest.memory.total,
      });
      await this._maybeAlert('HIGH_DISK_USAGE', latest.disk.usagePercent, this.alertThresholds.diskUsage, 'medium', {
        diskUsage: latest.disk.usagePercent, usedDisk: latest.disk.used, totalDisk: latest.disk.total,
      });
      await this._maybeAlert('HIGH_LOAD_AVERAGE', latest.loadAverage['1min'], this.alertThresholds.loadAverage, 'medium', {
        loadAverage1m: latest.loadAverage['1min'],
      });
    } catch (err) {
      console.error('checkAlerts error:', err && err.message ? err.message : err);
    }
  }

  async _maybeAlert(key, value, threshold, severity, meta = {}) {
    if (value <= threshold) return;
    const now = Date.now();
    const last = this.lastAlertAt[key] || 0;
    const cooldown = parseInt(process.env.ALERT_COOLDOWN_MS || '600000', 10); // default 10 minutes
    if (now - last < cooldown) return;
    this.lastAlertAt[key] = now;
    await alertService.sendAlert(key, severity, `${key} triggered: ${value}`, { ...meta, timestamp: new Date().toISOString() });
  }

  getLatestMetrics() {
    return {
      cpu: this.metrics.cpu[this.metrics.cpu.length - 1] || { usage: 0, cores: os.cpus().length },
      memory: this.metrics.memory[this.metrics.memory.length - 1] || { usagePercent: 0, total: 0, used: 0, free: 0 },
      disk: this.metrics.disk[this.metrics.disk.length - 1] || { usagePercent: 0, total: 0, used: 0, free: 0 },
      network: this.metrics.network[this.metrics.network.length - 1] || { rxBytes: 0, txBytes: 0, interfaces: 0 },
      loadAverage: this.metrics.loadAverage[this.metrics.loadAverage.length - 1] || { '1min': 0, '5min': 0, '15min': 0 },
      uptime: this.metrics.uptime,
    };
  }

  getInfrastructureReport() {
    const latest = this.getLatestMetrics();
    return {
      timestamp: new Date().toISOString(),
      system: { platform: os.platform(), arch: os.arch(), release: os.release(), hostname: os.hostname(), uptime: latest.uptime },
      cpu: { cores: latest.cpu.cores, usagePercent: Math.round(latest.cpu.usage * 10) / 10, loadAverage: latest.loadAverage },
      memory: {
        totalGB: Math.round((latest.memory.total / (1024 ** 3)) * 100) / 100,
        usedGB: Math.round((latest.memory.used / (1024 ** 3)) * 100) / 100,
        freeGB: Math.round((latest.memory.free / (1024 ** 3)) * 100) / 100,
        usagePercent: Math.round(latest.memory.usagePercent * 10) / 10,
      },
      disk: {
        totalGB: Math.round((latest.disk.total / (1024 ** 3)) * 100) / 100,
        usedGB: Math.round((latest.disk.used / (1024 ** 3)) * 100) / 100,
        freeGB: Math.round((latest.disk.free / (1024 ** 3)) * 100) / 100,
        usagePercent: Math.round(latest.disk.usagePercent * 10) / 10,
      },
      network: {
        interfaces: latest.network.interfaces,
        rxMB: Math.round((latest.network.rxBytes / (1024 ** 2)) * 100) / 100,
        txMB: Math.round((latest.network.txBytes / (1024 ** 2)) * 100) / 100,
        rxPerSec: latest.network.rxPerSec || 0,
        txPerSec: latest.network.txPerSec || 0,
      },
      alerts: { thresholds: this.alertThresholds, status: this.getHealthStatus() },
    };
  }

  getHealthStatus() {
    const latest = this.getLatestMetrics();
    const issues = [];
    if (latest.cpu.usage > this.alertThresholds.cpuUsage) issues.push('high_cpu');
    if (latest.memory.usagePercent > this.alertThresholds.memoryUsage) issues.push('high_memory');
    if (latest.disk.usagePercent > this.alertThresholds.diskUsage) issues.push('high_disk');
    if (latest.loadAverage['1min'] > this.alertThresholds.loadAverage) issues.push('high_load');
    return { status: issues.length === 0 ? 'healthy' : 'degraded', issues, issueCount: issues.length };
  }

  getHistoricalMetrics(minutes = 30) {
    const points = Math.max(1, Math.floor((minutes * 60 * 1000) / COLLECT_INTERVAL_MS));
    const recent = {};
    ['cpu', 'memory', 'disk', 'loadAverage'].forEach((m) => {
      recent[m] = this.metrics[m].slice(-points);
    });
    return { period: `${minutes} minutes`, dataPoints: points, metrics: recent };
  }

  async shutdown() {
    this.stop();
  }
}

module.exports = new InfrastructureMonitor();
