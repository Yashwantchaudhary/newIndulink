# 🧪 **FLUTTER NAVIGATION TESTING GUIDE**

## 🎯 **OBJECTIVE**
Test all Flutter routes to verify navigation works correctly and screens load without errors.

---

## 🚀 **PREPARATION**

### **Step 1: Start Backend Server**
```bash
cd backend
npm start
```
**Expected:** Server running on port 5000

### **Step 2: Start Flutter App**
```bash
cd frontend
flutter run --debug
```
**Expected:** App launches and shows splash screen

---

## 📋 **TESTING CHECKLIST**

### **✅ PHASE 1: BASIC NAVIGATION**

#### **1.1 Initial Routes (No Auth Required)**
- [ ] **Splash Screen** (`/`)
  - Should show app logo/branding
  - Auto-navigate after 2-3 seconds
- [ ] **Role Selection** (`/role-selection`)
  - Should show Customer/Supplier/Admin options
  - Buttons should be clickable
- [ ] **Login Screen** (`/login`)
  - Should show email/password fields
  - Should have "Forgot Password" link
- [ ] **Signup Screen** (`/signup`)
  - Should show registration form
  - Should have role selection

#### **1.2 Test Screen Access**
- [ ] **API Test Screen** (`/test-api`)
  - Should load the test interface
  - Should show API testing buttons

**Navigation Test:** Try accessing each route directly by typing the path

---

### **✅ PHASE 2: AUTHENTICATION FLOW**

#### **2.1 User Registration**
1. Go to `/signup`
2. Fill registration form:
   - First Name: Test
   - Last Name: User
   - Email: test@example.com
   - Password: password123
   - Role: Customer
3. Click "Sign Up"
4. **Expected:** Success message or auto-login

#### **2.2 User Login**
1. Go to `/login`
2. Enter credentials:
   - Email: test@example.com
   - Password: password123
3. Click "Login"
4. **Expected:** Navigate to customer home

#### **2.3 Test API Screen**
1. Navigate to `/test-api`
2. Click "Test GET Products"
3. **Expected:** ✅ SUCCESS message
4. Click "Test GET Categories"
5. **Expected:** ✅ SUCCESS message

---

### **✅ PHASE 3: CUSTOMER ROUTES (After Login)**

#### **3.1 Main Customer Screens**
- [ ] **Home** (`/customer/home`)
  - Should show products/categories
  - Should have navigation bar
- [ ] **Products** (`/customer/products`)
  - Should show product list
  - Should be scrollable
- [ ] **Categories** (`/customer/categories`)
  - Should show category grid/list
- [ ] **Search** (`/customer/search`)
  - Should have search input
- [ ] **Wishlist** (`/customer/wishlist`)
  - Should show saved products
- [ ] **Cart** (`/customer/cart`)
  - Should show cart items
- [ ] **Orders** (`/customer/orders`)
  - Should show order history
- [ ] **Profile** (`/customer/profile`)
  - Should show user info
- [ ] **Messages** (`/customer/messages`)
  - Should show conversations
- [ ] **Notifications** (`/customer/notifications`)
  - Should show notifications
- [ ] **Addresses** (`/customer/addresses`)
  - Should show saved addresses

#### **3.2 Parameter Passing Tests**
- [ ] **Product Detail**
  - Click product from list
  - Should navigate to `/customer/products/detail`
  - Should show product details
- [ ] **Order Detail**
  - Click order from list
  - Should navigate to `/customer/orders/detail`
  - Should show order details
- [ ] **Add Address**
  - Click "Add Address"
  - Should navigate to `/customer/addresses/add`
  - Should show address form

---

### **✅ PHASE 4: ROUTE GUARD TESTING**

#### **4.1 Test Unauthorized Access**
1. **Logout** (if logged in)
2. Try accessing `/customer/home` directly
3. **Expected:** Redirect to `/role-selection`
4. Try accessing `/admin/dashboard` directly
5. **Expected:** Redirect to `/role-selection`

#### **4.2 Test Role-Based Access**
1. Login as **Customer**
2. Try accessing `/supplier/dashboard`
3. **Expected:** Redirect or error message
4. Try accessing `/admin/users`
5. **Expected:** Redirect or error message

---

### **✅ PHASE 5: SUPPLIER ROUTES (If Available)**

#### **5.1 Supplier Registration/Login**
1. Register as Supplier role
2. Login with supplier account
3. **Expected:** Navigate to `/supplier/dashboard`

#### **5.2 Supplier Screens**
- [ ] **Dashboard** (`/supplier/dashboard`)
- [ ] **Products** (`/supplier/products`)
- [ ] **Orders** (`/supplier/orders`)
- [ ] **Profile** (`/supplier/profile`)
- [ ] **Analytics** (`/supplier/analytics`)

---

### **✅ PHASE 6: ADMIN ROUTES (If Available)**

#### **6.1 Admin Registration/Login**
1. Register as Admin role
2. Login with admin account
3. **Expected:** Navigate to `/admin/dashboard`

#### **6.2 Admin Screens**
- [ ] **Dashboard** (`/admin/dashboard`)
- [ ] **Users** (`/admin/users`)
- [ ] **Products** (`/admin/products`)
- [ ] **Categories** (`/admin/categories`)
- [ ] **Orders** (`/admin/orders`)

---

## 🚨 **ERROR CHECKING**

### **Common Issues to Watch For:**

#### **1. Black Screens**
- **Cause:** Screen not implemented or import error
- **Check:** Look for red error messages in console
- **Fix:** Verify screen file exists and is properly imported

#### **2. Route Not Found (404)**
- **Cause:** Route not defined in `app_router.dart`
- **Check:** Verify route exists in switch statement
- **Fix:** Add missing route case

#### **3. Parameter Errors**
- **Cause:** Missing required arguments
- **Check:** Console shows "arguments is null"
- **Fix:** Ensure calling code passes required parameters

#### **4. Authentication Errors**
- **Cause:** Route guard blocking access
- **Check:** Redirects to login/role selection
- **Fix:** Login with appropriate role or check guard logic

#### **5. API Errors**
- **Cause:** Backend not running or endpoint issues
- **Check:** Network errors in console
- **Fix:** Ensure backend server is running

---

## 📊 **TESTING RESULTS TEMPLATE**

### **Route Testing Results:**

| Route | Status | Notes |
|-------|--------|-------|
| `/` | ⏳ | |
| `/role-selection` | ⏳ | |
| `/login` | ⏳ | |
| `/signup` | ⏳ | |
| `/test-api` | ⏳ | |
| `/customer/home` | ⏳ | |
| `/customer/products` | ⏳ | |
| `/customer/categories` | ⏳ | |
| ... | ... | ... |

**Status Legend:**
- ✅ **Working** - Loads without errors
- ❌ **Broken** - Shows errors or doesn't load
- ⚠️ **Issues** - Works but has problems
- ⏳ **Not Tested** - Haven't tested yet

---

## 🛠️ **DEBUGGING TOOLS**

### **Flutter DevTools**
```bash
flutter run --debug
```
- Open DevTools in browser
- Check console for errors
- Use inspector to check UI

### **Console Logging**
- Look for red error messages
- Check network requests in Network tab
- Verify API calls are successful

### **Hot Reload**
- Make code changes
- Use `r` key to hot reload
- Test fixes immediately

---

## 🎯 **SUCCESS CRITERIA**

### **✅ All Routes Working When:**
- [ ] No red error screens
- [ ] All screens load within 2 seconds
- [ ] Navigation between screens works
- [ ] Route guards properly redirect
- [ ] Parameter passing works correctly
- [ ] API calls succeed (check test screen)
- [ ] No console errors

### **🚨 System Needs Fixes When:**
- [ ] Black screens appear
- [ ] "Route not found" errors
- [ ] Authentication redirects don't work
- [ ] Parameter passing fails
- [ ] API calls fail consistently

---

## 📞 **TROUBLESHOOTING**

### **If Route Doesn't Load:**
1. Check if screen file exists
2. Verify import in `app_router.dart`
3. Check for syntax errors in screen file
4. Look for missing dependencies

### **If Route Guard Fails:**
1. Check user authentication status
2. Verify user role matches route requirements
3. Check AuthProvider state
4. Test with different user roles

### **If Parameters Don't Work:**
1. Check calling code passes arguments
2. Verify parameter extraction in route
3. Check argument types match expectations
4. Look for null safety issues

---

## 🎉 **FINAL VERIFICATION**

**Navigation is fully working when:**
- ✅ All routes load without errors
- ✅ Authentication flow works
- ✅ Role-based access control works
- ✅ Parameter passing functions
- ✅ API integration successful
- ✅ No console errors

**Ready to test?** Follow this guide step by step and mark each route as you test it!