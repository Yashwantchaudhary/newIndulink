const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Indulink API is healthy',
    timestamp: new Date().toISOString(),
    environment: 'development',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Indulink E-commerce API',
    version: '1.0.0',
    documentation: '/api/docs',
  });
});

// Basic API endpoints
app.get('/api/products', (req, res) => {
  res.json({
    success: true,
    message: 'Products retrieved successfully',
    data: [
      {
        id: '1',
        name: 'Sample Product',
        price: 99.99,
        description: 'This is a sample product'
      }
    ]
  });
});

app.get('/api/categories', (req, res) => {
  res.json({
    success: true,
    message: 'Categories retrieved successfully',
    data: [
      {
        id: '1',
        name: 'Electronics',
        description: 'Electronic products'
      }
    ]
  });
});

// Auth endpoints
app.post('/api/auth/login', (req, res) => {
  res.json({
    success: true,
    message: 'Login successful',
    data: {
      user: {
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: 'customer'
      },
      accessToken: 'mock-jwt-token',
      refreshToken: 'mock-refresh-token'
    }
  });
});

app.post('/api/auth/register', (req, res) => {
  res.json({
    success: true,
    message: 'Registration successful',
    data: {
      user: {
        id: '1',
        name: 'New User',
        email: req.body.email,
        role: 'customer'
      },
      accessToken: 'mock-jwt-token',
      refreshToken: 'mock-refresh-token'
    }
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔══════════════════════════════════════════════╗
║                                              ║
║   🚀 Simple Indulink API Server              ║
║                                              ║
║   ✓ Server running on port ${PORT} (0.0.0.0)    ║
║   ✓ Health check: http://localhost:${PORT}/health ║
║                                              ║
╚══════════════════════════════════════════════╝
  `);
});