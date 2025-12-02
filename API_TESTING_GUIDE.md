# 🧪 **INDULINK API & NAVIGATION TESTING GUIDE**

## 📋 **OVERVIEW**
This guide provides comprehensive testing instructions for all API endpoints and navigation routes in the Indulink E-commerce system.

---

## 🚀 **QUICK START**

### **1. Start Backend Server**
```bash
cd backend
npm start
```
**Expected:** Server running on `http://localhost:5000`

### **2. Start Flutter App**
```bash
cd frontend
flutter run
```

### **3. Test Screen Access**
Navigate to `/test-api` in Flutter app for automated testing.

---

## 🔗 **API ENDPOINTS TESTING**

### **📊 HEALTH & INFO ENDPOINTS**

| Method | Endpoint | Expected Status | Test Command |
|--------|----------|-----------------|--------------|
| GET | `/health` | 200 | `curl http://localhost:5000/health` |
| GET | `/api` | 200 | `curl http://localhost:5000/api` |
| GET | `/api/metrics` | 200 | `curl http://localhost:5000/api/metrics` |
| GET | `/api/infrastructure` | 200 | `curl http://localhost:5000/api/infrastructure` |

**Expected Response:**
```json
{
  "success": true,
  "message": "Indulink E-commerce API",
  "version": "1.0.0"
}
```

---

### **🔐 AUTHENTICATION ENDPOINTS**

| Method | Endpoint | Auth Required | Test Data |
|--------|----------|---------------|-----------|
| POST | `/api/auth/login` | ❌ No | `{"email":"test@example.com","password":"password123"}` |
| POST | `/api/auth/register` | ❌ No | `{"firstName":"Test","lastName":"User","email":"test@example.com","password":"password123","role":"customer"}` |
| POST | `/api/auth/google` | ❌ No | Google OAuth token |
| GET | `/api/auth/logout` | ✅ Yes | - |
| POST | `/api/auth/forgot-password` | ❌ No | `{"email":"test@example.com"}` |

**Test Commands:**
```bash
# Register user
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","lastName":"User","email":"test@example.com","password":"password123","role":"customer"}'

# Login (get token)
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

### **📦 PRODUCTS ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/products` | ❌ No | Get all products (paginated) |
| GET | `/api/products/:id` | ❌ No | Get product details |
| GET | `/api/products/featured` | ❌ No | Get featured products |
| GET | `/api/products/search` | ❌ No | Search products |

**Test Commands:**
```bash
# Get products
curl "http://localhost:5000/api/products?page=1&limit=10"

# Search products
curl "http://localhost:5000/api/products/search?q=cement"

# Get featured products
curl "http://localhost:5000/api/products/featured?limit=5"
```

---

### **📂 CATEGORIES ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/categories` | ❌ No | Get all categories |
| GET | `/api/categories/:id/products` | ❌ No | Get products by category |

**Test Commands:**
```bash
# Get categories
curl http://localhost:5000/api/categories

# Get products by category
curl http://localhost:5000/api/categories/CATEGORY_ID/products
```

---

### **📍 ADDRESSES ENDPOINTS (NEW)**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/addresses` | ✅ Yes | Get user addresses |
| POST | `/api/addresses` | ✅ Yes | Add new address |
| PUT | `/api/addresses/:id` | ✅ Yes | Update address |
| DELETE | `/api/addresses/:id` | ✅ Yes | Delete address |
| PUT | `/api/addresses/:id/set-default` | ✅ Yes | Set default address |

**Test Commands (with Bearer token):**
```bash
# Get addresses
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:5000/api/addresses

# Add address
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "John Doe",
    "phoneNumber": "+9779800000000",
    "addressLine1": "123 Main St",
    "city": "Kathmandu",
    "state": "Bagmati",
    "zipCode": "44600",
    "isDefault": true
  }' \
  http://localhost:5000/api/addresses
```

---

### **🛒 CART ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/cart` | ✅ Yes | Get cart items |
| POST | `/api/cart/add` | ✅ Yes | Add item to cart |
| PUT | `/api/cart/update` | ✅ Yes | Update cart item |
| DELETE | `/api/cart/remove` | ✅ Yes | Remove from cart |
| DELETE | `/api/cart/clear` | ✅ Yes | Clear cart |

---

### **📦 ORDERS ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/orders` | ✅ Yes | Get user orders |
| POST | `/api/orders` | ✅ Yes | Create new order |
| GET | `/api/orders/:id` | ✅ Yes | Get order details |
| PUT | `/api/orders/:id/cancel` | ✅ Yes | Cancel order |

---

### **💬 MESSAGES ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/conversations` | ✅ Yes | Get user conversations |
| GET | `/api/conversations/:id/messages` | ✅ Yes | Get conversation messages |
| POST | `/api/conversations/:id/messages` | ✅ Yes | Send message |

---

### **🔔 NOTIFICATIONS ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/notifications` | ✅ Yes | Get notifications |
| PUT | `/api/notifications/:id/read` | ✅ Yes | Mark as read |
| PUT | `/api/notifications/read-all` | ✅ Yes | Mark all as read |

---

### **❤️ WISHLIST ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/wishlist` | ✅ Yes | Get wishlist |
| POST | `/api/wishlist/add` | ✅ Yes | Add to wishlist |
| DELETE | `/api/wishlist/remove` | ✅ Yes | Remove from wishlist |

---

### **📊 DASHBOARD ENDPOINTS**

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/api/dashboard` | ✅ Yes | Get dashboard data |
| GET | `/api/admin/dashboard` | ✅ Yes (Admin) | Admin dashboard |

---

## 🧭 **NAVIGATION ROUTES TESTING**

### **📱 FLUTTER NAVIGATION TESTING**

#### **Initial Routes (No Auth Required):**
- `/` → Splash Screen
- `/role-selection` → Role Selection
- `/login` → Login Screen
- `/signup` → Signup Screen
- `/forgot-password` → Forgot Password
- `/test-api` → **API Test Screen** ⭐

#### **Customer Routes (Customer Auth Required):**
- `/customer/home` → Customer Home
- `/customer/products` → Product List
- `/customer/products/detail` → Product Detail (needs productId)
- `/customer/categories` → Categories
- `/customer/search` → Search
- `/customer/wishlist` → Wishlist
- `/customer/cart` → Cart
- `/customer/checkout` → Checkout
- `/customer/orders` → Orders
- `/customer/profile` → Profile
- `/customer/addresses` → Addresses
- `/customer/messages` → Messages
- `/customer/notifications` → Notifications

#### **Supplier Routes (Supplier Auth Required):**
- `/supplier/dashboard` → Supplier Dashboard
- `/supplier/products` → Supplier Products
- `/supplier/orders` → Supplier Orders
- `/supplier/profile` → Supplier Profile
- `/supplier/analytics` → Analytics

#### **Admin Routes (Admin Auth Required):**
- `/admin/dashboard` → Admin Dashboard
- `/admin/users` → Admin Users
- `/admin/products` → Admin Products ⭐
- `/admin/categories` → Admin Categories ⭐
- `/admin/orders` → Admin Orders ⭐

---

## 🧪 **AUTOMATED TESTING IN FLUTTER**

### **Test Screen Features (`/test-api`):**

1. **Test GET Products** → Verifies product fetching
2. **Test GET Categories** → Verifies category fetching
3. **Test POST Address** → Verifies address creation
4. **Test Raw API Call** → Verifies basic connectivity

### **Expected Test Results:**
```
✅ SUCCESS: Retrieved X products
✅ SUCCESS: Retrieved X categories
✅ SUCCESS: Address added successfully
✅ SUCCESS: Raw API Response - Status: 200
```

---

## 🔧 **MANUAL API TESTING WITH POSTMAN**

### **1. Create Environment:**
```
Base URL: http://localhost:5000
Auth Token: (from login response)
```

### **2. Test Collections:**

#### **Public Endpoints (No Auth):**
- GET Products
- GET Categories
- GET Health Check
- POST Register
- POST Login

#### **Protected Endpoints (Auth Required):**
- GET Addresses (after login)
- POST Add Address
- PUT Update Address
- DELETE Delete Address

---

## 🚨 **TROUBLESHOOTING**

### **Backend Issues:**
```bash
# Check server status
curl http://localhost:5000/health

# Check MongoDB connection
# Look for "MongoDB connected" in logs

# Check for errors
tail -f backend/logs/error.log
```

### **Flutter Issues:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run --debug

# Check for compilation errors
flutter analyze
```

### **Network Issues:**
- Backend on `localhost:5000`?
- Firewall blocking connections?
- Try `127.0.0.1:5000` instead of `localhost`

### **Authentication Issues:**
- Token expired? Login again
- Wrong token format? Should be `Bearer TOKEN`
- User role permissions?

---

## 📊 **TESTING CHECKLIST**

### **✅ Backend Tests:**
- [ ] Server starts successfully
- [ ] MongoDB connects
- [ ] Health endpoint returns 200
- [ ] API root returns version info

### **✅ Authentication Tests:**
- [ ] User registration works
- [ ] User login returns token
- [ ] Token authentication works

### **✅ Data Flow Tests:**
- [ ] GET products returns data
- [ ] GET categories returns data
- [ ] POST address creates record
- [ ] PUT address updates record
- [ ] DELETE address removes record

### **✅ Navigation Tests:**
- [ ] All routes accessible
- [ ] Route guards working
- [ ] Role-based access working
- [ ] Test screen loads

---

## 🎯 **SUCCESS CRITERIA**

### **✅ System Working When:**
1. Backend server runs without errors
2. MongoDB connection successful
3. All public API endpoints return 200
4. Authentication flow works
5. CRUD operations successful
6. Flutter app navigates properly
7. Test screen shows all ✅ SUCCESS messages

### **🚨 System Needs Fixing When:**
1. Server fails to start
2. API calls return 500 errors
3. Authentication fails
4. Database operations fail
5. Flutter compilation errors
6. Navigation broken

---

## 📞 **SUPPORT**

If tests fail:
1. Check server logs for errors
2. Verify MongoDB connection
3. Test individual endpoints with curl/Postman
4. Check Flutter debug console
5. Verify network connectivity

**Remember:** The `/test-api` screen in Flutter provides the quickest way to verify your complete data flow system! 🚀