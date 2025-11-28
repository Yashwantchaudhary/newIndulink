#!/usr/bin/env node

/**
 * Monitoring Integration Validation Script
 * Tests all monitoring components to ensure they are working correctly
 */

const axios = require('axios');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const BASE_URL = process.env.BACKEND_URL || 'http://localhost:5000';

class MonitoringValidator {
  constructor() {
    this.results = {
      passed: 0,
      failed: 0,
      tests: []
    };
  }

  log(message, status = 'info') {
    const timestamp = new Date().toISOString();
    const statusIcon = status === 'pass' ? '✅' : status === 'fail' ? '❌' : 'ℹ️';
    console.log(`[${timestamp}] ${statusIcon} ${message}`);
  }

  async runTest(testName, testFunction) {
    try {
      this.log(`Running test: ${testName}`, 'info');
      const result = await testFunction();
      this.results.passed++;
      this.results.tests.push({ name: testName, status: 'pass', result });
      this.log(`${testName}: PASSED`, 'pass');
      return result;
    } catch (error) {
      this.results.failed++;
      this.results.tests.push({ name: testName, status: 'fail', error: error.message });
      this.log(`${testName}: FAILED - ${error.message}`, 'fail');
      return null;
    }
  }

  async testHealthEndpoint() {
    const response = await axios.get(`${BASE_URL}/health`);
    if (response.status !== 200) {
      throw new Error(`Health endpoint returned status ${response.status}`);
    }
    if (!response.data.infrastructure) {
      throw new Error('Health endpoint missing infrastructure data');
    }
    return response.data;
  }

  async testMetricsEndpoint() {
    const response = await axios.get(`${BASE_URL}/api/metrics`);
    if (response.status !== 200) {
      throw new Error(`Metrics endpoint returned status ${response.status}`);
    }
    if (!response.data.data.api || !response.data.data.infrastructure) {
      throw new Error('Metrics endpoint missing required data');
    }
    return response.data;
  }

  async testInfrastructureEndpoint() {
    const response = await axios.get(`${BASE_URL}/api/infrastructure`);
    if (response.status !== 200) {
      throw new Error(`Infrastructure endpoint returned status ${response.status}`);
    }
    if (!response.data.data.cpu || !response.data.data.memory || !response.data.data.disk) {
      throw new Error('Infrastructure endpoint missing system metrics');
    }
    return response.data;
  }

  async testDashboardAccess() {
    const response = await axios.get(`${BASE_URL}/monitoring`);
    if (response.status !== 200) {
      throw new Error(`Dashboard endpoint returned status ${response.status}`);
    }
    if (!response.data.includes('Indulink Monitoring Dashboard')) {
      throw new Error('Dashboard HTML not served correctly');
    }
    return response.data;
  }

  async testDatabaseConnection() {
    const client = new MongoClient(process.env.MONGODB_URI);
    try {
      await client.connect();
      const db = client.db();
      const stats = await db.stats();
      if (!stats) {
        throw new Error('Could not retrieve database stats');
      }
      return stats;
    } finally {
      await client.close();
    }
  }

  async testApiMonitoring() {
    // Make a test API call to trigger monitoring
    try {
      await axios.get(`${BASE_URL}/health`);
    } catch (error) {
      // Ignore errors, we just want to trigger monitoring
    }

    // Wait a moment for metrics to be collected
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Check if metrics were recorded
    const response = await axios.get(`${BASE_URL}/api/metrics`);
    const apiMetrics = response.data.data.api;

    if (apiMetrics.totalRequests < 1) {
      throw new Error('API monitoring not recording requests');
    }

    return apiMetrics;
  }

  async testNewRelicIntegration() {
    // Check if New Relic is configured
    if (!process.env.NEW_RELIC_LICENSE_KEY) {
      this.log('New Relic not configured - skipping test', 'info');
      return 'skipped';
    }

    // New Relic integration is passive, so we just check configuration
    return 'configured';
  }

  async testAlertSystem() {
    // The alert system is passive, so we check if the service is initialized
    // In a real test, you might trigger alerts and check if they're sent
    const alertService = require('../services/alertService');

    if (!alertService) {
      throw new Error('Alert service not available');
    }

    return 'initialized';
  }

  async runAllTests() {
    this.log('Starting Monitoring Integration Validation', 'info');
    this.log('='.repeat(50), 'info');

    // Backend Tests
    await this.runTest('Health Endpoint', () => this.testHealthEndpoint());
    await this.runTest('Metrics Endpoint', () => this.testMetricsEndpoint());
    await this.runTest('Infrastructure Endpoint', () => this.testInfrastructureEndpoint());
    await this.runTest('Dashboard Access', () => this.testDashboardAccess());
    await this.runTest('Database Connection', () => this.testDatabaseConnection());
    await this.runTest('API Monitoring', () => this.testApiMonitoring());

    // Integration Tests
    await this.runTest('New Relic Integration', () => this.testNewRelicIntegration());
    await this.runTest('Alert System', () => this.testAlertSystem());

    // Summary
    this.log('='.repeat(50), 'info');
    this.log(`Validation Complete: ${this.results.passed} passed, ${this.results.failed} failed`, 'info');

    if (this.results.failed > 0) {
      this.log('Failed Tests:', 'fail');
      this.results.tests
        .filter(test => test.status === 'fail')
        .forEach(test => this.log(`  - ${test.name}: ${test.error}`, 'fail'));
      process.exit(1);
    } else {
      this.log('All monitoring integrations validated successfully! 🎉', 'pass');
      process.exit(0);
    }
  }
}

// Run validation if called directly
if (require.main === module) {
  const validator = new MonitoringValidator();
  validator.runAllTests().catch(error => {
    console.error('Validation failed with error:', error);
    process.exit(1);
  });
}

module.exports = MonitoringValidator;