# Enhanced Authentication & Authorization System

## Overview

This document provides comprehensive documentation for the enhanced authentication and authorization system implemented in the Indulink E-commerce API. The system includes improved security features, role-based access control (RBAC), and comprehensive user management capabilities.

## Table of Contents

1. [Security Enhancements](#security-enhancements)
2. [Role-Based Access Control (RBAC)](#role-based-access-control-rbac)
3. [User Management System](#user-management-system)
4. [API Endpoints](#api-endpoints)
5. [Usage Examples](#usage-examples)
6. [Testing](#testing)
7. [Best Practices](#best-practices)

## Security Enhancements

### Password Security

- **Enhanced Password Validation**: Minimum 8 characters with requirements for uppercase, lowercase, numbers, and special characters
- **Password Strength Checking**: Real-time feedback with suggestions for improvement
- **Secure Hashing**: bcrypt with cost factor 14 for enhanced security
- **Password Change Detection**: Tracks when passwords were last changed

### Account Protection

- **Account Locking**: Automatic locking after 5 failed login attempts (30-minute lockout)
- **Login Attempt Tracking**: Monitors and limits failed login attempts
- **Email Verification**: Token-based email verification system
- **Two-Factor Authentication**: Support for TOTP and backup codes

### Token Security

- **JWT Enhancements**: Enhanced JWT token generation with explicit algorithms and claims
- **Refresh Token Security**: Unique identifiers (JTI) and enhanced validation
- **Token Expiry Management**: Configurable token lifetimes with clock skew tolerance
- **Password Change Detection**: Invalidates tokens when passwords are changed

### Rate Limiting

- **Login Rate Limiting**: 5 attempts per 15 minutes per IP
- **Registration Rate Limiting**: 3 attempts per hour per IP
- **Password Reset Rate Limiting**: 2 attempts per 30 minutes per IP
- **Global API Rate Limiting**: Configurable limits for all API endpoints

### Security Headers

- **Enhanced CSP**: Content Security Policy with fine-grained control
- **Security Headers**: XSS protection, frame options, referrer policy
- **Session Security**: Cache control and secure session management

## Role-Based Access Control (RBAC)

### Role Hierarchy

The system implements a role hierarchy with the following levels:

| Role | Level | Description |
|------|-------|-------------|
| superadmin | 4 | Full system access, can manage all resources |
| admin | 3 | Administrative access, can manage users and content |
| supplier | 2 | Business user access, can manage products and orders |
| customer | 1 | Standard user access, can view and purchase products |

### Permission System

The RBAC system includes fine-grained permissions:

**Customer Permissions:**
- `view_products`, `add_to_cart`, `checkout`
- `view_orders`, `manage_profile`, `view_wishlist`
- `manage_addresses`, `view_notifications`

**Supplier Permissions:**
- `manage_products`, `view_orders`, `manage_inventory`
- `view_analytics`, `manage_profile`, `manage_addresses`
- `view_notifications`, `manage_rfqs`

**Admin Permissions:**
- `manage_users`, `manage_products`, `manage_orders`
- `view_analytics`, `manage_settings`, `view_reports`
- `manage_content`, `manage_payments`, `manage_shipping`
- `manage_categories`, `manage_reviews`

**Superadmin Permissions:**
- `all_permissions` (bypasses all permission checks)
- `manage_admins`, `manage_roles`, `manage_permissions`
- `view_audit_logs`, `manage_system`

### RBAC Middleware Usage

```javascript
// Basic role-based access
const { rbacMiddleware } = require('../middleware/rbacMiddleware');

// Require specific roles
router.get('/admin-only',
    protect,
    rbacMiddleware([], ['admin', 'superadmin']),
    adminController
);

// Require specific permissions
router.put('/user-management',
    protect,
    rbacMiddleware(['manage_users']),
    userManagementController
);

// Combined role and permission requirements
router.delete('/sensitive-action',
    protect,
    rbacMiddleware(['delete_users'], ['admin']),
    sensitiveActionController
);
```

## User Management System

### Comprehensive User Management Features

1. **User Listing & Search**
   - Paginated user lists with filtering
   - Advanced search by name, email, role, status
   - Sorting and pagination controls

2. **User Creation & Management**
   - Admin user creation with validation
   - Bulk user updates and management
   - Role and permission assignment

3. **Security Management**
   - Account locking/unlocking
   - Password resets and updates
   - Activity monitoring and logging

4. **Analytics & Reporting**
   - User statistics and metrics
   - Role distribution analysis
   - Activity tracking and reporting

### User Management API Endpoints

| Endpoint | Method | Description | Required Role |
|----------|--------|-------------|----------------|
| `/api/admin/users` | GET | List all users with filtering | admin |
| `/api/admin/users` | POST | Create new user | admin |
| `/api/admin/users/:id` | GET | Get user details | admin |
| `/api/admin/users/:id` | PUT | Update user | admin |
| `/api/admin/users/:id` | DELETE | Delete user | admin |
| `/api/admin/users/bulk-update` | PUT | Bulk update users | admin |
| `/api/admin/users/stats` | GET | Get user statistics | admin |
| `/api/admin/users/search` | GET | Search users | admin |
| `/api/admin/users/export` | GET | Export user data | admin |
| `/api/admin/users/:id/permissions` | GET | Get user permissions | admin |
| `/api/admin/users/:id/permissions` | PUT | Update user permissions | admin |
| `/api/admin/users/:id/password` | PUT | Update user password | admin |
| `/api/admin/users/:id/unlock` | POST | Unlock user account | admin |
| `/api/admin/users/:id/activity` | GET | Get user activity | admin |

## API Endpoints

### Authentication Endpoints

#### User Registration
```
POST /api/auth/register
```
**Request Body:**
```json
{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "password": "Strong@1234",
    "phone": "+1234567890",
    "role": "customer"
}
```
**Response:**
```json
{
    "success": true,
    "message": "User registered successfully",
    "data": {
        "user": {
            "id": "5f8d0d55b54764421b7156a1",
            "firstName": "John",
            "lastName": "Doe",
            "email": "john@example.com",
            "role": "customer"
        },
        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
}
```

#### User Login
```
POST /api/auth/login
```
**Request Body:**
```json
{
    "email": "john@example.com",
    "password": "Strong@1234"
}
```
**Response:**
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "user": {
            "id": "5f8d0d55b54764421b7156a1",
            "firstName": "John",
            "lastName": "Doe",
            "email": "john@example.com",
            "role": "customer"
        },
        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
}
```

#### Token Refresh
```
POST /api/auth/refresh
```
**Request Body:**
```json
{
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```
**Response:**
```json
{
    "success": true,
    "data": {
        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
}
```

#### Password Update
```
PUT /api/auth/update-password
```
**Headers:**
```
Authorization: Bearer <access_token>
```
**Request Body:**
```json
{
    "currentPassword": "Old@1234",
    "newPassword": "NewStrong@1234"
}
```
**Response:**
```json
{
    "success": true,
    "message": "Password updated successfully"
}
```

#### Forgot Password
```
POST /api/auth/forgot-password
```
**Request Body:**
```json
{
    "email": "john@example.com"
}
```
**Response:**
```json
{
    "success": true,
    "message": "If an account with this email exists, a password reset link has been sent."
}
```

#### Reset Password
```
POST /api/auth/reset-password
```
**Request Body:**
```json
{
    "token": "reset_token_from_email",
    "newPassword": "NewStrong@1234"
}
```
**Response:**
```json
{
    "success": true,
    "message": "Password reset successfully"
}
```

## Usage Examples

### Enhanced Authentication Flow

```javascript
// Enhanced login with error handling
async function enhancedLogin(email, password) {
    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (!data.success) {
            if (data.code === 'ACCOUNT_LOCKED') {
                console.error('Account locked. Please try again later.');
                return;
            }

            if (data.code === 'INVALID_CREDENTIALS' && data.attemptsRemaining) {
                console.error(`Invalid credentials. ${data.attemptsRemaining} attempts remaining.`);
                return;
            }

            console.error('Login failed:', data.message);
            return;
        }

        // Store tokens securely
        localStorage.setItem('accessToken', data.data.accessToken);
        localStorage.setItem('refreshToken', data.data.refreshToken);

        console.log('Login successful!');
        return data.data.user;

    } catch (error) {
        console.error('Login error:', error);
    }
}

// Token refresh with enhanced security
async function refreshAccessToken() {
    try {
        const refreshToken = localStorage.getItem('refreshToken');

        const response = await fetch('/api/auth/refresh', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ refreshToken })
        });

        const data = await response.json();

        if (!data.success) {
            if (data.code === 'REFRESH_TOKEN_EXPIRED') {
                console.error('Session expired. Please login again.');
                return false;
            }

            console.error('Token refresh failed:', data.message);
            return false;
        }

        // Update access token
        localStorage.setItem('accessToken', data.data.accessToken);
        return true;

    } catch (error) {
        console.error('Token refresh error:', error);
        return false;
    }
}
```

### RBAC Usage Examples

```javascript
// Check user permissions before performing actions
async function performAdminAction(userId, action) {
    try {
        // Check if current user has permission
        const hasPermission = await checkUserPermission('manage_users');

        if (!hasPermission) {
            console.error('Insufficient permissions for this action');
            return;
        }

        const response = await fetch(`/api/admin/users/${userId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
            },
            body: JSON.stringify(action)
        });

        const data = await response.json();

        if (!data.success) {
            console.error('Action failed:', data.message);
            return;
        }

        console.log('Action successful:', data.message);
        return data.data;

    } catch (error) {
        console.error('Admin action error:', error);
    }
}

// Check user permission helper
async function checkUserPermission(requiredPermission) {
    try {
        const response = await fetch('/api/auth/me', {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
            }
        });

        const data = await response.json();

        if (!data.success) {
            return false;
        }

        const user = data.data;
        const permissions = user.permissions || [];

        // Superadmin has all permissions
        if (user.role === 'superadmin') {
            return true;
        }

        // Check if user has the required permission
        return permissions.includes(requiredPermission) ||
               permissions.includes('all_permissions');

    } catch (error) {
        console.error('Permission check error:', error);
        return false;
    }
}
```

### User Management Examples

```javascript
// Create new user (Admin only)
async function createUser(userData) {
    try {
        const response = await fetch('/api/admin/users', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
            },
            body: JSON.stringify(userData)
        });

        const data = await response.json();

        if (!data.success) {
            if (data.code === 'WEAK_PASSWORD') {
                console.error('Password too weak:', data.suggestions.join(', '));
                return;
            }

            console.error('User creation failed:', data.message);
            return;
        }

        console.log('User created successfully:', data.data);
        return data.data;

    } catch (error) {
        console.error('User creation error:', error);
    }
}

// Bulk update users (Admin only)
async function bulkUpdateUsers(userIds, updates) {
    try {
        const response = await fetch('/api/admin/users/bulk-update', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
            },
            body: JSON.stringify({ userIds, updates })
        });

        const data = await response.json();

        if (!data.success) {
            console.error('Bulk update failed:', data.message);
            return;
        }

        console.log('Bulk update results:',
            `${data.results.successCount} successful, ` +
            `${data.results.errorCount} failed`);

        return data.results;

    } catch (error) {
        console.error('Bulk update error:', error);
    }
}

// Get user statistics (Admin only)
async function getUserStatistics() {
    try {
        const response = await fetch('/api/admin/users/stats', {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
            }
        });

        const data = await response.json();

        if (!data.success) {
            console.error('Failed to get statistics:', data.message);
            return;
        }

        console.log('User Statistics:', data.data);
        return data.data;

    } catch (error) {
        console.error('Statistics error:', error);
    }
}
```

## Testing

### Running Tests

The system includes comprehensive unit and integration tests:

```bash
# Run all tests
npm test

# Run specific test files
npm test -- backend/tests/unit/authController.test.js
npm test -- backend/tests/unit/rbacMiddleware.test.js
npm test -- backend/tests/unit/userManagementController.test.js

# Run with coverage
npm test -- --coverage
```

### Test Coverage

The test suite covers:

1. **Authentication Tests**
   - Password strength validation
   - Account locking mechanisms
   - Token generation and validation
   - Rate limiting enforcement
   - Error handling and edge cases

2. **RBAC Tests**
   - Role-based access control
   - Permission validation
   - Hierarchy enforcement
   - Middleware functionality
   - Edge cases and error conditions

3. **User Management Tests**
   - CRUD operations
   - Bulk operations
   - Search and filtering
   - Statistics and reporting
   - Security and validation

## Best Practices

### Security Best Practices

1. **Password Management**
   - Always use strong passwords (minimum 8 characters with complexity)
   - Never store passwords in plain text
   - Implement password rotation policies
   - Use password managers for sensitive accounts

2. **Token Management**
   - Store tokens securely (use HttpOnly, Secure cookies in production)
   - Implement token rotation and short lifetimes
   - Monitor for token misuse and revoke compromised tokens
   - Use refresh tokens for long-lived sessions

3. **Account Security**
   - Monitor failed login attempts
   - Implement account lockout policies
   - Require email verification for new accounts
   - Enable two-factor authentication for sensitive accounts

4. **API Security**
   - Always use HTTPS in production
   - Implement proper CORS configuration
   - Use security headers and CSP
   - Monitor and rate limit API usage

### RBAC Best Practices

1. **Role Design**
   - Follow the principle of least privilege
   - Use role hierarchy for natural access levels
   - Avoid creating too many custom roles
   - Document role permissions clearly

2. **Permission Management**
   - Use fine-grained permissions for sensitive operations
   - Regularly audit permission assignments
   - Remove unused permissions
   - Document permission requirements

3. **Access Control**
   - Always check permissions before sensitive operations
   - Implement ownership verification for user-specific data
   - Use context-aware access control when needed
   - Log access control decisions for auditing

### User Management Best Practices

1. **User Provisioning**
   - Validate all user input thoroughly
   - Implement proper email verification
   - Set appropriate default roles and permissions
   - Monitor for suspicious registration patterns

2. **User Maintenance**
   - Regularly review user accounts and permissions
   - Deactivate inactive accounts
   - Implement proper account recovery procedures
   - Monitor for unusual account activity

3. **Data Protection**
   - Never expose sensitive user data in APIs
   - Implement proper data masking
   - Use field-level encryption for PII
   - Comply with data protection regulations

## Migration Guide

### From Previous Version

1. **Database Updates**
   - Run migrations to add new fields to User model
   - Update existing users with default permission sets
   - Set appropriate role levels for existing users

2. **Configuration Updates**
   - Update environment variables for new security settings
   - Configure rate limiting parameters
   - Set up security headers and CSP

3. **Code Updates**
   - Replace old authentication middleware with new enhanced versions
   - Update route handlers to use RBAC middleware
   - Implement new error handling patterns

4. **Testing**
   - Run comprehensive test suite
   - Verify all authentication flows
   - Test RBAC permissions
   - Validate user management functionality

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Check token validity and expiry
   - Verify account status (active/locked)
   - Ensure proper role assignments
   - Validate permission requirements

2. **Rate Limiting Issues**
   - Check rate limit headers in responses
   - Verify IP-based rate limiting
   - Review rate limit configuration
   - Monitor for abusive patterns

3. **Permission Denied Errors**
   - Verify user role and permissions
   - Check RBAC middleware configuration
   - Review role hierarchy settings
   - Audit permission assignments

4. **Token Validation Errors**
   - Check JWT secret configuration
   - Verify token signing algorithms
   - Ensure proper token storage
   - Validate token lifetime settings

## Support

For issues or questions regarding the enhanced authentication system:

- **Documentation**: Refer to this comprehensive guide
- **API Reference**: Check the interactive API documentation
- **Error Codes**: Review the error code reference
- **Contact**: Reach out to the development team for assistance

## Conclusion

This enhanced authentication and authorization system provides a robust foundation for secure user management in the Indulink E-commerce API. The combination of improved security features, fine-grained RBAC, and comprehensive user management capabilities ensures a secure and flexible access control system that can scale with business requirements.