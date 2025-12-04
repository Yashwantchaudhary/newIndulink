# 📋 INDULINK Profile Management Technical Specification

## 📖 Document Overview

This technical specification provides detailed implementation requirements for the INDULINK profile management system, including API specifications, database schemas, security requirements, and integration guidelines.

## 🔧 API Specifications

### Base URL
```
https://api.indulink.com/api/v1
```

### Authentication
All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

### 1. User Profile Endpoints

#### GET `/users/profile`
**Description**: Retrieve current user's profile data
**Authentication**: Required
**Response**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "phone": "string",
    "role": "customer|supplier|admin",
    "profileImage": "string|null",
    "businessName": "string|null",
    "businessDescription": "string|null",
    "businessAddress": "string|null",
    "businessLicense": "string|null",
    "notificationPreferences": {
      "orderUpdates": true,
      "promotions": true,
      "messages": true,
      "system": true,
      "emailNotifications": true,
      "pushNotifications": true
    },
    "language": "en|ne|hi",
    "themeMode": "light|dark|system",
    "isEmailVerified": true,
    "isActive": true,
    "createdAt": "ISO8601",
    "updatedAt": "ISO8601"
  }
}
```

#### PUT `/users/profile`
**Description**: Update user profile information
**Authentication**: Required
**Request Body**:
```json
{
  "firstName": "string",
  "lastName": "string",
  "phone": "string",
  "businessName": "string",
  "businessDescription": "string",
  "businessAddress": "string",
  "businessLicense": "string",
  "language": "en|ne|hi"
}
```
**Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "string",
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "phone": "string",
    "role": "customer|supplier|admin",
    "businessName": "string|null",
    "businessDescription": "string|null",
    "businessAddress": "string|null",
    "businessLicense": "string|null",
    "language": "en|ne|hi",
    "updatedAt": "ISO8601"
  }
}
```

### 2. Profile Image Endpoints

#### POST `/users/profile/image`
**Description**: Upload profile image
**Authentication**: Required
**Request**: `multipart/form-data` with `image` field
**Response**:
```json
{
  "success": true,
  "message": "Profile image uploaded successfully",
  "data": {
    "profileImage": "string"
  }
}
```

### 3. Notification Preferences Endpoints

#### GET `/users/notification-preferences`
**Description**: Get current notification preferences
**Authentication**: Required
**Response**:
```json
{
  "success": true,
  "data": {
    "orderUpdates": true,
    "promotions": true,
    "messages": true,
    "system": true,
    "emailNotifications": true,
    "pushNotifications": true
  }
}
```

#### PUT `/users/notification-preferences`
**Description**: Update notification preferences
**Authentication**: Required
**Request Body**:
```json
{
  "orderUpdates": true,
  "promotions": true,
  "messages": true,
  "system": true,
  "emailNotifications": true,
  "pushNotifications": true
}
```
**Response**:
```json
{
  "success": true,
  "message": "Notification preferences updated successfully",
  "data": {
    "orderUpdates": true,
    "promotions": true,
    "messages": true,
    "system": true,
    "emailNotifications": true,
    "pushNotifications": true
  }
}
```

### 4. Theme Preferences Endpoints

#### GET `/users/theme-preference`
**Description**: Get saved theme preference
**Authentication**: Required
**Response**:
```json
{
  "success": true,
  "data": {
    "themeMode": "light|dark|system"
  }
}
```

#### PUT `/users/theme-preference`
**Description**: Save theme preference
**Authentication**: Required
**Request Body**:
```json
{
  "themeMode": "light|dark|system"
}
```
**Response**:
```json
{
  "success": true,
  "message": "Theme preference saved successfully",
  "data": {
    "themeMode": "light|dark|system"
  }
}
```

## 🗃️ Database Schema

### User Collection (MongoDB)

```javascript
{
  _id: ObjectId,
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    match: /^\S+@\S+\.\S+$/
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
    select: false
  },
  phone: {
    type: String,
    trim: true
  },
  role: {
    type: String,
    enum: ['customer', 'supplier', 'admin'],
    default: 'customer',
    required: true
  },
  profileImage: {
    type: String,
    default: null
  },
  // Customer-specific fields
  wishlist: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product'
  }],
  // Supplier-specific fields
  businessName: {
    type: String,
    trim: true
  },
  businessDescription: {
    type: String
  },
  businessAddress: {
    type: String
  },
  businessLicense: {
    type: String
  },
  // Common fields
  addresses: [{
    label: {
      type: String,
      enum: ['home', 'work', 'other'],
      default: 'home'
    },
    fullName: {
      type: String,
      required: true
    },
    phone: {
      type: String,
      required: true
    },
    addressLine1: {
      type: String,
      required: true
    },
    addressLine2: String,
    city: {
      type: String,
      required: true
    },
    state: {
      type: String,
      required: true
    },
    postalCode: {
      type: String,
      required: true
    },
    country: {
      type: String,
      required: true,
      default: 'Nepal'
    },
    isDefault: {
      type: Boolean,
      default: false
    }
  }],
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  refreshToken: {
    type: String,
    select: false
  },
  // Password reset fields
  resetPasswordToken: {
    type: String,
    select: false
  },
  resetPasswordExpiry: {
    type: Date,
    select: false
  },
  // FCM tokens for push notifications
  fcmTokens: [{
    type: String,
    trim: true
  }],
  // Notification preferences
  notificationPreferences: {
    orderUpdates: {
      type: Boolean,
      default: true
    },
    promotions: {
      type: Boolean,
      default: true
    },
    messages: {
      type: Boolean,
      default: true
    },
    system: {
      type: Boolean,
      default: true
    },
    emailNotifications: {
      type: Boolean,
      default: true
    },
    pushNotifications: {
      type: Boolean,
      default: true
    }
  },
  // Language preference
  language: {
    type: String,
    enum: ['en', 'ne', 'hi'],
    default: 'en'
  },
  // Theme preference
  themeMode: {
    type: String,
    enum: ['light', 'dark', 'system'],
    default: 'system'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}
```

### Indexes
```javascript
// Performance indexes
{
  email: 1
}, {
  unique: true
}

{
  role: 1
}

{
  isActive: 1
}

{
  createdAt: -1
}
```

## 🔐 Security Requirements

### Authentication & Authorization
1. **JWT Authentication**: All API endpoints require valid JWT tokens
2. **Role-Based Access**: Different profile fields accessible based on user role
3. **Token Expiration**: Access tokens expire after 24 hours, refresh tokens after 7 days
4. **Secure Storage**: Tokens stored securely using Flutter's Secure Storage

### Data Protection
1. **Password Hashing**: BCrypt with cost factor 12 for password storage
2. **Sensitive Data**: Passwords and tokens excluded from API responses by default
3. **HTTPS**: All API communication over HTTPS with TLS 1.2+
4. **CORS**: Restricted to approved domains only

### Input Validation
1. **Server-Side Validation**: All profile updates validated on server
2. **Field Length Limits**: Reasonable limits on all text fields
3. **Content Type Validation**: Proper MIME type checking for image uploads
4. **Rate Limiting**: 100 requests per minute per user for profile endpoints

### API Security
1. **CSRF Protection**: Anti-CSRF tokens for state-changing operations
2. **CORS Headers**: Restrictive CORS policy
3. **Content Security**: Proper Content-Security-Policy headers
4. **Request Size Limits**: 10MB max for profile image uploads

## 📊 Performance Requirements

### API Performance
1. **Response Time**: < 500ms for 95% of profile requests
2. **Concurrent Users**: Support 10,000 concurrent profile operations
3. **Caching**: Profile data cached for 5 minutes
4. **Database Optimization**: Proper indexing on frequently queried fields

### Mobile Performance
1. **Offline Support**: Profile data available offline with cache
2. **Image Optimization**: Profile images compressed and cached
3. **Memory Management**: Efficient state management for profile data
4. **Background Sync**: Theme preferences synced in background

## 🔄 Integration Requirements

### Frontend Integration
1. **State Management**: Provider pattern for profile state
2. **Error Handling**: Graceful error handling for API failures
3. **Loading States**: Proper loading indicators during operations
4. **Form Validation**: Client-side validation before API calls

### Backend Integration
1. **Database Connection**: MongoDB with proper connection pooling
2. **File Storage**: Profile images stored with CDN integration
3. **Email Service**: Integration with email service for notifications
4. **Push Notifications**: FCM integration for mobile notifications

## 🧪 Testing Requirements

### Unit Testing
1. **Model Validation**: Test all user model validations
2. **Controller Logic**: Test all controller methods
3. **Service Methods**: Test storage and API services
4. **Provider Logic**: Test theme and notification providers

### Integration Testing
1. **API Endpoints**: Test all profile-related endpoints
2. **Database Operations**: Test CRUD operations
3. **Authentication Flow**: Test JWT authentication
4. **File Upload**: Test profile image upload

### UI Testing
1. **Profile Screens**: Test all profile UI components
2. **Form Validation**: Test all form validations
3. **Navigation Flow**: Test screen navigation
4. **Theme Switching**: Test theme persistence

## 📁 Deployment Requirements

### Environment Variables
```
JWT_SECRET=complex_random_string_64_chars
JWT_EXPIRE=24h
JWT_REFRESH_EXPIRE=7d
MONGODB_URI=mongodb://localhost:27017/indulink
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10mb
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,webp
```

### Server Requirements
1. **Node.js**: Version 16+
2. **MongoDB**: Version 5.0+
3. **Storage**: 50GB for profile images
4. **Memory**: 4GB minimum for production

## 📈 Monitoring Requirements

### Metrics to Track
1. **API Response Times**: Monitor profile endpoint performance
2. **Error Rates**: Track failed profile operations
3. **User Activity**: Monitor profile update frequency
4. **Storage Usage**: Track profile image storage growth

### Alerting
1. **Error Thresholds**: Alert on >5% error rate
2. **Response Time**: Alert on >1s average response time
3. **Storage Limits**: Alert at 80% storage capacity
4. **Authentication Failures**: Alert on unusual auth patterns

## 📝 Implementation Checklist

### Backend Implementation
- [ ] User model with all required fields
- [ ] Profile controller with all endpoints
- [ ] Authentication middleware
- [ ] Input validation and sanitization
- [ ] Database indexes for performance
- [ ] File upload handling
- [ ] Error handling and logging
- [ ] Rate limiting configuration

### Frontend Implementation
- [ ] Profile screens for both user types
- [ ] Edit profile screens
- [ ] Settings screens with all options
- [ ] Theme provider with persistence
- [ ] Notification provider
- [ ] Auth provider integration
- [ ] Form validation
- [ ] Error handling UI
- [ ] Loading states

### Testing Implementation
- [ ] Unit tests for all providers
- [ ] Unit tests for all services
- [ ] Integration tests for API endpoints
- [ ] UI tests for profile screens
- [ ] End-to-end testing scenarios
- [ ] Performance testing
- [ ] Security testing

## 🎯 Key Performance Indicators

1. **Profile Load Time**: < 1.5s for complete profile data
2. **Update Success Rate**: >99.9% successful profile updates
3. **User Satisfaction**: >4.5/5 for profile management features
4. **Feature Adoption**: >80% of users customize their profile

## 📚 Documentation Requirements

1. **API Documentation**: Swagger/OpenAPI specs for all endpoints
2. **Developer Guide**: Integration guide for frontend developers
3. **Admin Guide**: Profile management guide for administrators
4. **User Guide**: Help documentation for end users

## 🔮 Future Enhancements

1. **Profile Verification**: Business verification for suppliers
2. **Social Integration**: Connect social media profiles
3. **Activity Analytics**: Profile engagement metrics
4. **Multi-Factor Authentication**: Enhanced security options
5. **Profile Export/Import**: Data portability features

This technical specification provides a complete blueprint for implementing the INDULINK profile management system with all necessary details for development, testing, and deployment.