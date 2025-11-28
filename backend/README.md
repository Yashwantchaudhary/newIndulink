# Indulink Backend API

Production-ready Node.js REST API for Indulink E-commerce Platform.

## Features

- 🔐 JWT Authentication & Authorization
- 👥 Role-based Access Control (Customer/Supplier/Admin)
- 🛍️ Complete E-commerce Functionality
- 💬 Customer-Supplier Messaging
- 📊 Analytics & Dashboard
- 📸 Image Upload Support
- ⚡ Performance Optimized
- 🔒 Security Best Practices

## Tech Stack

- **Runtime:** Node.js v18+
- **Framework:** Express.js
- **Database:** MongoDB with Mongoose ODM
- **Authentication:** JWT (JSON Web Tokens)
- **File Upload:** Multer
- **Security:** Helmet, CORS, bcrypt
- **Validation:** express-validator

## Getting Started

### Prerequisites

- Node.js v18 or higher
- MongoDB (local or MongoDB Atlas)
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create environment file:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
```env
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://localhost:27017/indulink
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret-key
```

4. Start the server:

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

The API will be running at `http://localhost:5000`

## API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "+1234567890",
  "role": "customer"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

### Protected Routes

Include the JWT token in the Authorization header:
```http
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## Project Structure

```
backend/
├── config/
│   └── database.js          # Database connection
├── controllers/             # Request handlers
│   ├── authController.js
│   ├── userController.js
│   ├── productController.js
│   ├── categoryController.js
│   ├── cartController.js
│   ├── orderController.js
│   ├── reviewController.js
│   ├── messageController.js
│   └── dashboardController.js
├── middleware/              # Custom middleware
│   ├── authMiddleware.js    # JWT & authorization
│   ├── errorHandler.js      # Error handling
│   └── upload.js            # File upload
├── models/                  # Mongoose models
│   ├── User.js
│   ├── Product.js
│   ├── Category.js
│   ├── Cart.js
│   ├── Order.js
│   ├── Review.js
│   └── Message.js
├── routes/                  # API routes
│   ├── authRoutes.js
│   ├── userRoutes.js
│   ├── productRoutes.js
│   ├── categoryRoutes.js
│   ├── cartRoutes.js
│   ├── orderRoutes.js
│   ├── reviewRoutes.js
│   ├── messageRoutes.js
│   └── dashboardRoutes.js
├── uploads/                 # Uploaded files
├── .env.example             # Environment template
├── .gitignore
├── package.json
└── server.js                # App entry point
```

## Available Scripts

- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm test` - Run tests

## Database Seeding

The project includes comprehensive database seeding scripts for populating test data.

### Quick Start
```bash
# Full database seeding
node scripts/seedDatabase.js

# Individual data types
node scripts/seedDatabase.js users
node scripts/seedDatabase.js categories
node scripts/seedDatabase.js products
```

### API Endpoints (Admin Only)
```http
GET  /api/seed/status      # Check current data counts
POST /api/seed/all         # Seed all data
POST /api/seed/users       # Seed users only
POST /api/seed/categories  # Seed categories only
POST /api/seed/products    # Seed products only
DELETE /api/seed/clear     # Clear all data
```

### Sample Admin Credentials
- **Email:** `admin@indulink.com`
- **Password:** `password123`

For detailed documentation, see `scripts/README.md`.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment (development/production) | development |
| `PORT` | Server port | 5000 |
| `MONGODB_URI` | MongoDB connection string | - |
| `JWT_SECRET` | JWT secret key | - |
| `JWT_REFRESH_SECRET` | Refresh token secret | - |
| `JWT_EXPIRE` | Access token expiry | 24h |
| `JWT_REFRESH_EXPIRE` | Refresh token expiry | 7d |
| `UPLOAD_DIR` | Upload directory | uploads |
| `MAX_FILE_SIZE` | Max file size in bytes | 5242880 |

## Security Features

- Password hashing with bcrypt
- JWT token authentication
- Role-based access control
- Request rate limiting
- CORS configuration
- Helmet security headers
- Input validation and sanitization
- MongoDB injection prevention

## License

MIT
