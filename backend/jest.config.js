module.exports = {
  testEnvironment: 'node',
  testMatch: [
    '<rootDir>/tests/**/*.test.js',
    '<rootDir>/tests/**/*.spec.js'
  ],
  collectCoverageFrom: [
    'controllers/**/*.js',
    'models/**/*.js',
    'services/**/*.js',
    'middleware/**/*.js',
    'utils/**/*.js',
    'routes/**/*.js',
    '!**/node_modules/**',
    '!**/tests/**',
    '!**/scripts/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: [
    'text',
    'lcov',
    'html',
    'json'
  ],
  coverageThreshold: {
    global: {
      branches: 0,
      functions: 0,
      lines: 0,
      statements: 0
    }
  },
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testTimeout: 30000,
  verbose: true,
  forceExit: true,
  detectOpenHandles: true,
  // Handle ES modules
  transformIgnorePatterns: [
    'node_modules/(?!(supertest|@faker-js/faker)/)'
  ],
  // Mock external services for testing
  moduleNameMapper: {
    '^@faker-js/faker$': '<rootDir>/tests/mocks/faker.js'
  }
};