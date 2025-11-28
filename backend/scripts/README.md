# Database Seeding Scripts

This directory contains scripts and utilities for populating the InduLink ecommerce platform database with comprehensive sample data for testing and development purposes.

## Overview

The seeding system provides two ways to populate data:

1. **Command-line scripts** - Run directly from the terminal for development setup
2. **API endpoints** - RESTful endpoints for on-demand data population (admin-only)

## Files Structure

```
scripts/
├── sampleDataUtils.js    # Core data generation utilities
├── seedDatabase.js       # Main seeding script
├── seedingController.js  # API controller for seeding endpoints
├── seedingRoutes.js      # Express routes for seeding API
└── README.md            # This documentation
```

## Sample Data Generated

### Users
- **Admins**: 2 pre-configured admin users
  - `admin@indulink.com` / `password123`
  - `sysadmin@indulink.com` / `password123`
- **Customers**: 5 sample customers with addresses and preferences
- **Suppliers**: 3 sample suppliers with business information

### Categories
- **Main Categories**: 8 top-level categories (Electronics, Clothing, Home & Garden, etc.)
- **Subcategories**: 51 detailed subcategories with proper parent-child relationships

### Products
- **Total**: 20 diverse products across all categories
- **Features**: Realistic pricing, stock levels, images, descriptions, and specifications
- **Distribution**: Products are distributed across suppliers and categories

### Orders
- **Total**: 10 sample orders with various statuses
- **Statuses**: pending, confirmed, processing, shipped, out_for_delivery, delivered, cancelled
- **Features**: Multiple items per order, realistic pricing, shipping addresses

### Reviews
- **Total**: 11 verified customer reviews
- **Features**: Ratings (1-5 stars), titles, comments, verified purchase status
- **Uniqueness**: One review per customer per product

### Notifications
- **Total**: 20 sample notifications
- **Types**: order, promotion, message, system, review
- **Features**: Read/unread status, timestamps, relevant data payloads

## Command-Line Usage

### Full Database Seeding
```bash
cd backend
node scripts/seedDatabase.js
```

### Individual Data Type Seeding
```bash
# Seed only users
node scripts/seedDatabase.js users

# Seed only categories
node scripts/seedDatabase.js categories

# Seed only products
node scripts/seedDatabase.js products

# Seed only orders
node scripts/seedDatabase.js orders

# Seed only reviews
node scripts/seedDatabase.js reviews

# Seed only notifications
node scripts/seedDatabase.js notifications
```

## API Endpoints

All seeding endpoints require admin authentication and are available at `/api/seed/*`.

### Authentication
Include JWT token in Authorization header:
```
Authorization: Bearer <admin-jwt-token>
```

### Endpoints

#### Get Seeding Status
```http
GET /api/seed/status
```
Returns current database record counts.

#### Clear All Data
```http
DELETE /api/seed/clear
```
**⚠️ DANGER**: Removes all data from database.

#### Seed All Data
```http
POST /api/seed/all
```
Populates database with complete sample dataset.

#### Seed Individual Data Types
```http
POST /api/seed/users
POST /api/seed/categories
POST /api/seed/products
POST /api/seed/orders
POST /api/seed/reviews
POST /api/seed/notifications
```

### API Response Format
```json
{
  "success": true,
  "message": "Users seeded successfully",
  "data": {
    "total": 10,
    "admins": 2,
    "customers": 5,
    "suppliers": 3
  }
}
```

## Data Characteristics

### Realistic Scenarios
- **Geographic**: Nepal-based addresses and phone numbers
- **Pricing**: NPR currency with realistic price ranges
- **Business Logic**: Proper relationships between orders, products, and users
- **Validation**: All data passes model validation rules

### Testing Coverage
- **Order Statuses**: All possible order workflow states
- **User Roles**: Admin, customer, and supplier perspectives
- **Product Variety**: Different categories, price ranges, stock levels
- **Review Distribution**: Various ratings and feedback types

## Dependencies

- `@faker-js/faker`: For generating realistic sample data
- `mongoose`: For database operations
- `express`: For API endpoints

## Security Notes

- **Admin Only**: All seeding operations require admin role
- **Development Only**: Intended for development/testing environments
- **Data Loss**: Clear operations permanently delete data

## Troubleshooting

### Common Issues

1. **Duplicate Key Errors**: Ensure database is cleared before seeding
2. **Validation Errors**: Check model schemas for required fields
3. **Connection Issues**: Verify MongoDB connection string

### Database Connection
The scripts use the same database configuration as the main application (`process.env.MONGODB_URI`).

### Memory Usage
Large datasets may require increased Node.js memory limits:
```bash
node --max-old-space-size=4096 scripts/seedDatabase.js
```

## Customization

### Modifying Data Amounts
Edit the seeding script to adjust quantities:

```javascript
// In seedDatabase.js
const customers = SampleDataUtils.generateUsers(10, 'customer'); // Change numbers
const products = SampleDataUtils.generateProducts(categories, suppliers, 50);
```

### Adding New Data Types
1. Create generation method in `SampleDataUtils`
2. Add seeding method in `DatabaseSeeder` class
3. Add API endpoint in controller and routes
4. Update CLI argument handling

## Integration with Development Workflow

### Recommended Usage
1. **Initial Setup**: Run full seeding for development environment
2. **Feature Testing**: Use individual endpoints to add specific data types
3. **Clean Slate**: Use clear endpoint before major testing sessions

### CI/CD Integration
```bash
# In package.json scripts
"seed": "node scripts/seedDatabase.js",
"seed:test": "node scripts/seedDatabase.js --small",
"seed:clear": "node scripts/seedDatabase.js clear"
```

## Support

For issues with seeding scripts, check:
1. Database connectivity
2. Model validation rules
3. Data dependencies (e.g., categories before products)
4. Authentication for API endpoints