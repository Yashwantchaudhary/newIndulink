# INDULINK E-Commerce Platform API Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [Base URL and Environment](#base-url-and-environment)
3. [Authentication](#authentication)
4. [API Endpoints](#api-endpoints)
   - [Authentication Endpoints](#authentication-endpoints)
   - [User Management Endpoints](#user-management-endpoints)
   - [Product Management Endpoints](#product-management-endpoints)
   - [Order Management Endpoints](#order-management-endpoints)
   - [Category Management Endpoints](#category-management-endpoints)
   - [Review Management Endpoints](#review-management-endpoints)
   - [Message Management Endpoints](#message-management-endpoints)
   - [Notification Management Endpoints](#notification-management-endpoints)
   - [Wishlist Management Endpoints](#wishlist-management-endpoints)
   - [Address Management Endpoints](#address-management-endpoints)
   - [Filter Management Endpoints](#filter-management-endpoints)
   - [Cart Management Endpoints](#cart-management-endpoints)
   - [Supplier Management Endpoints](#supplier-management-endpoints)
   - [Dashboard Management Endpoints](#dashboard-management-endpoints)
   - [RFQ Management Endpoints](#rfq-management-endpoints)
   - [Admin Management Endpoints](#admin-management-endpoints)
   - [Export/Import Endpoints](#exportimport-endpoints)
   - [Analytics Endpoints](#analytics-endpoints)
   - [Inventory Management Endpoints](#inventory-management-endpoints)
   - [Push Notification Endpoints](#push-notification-endpoints)
5. [Request and Response Formats](#request-and-response-formats)
6. [Error Handling](#error-handling)
7. [Rate Limiting](#rate-limiting)
8. [Security](#security)
9. [Integration Guides](#integration-guides)
10. [WebSocket Integration](#websocket-integration)
11. [Monitoring and Metrics](#monitoring-and-metrics)

## Introduction

The INDULINK E-Commerce Platform API provides a comprehensive set of RESTful endpoints for managing all aspects of an e-commerce platform. This API supports multiple user roles including customers, suppliers, and administrators with role-based access control.

## Base URL and Environment

- **Base URL**: `http://localhost:5000/api` (Development)
- **Production URL**: `https://api.indulink.com/api` (Production)
- **Environment**: Development/Production
- **API Version**: 1.0.0

## Authentication

### JWT Authentication

The INDULINK API uses JSON Web Tokens (JWT) for authentication. All authenticated endpoints require a valid JWT token in the Authorization header.

#### Token Structure

- **Access Token**: Short-lived token (default: 15 minutes)
- **Refresh Token**: Long-lived token (default: 7 days)
- **Algorithm**: HS256
- **Header Format**: `Authorization: Bearer <token>`

#### Authentication Flow

1. **Register**: `POST /api/auth/register`
2. **Login**: `POST /api/auth/login`
3. **Use Access Token**: Include in Authorization header for protected endpoints
4. **Refresh Token**: `POST /api/auth/refresh` when access token expires
5. **Logout**: `POST /api/auth/logout`

### Role-Based Access Control

The API supports three main user roles:

- **Customer**: Regular e-commerce customers
- **Supplier**: Product suppliers and vendors
- **Admin**: System administrators

### Authentication Headers

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

## API Endpoints

### Authentication Endpoints

#### Register User
- **Endpoint**: `POST /api/auth/register`
- **Access**: Public
- **Description**: Register a new user
- **Request Body**:
```json
{
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "password": "string",
  "phone": "string",
  "role": "customer|supplier|admin"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "string",
      "firstName": "string",
      "lastName": "string",
      "email": "string",
      "role": "string"
    },
    "accessToken": "string",
    "refreshToken": "string"
  }
}
```

#### Login User
- **Endpoint**: `POST /api/auth/login`
- **Access**: Public
- **Request Body**:
```json
{
  "email": "string",
  "password": "string"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "string",
      "firstName": "string",
      "lastName": "string",
      "email": "string",
      "role": "string"
    },
    "accessToken": "string",
    "refreshToken": "string"
  }
}
```

#### Refresh Token
- **Endpoint**: `POST /api/auth/refresh`
- **Access**: Public
- **Request Body**:
```json
{
  "refreshToken": "string"
}
```
- **Response**:
```json
{
  "success": true,
  "data": {
    "accessToken": "string"
  }
}
```

#### Get Current User
- **Endpoint**: `GET /api/auth/me`
- **Access**: Private
- **Response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "string",
      "firstName": "string",
      "lastName": "string",
      "email": "string",
      "role": "string"
    }
  }
}
```

### User Management Endpoints

#### Get User Profile
- **Endpoint**: `GET /api/users/profile`
- **Access**: Private
- **Response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "string",
      "firstName": "string",
      "lastName": "string",
      "email": "string",
      "phone": "string",
      "role": "string",
      "createdAt": "date",
      "updatedAt": "date"
    }
  }
}
```

#### Update User Profile
- **Endpoint**: `PUT /api/users/profile`
- **Access**: Private
- **Request Body**:
```json
{
  "firstName": "string",
  "lastName": "string",
  "phone": "string"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "user": {
      "id": "string",
      "firstName": "string",
      "lastName": "string",
      "email": "string",
      "phone": "string"
    }
  }
}
```

### Product Management Endpoints

#### Get All Products
- **Endpoint**: `GET /api/products`
- **Access**: Public
- **Query Parameters**:
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 10)
  - `category`: Filter by category
  - `search`: Search term
  - `minPrice`: Minimum price
  - `maxPrice`: Maximum price
- **Response**:
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": "string",
        "name": "string",
        "description": "string",
        "price": "number",
        "category": "string",
        "stock": "number",
        "images": ["string"],
        "createdAt": "date"
      }
    ],
    "pagination": {
      "total": "number",
      "page": "number",
      "limit": "number",
      "totalPages": "number"
    }
  }
}
```

#### Get Single Product
- **Endpoint**: `GET /api/products/:id`
- **Access**: Public
- **Response**:
```json
{
  "success": true,
  "data": {
    "product": {
      "id": "string",
      "name": "string",
      "description": "string",
      "price": "number",
      "category": "string",
      "stock": "number",
      "images": ["string"],
      "reviews": ["string"],
      "createdAt": "date"
    }
  }
}
```

### Order Management Endpoints

#### Create Order
- **Endpoint**: `POST /api/orders`
- **Access**: Private (Customer)
- **Request Body**:
```json
{
  "items": [
    {
      "productId": "string",
      "quantity": "number",
      "price": "number"
    }
  ],
  "shippingAddress": "string",
  "paymentMethod": "string",
  "totalAmount": "number"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "order": {
      "id": "string",
      "userId": "string",
      "items": ["object"],
      "status": "pending",
      "totalAmount": "number",
      "createdAt": "date"
    }
  }
}
```

#### Get Customer Orders
- **Endpoint**: `GET /api/orders`
- **Access**: Private (Customer)
- **Response**:
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": "string",
        "userId": "string",
        "items": ["object"],
        "status": "string",
        "totalAmount": "number",
        "createdAt": "date"
      }
    ]
  }
}
```

### Error Handling

The API follows consistent error response patterns:

#### Common Error Responses

**400 Bad Request**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": ["array of error messages"]
}
```

**401 Unauthorized**
```json
{
  "success": false,
  "message": "Not authorized to access this route",
  "code": "UNAUTHORIZED"
}
```

**403 Forbidden**
```json
{
  "success": false,
  "message": "User role 'customer' is not authorized to access this route",
  "code": "FORBIDDEN"
}
```

**404 Not Found**
```json
{
  "success": false,
  "message": "Resource not found",
  "code": "NOT_FOUND"
}
```

**500 Server Error**
```json
{
  "success": false,
  "message": "Server error",
  "stack": "error stack trace" (development only)
}
```

### Rate Limiting

- **Default Rate Limit**: 100 requests per 15 minutes
- **Auth Routes**: Special rate limits for login/register endpoints
- **Headers**:
  - `X-RateLimit-Limit`: Total allowed requests
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Time when limit resets

### Security

- **CORS**: Configurable allowed origins
- **CSRF Protection**: Enabled via security headers
- **Content Security Policy**: Strict CSP headers
- **Rate Limiting**: Protection against brute force attacks
- **JWT Security**: Secure token handling with refresh tokens

### Integration Guides

#### Frontend Integration

```javascript
// Example using Axios
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle token refresh
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        const response = await axios.post('/api/auth/refresh', { refreshToken });
        localStorage.setItem('accessToken', response.data.accessToken);
        originalRequest.headers.Authorization = `Bearer ${response.data.accessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        // Redirect to login
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);
```

#### Mobile App Integration

```swift
// Swift example
let url = URL(string: "http://localhost:5000/api/auth/login")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
    "email": "user@example.com",
    "password": "password123"
]

request.httpBody = try? JSONSerialization.data(withJSONObject: body)

URLSession.shared.dataTask(with: request) { data, response, error in
    if let data = data {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print(json)
        }
    }
}.resume()
```

### WebSocket Integration

The platform supports real-time updates via WebSocket:

```javascript
const socket = io('http://localhost:5000', {
  withCredentials: true,
  extraHeaders: {
    Authorization: `Bearer ${accessToken}`
  }
});

socket.on('connect', () => {
  console.log('Connected to WebSocket server');
});

socket.on('product_updated', (data) => {
  console.log('Product updated:', data);
  // Update UI in real-time
});

socket.on('order_status_changed', (data) => {
  console.log('Order status changed:', data);
  // Update order status in UI
});
```

### Monitoring and Metrics

#### Health Check
- **Endpoint**: `GET /health`
- **Response**:
```json
{
  "success": true,
  "message": "Indulink API is healthy",
  "timestamp": "date",
  "environment": "development",
  "infrastructure": {
    "status": "healthy",
    "metrics": {}
  },
  "uptime": "number",
  "memory": {
    "rss": "number",
    "heapTotal": "number",
    "heapUsed": "number"
  }
}
```

#### API Metrics
- **Endpoint**: `GET /api/metrics`
- **Response**:
```json
{
  "success": true,
  "message": "System metrics retrieved successfully",
  "data": {
    "api": {
      "totalRequests": "number",
      "responseTimes": {
        "avg": "number",
        "max": "number",
        "min": "number"
      },
      "errorRate": "number"
    },
    "infrastructure": {
      "status": "string",
      "metrics": {}
    },
    "timestamp": "date"
  }
}
```

## API Versioning

The current API version is **1.0.0**. All endpoints are prefixed with `/api/` for versioning.

## Support and Contact

For API support or issues, contact:
- **Email**: support@indulink.com
- **Documentation**: https://docs.indulink.com
- **Status Page**: https://status.indulink.com

## Changelog

**Version 1.0.0** - Initial release with full e-commerce functionality
- Authentication system with JWT
- Product management
- Order processing
- User management
- Real-time notifications
- Comprehensive error handling