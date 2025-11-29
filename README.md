# 🏗️ INDULINK - Premium Building Materials E-Commerce Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev/)
[![Material Design](https://img.shields.io/badge/Material%20Design-3-purple)](https://m3.material.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌟 Overview

**INDULINK** is a world-class, modern e-commerce mobile application designed specifically for building materials marketplace. The platform connects three distinct user types: **Customers**, **Suppliers**, and **Admins** in a seamless, premium shopping experience.

### ✨ Key Highlights

- 🎨 **World-Class UI/UX** - Inspired by Amazon & Flipkart with unique branding
- 🚀 **Material Design 3** - Latest Google design standards
- 💫 **Smooth Animations** - Premium micro-interactions throughout
- 🎯 **Role-Based Architecture** - Separate flows for each user type
- 🌓 **Dark Mode Ready** - Full theme switching support
- 📱 **Responsive Design** - Optimized for all screen sizes
- 🔐 **Secure Authentication** - JWT + Google Sign-In
- 🏪 **Complete E-Commerce** - From browsing to checkout

## 📱 Features by User Role

### 👥 Customer Features
- **Browse Products** - Grid and list views with filters
- **Product Details** - Image gallery, reviews, specifications
- **Shopping Cart** - Add to cart, quantity management
- **Wishlist** - Save favorite products
- **Orders** - Track order status and history
- **Search** - Advanced product search with filters
- **Reviews & Ratings** - View and submit product reviews
- **Profile Management** - Edit personal information
- **Address Management** - Multiple delivery addresses
- **Notifications** - Order updates and promotions

### 🏭 Supplier Features
- **Dashboard** - Sales analytics and insights
- **Product Management** - Add, edit, delete products
- **Inventory Control** - Stock management
- **Order Management** - Process incoming orders
- **Analytics** - Sales charts and product performance
- **Business Profile** - Manage business information

### 👨‍💼 Admin Features
- **Platform Dashboard** - Overall system overview
- **User Management** - Manage all users and roles
- **Product Moderation** - Approve/reject supplier products
- **Category Management** - Add/edit product categories
- **Order Monitoring** - View all platform orders
- **Analytics** - Platform-wide statistics

## 🎨 Design System

### Color Palette
- **Primary**: Industrial Blue (#1A73E8) - Trust & reliability
- **Secondary**: Vibrant Orange (#FF6F00) - Action & energy
- **Success**: Green (#00C853) - Positive confirmation
- **Warning**: Amber (#FFC107) - Alerts
- **Error**: Red (#D32F2F) - Errors

### Typography
- **Primary Font**: Inter - Headings & important text
- **Secondary Font**: Roboto - Body text
- **Monospace**: Roboto Mono - Prices & numbers

### Design Principles
1. **Glassmorphism** - Frosted glass effects
2. **Consistent Spacing** - 8px grid system
3. **Elevation & Shadows** - Proper depth hierarchy
4. **Micro-animations** - Smooth transitions
5. **Accessibility** - WCAG compliant

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Provider
- **UI Components**: Material Design 3
- **Fonts**: Google Fonts
- **Animations**: Flutter Animations API

### Backend Integration
- **API**: RESTful with Node.js + Express
- **Database**: MongoDB
- **Authentication**: JWT + Google OAuth
- **Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging
- **Analytics**: Firebase Analytics

### Dependencies
```yaml
# Core
flutter_sdk: 3.x
provider: ^6.1.1
google_fonts: ^6.1.0

# Authentication
firebase_core: ^4.1.0
firebase_auth: ^6.0.2
google_sign_in: ^7.2.0

# Networking
http: ^1.2.0

# Local Storage
shared_preferences: ^2.2.2

# UI Enhancement
cached_network_image: ^3.3.0
shimmer: ^3.0.0
carousel_slider: ^5.0.0
glassmorphism: ^3.0.0

# Additional
image_picker: ^1.0.4
fl_chart: ^1.1.1
```

## 📁 Project Structure

```
lib/
├──core/
│   ├── constants/
│   │   ├── app_colors.dart         # Color system
│   │   ├── app_typography.dart     # Typography styles
│   │   ├── app_dimensions.dart     # Spacing & sizing
│   │   └── app_config.dart         # API endpoints & config
│   ├── theme/
│   │   └── app_theme.dart          # Material theme config
│   ├── widgets/                     # Reusable widgets
│   ├── utils/                       # Utility functions
│   └── services/                    # Core services
│
├── models/
│   ├── user.dart                   # User model
│   ├── product.dart                # Product model
│   ├── cart.dart                   # Cart model
│   ├── order.dart                  # Order model
│   └── category.dart               # Category model
│
├── providers/                       # State management
│
├── services/
│   ├── api_service.dart            # HTTP client
│   ├── auth_service.dart           # Authentication
│   └── storage_service.dart        # Local storage
│
├── screens/
│   ├── splash/                     # Splash screen
│   ├── role_selection/             # Role selection
│   ├── auth/                       # Login/Signup
│   ├── customer/                   # Customer app
│   │   ├──home/
│   │   ├── products/
│   │   ├── cart/
│   │   ├── orders/
│   │   ├── profile/
│   │   └── wishlist/
│   ├── supplier/                   # Supplier app
│   │   ├── dashboard/
│   │   ├── products/
│   │   └── orders/
│   └── admin/                      # Admin app
│       └── dashboard/
│
├── routes/                         # Navigation
└── main.dart                       # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / VS Code
- Node.js (for backend)
- MongoDB

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/indulink.git
cd indulink
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Create a Firebase project
   - Add Android/iOS apps
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in respective folders

4. **Configure Backend**
   - Update API base URL in `lib/core/constants/app_config.dart`
   - Set environment variables

5. **Run the app**
```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Run on Web
flutter run -d chrome

# Build APK
flutter build apk --release
```

## 🎯 Development Status

### ✅ Completed
- [x] Premium design system (Colors, Typography, Theme)
- [x] Data models (User, Product, Cart, Order, Category)
- [x] Authentication flow (Splash, Role Selection, Login, Signup)
- [x] Customer home screen with product cards
- [x] API configuration and endpoints
- [x] Theme switching (Light/Dark)

### 🚧 In Progress
- [ ] Complete customer screens (Product details, Cart, Checkout)
- [ ] Supplier dashboard and management
- [ ] Admin panel
- [ ] API integration with backend
- [ ] State management implementation
- [ ] Payment gateway integration

### 📋 Planned
- [ ] Push notifications
- [ ] Real-time order tracking
- [ ] Advanced search & filters
- [ ] Product reviews system
- [ ] RFQ (Request for Quotation)
- [ ] Multi-language support

## 🎨 Screenshots

### Authentication Flow
| Splash Screen | Role Selection | Login Screen |
|--------------|----------------|-------------|
| Premium animated splash | Beautiful role cards | Secure login form |

### Customer App
| Home Screen | Product Detail | Shopping Cart |
|-------------|---------------|---------------|
| Products & deals | Full details | Cart management |

## 🔧 Configuration

### API Configuration
Edit `lib/core/constants/app_config.dart`:
```dart
static const String devBaseUrl = 'http://localhost:5000/api';
static const String prodBaseUrl = 'https://your-api.com/api';
```

### Theme Configuration
Customize in `lib/core/constants/app_colors.dart`:
```dart
static const Color primary = Color(0xFF1A73E8);
static const Color secondary = Color(0xFFFF6F00);
```

## 📖 Documentation

- [Design System Guide](docs/DESIGN_SYSTEM.md)
- [API Integration](docs/API_INTEGRATION.md)
- [State Management](docs/STATE_MANAGEMENT.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- Design inspiration from Amazon, Flipkart, and Material Design
- Icons from Material Icons
- Fonts from Google Fonts

## 📞 Support

For support, email support@indulink.com or create an issue in this repository.

## 🗺️ Roadmap

### Version 1.0.0 (Current)
- Basic e-commerce functionality
- Three user roles
- Product browsing and search
- Shopping cart and checkout
- Order management

### Version 1.1.0
- Payment gateway integration
- Push notifications
- Advanced analytics
- Product recommendations

### Version 2.0.0
- Multi-vendor support
- Live chat
- AR product preview
- Voice search

---

**Built with ❤️ using Flutter**

*Last Updated: November 28, 2025*
