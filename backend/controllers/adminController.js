// controllers/adminController.js

const mongoose = require('mongoose');
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Category = require('../models/Category');

const MAX_LIMIT = 100;

// -------------------- Helpers --------------------

const respond = (res, data = {}, message = 'OK', status = 200) =>
  res.status(status).json({ success: status < 400, message, data });

const isValidId = (id) => mongoose.Types.ObjectId.isValid(String(id));

const parsePageLimit = (page = 1, limit = 20) => {
  const p = Math.max(parseInt(page, 10) || 1, 1);
  let l = Math.max(parseInt(limit, 10) || 20, 1);
  l = Math.min(l, MAX_LIMIT);
  const skip = (p - 1) * l;
  return { page: p, limit: l, skip };
};

const ensureAdmin = (req, res) => {
  if (!req.user || req.user.role !== 'admin') {
    respond(res, {}, 'Admin role required', 403);
    return false;
  }
  return true;
};

// Whitelist for bulk product updates
const ALLOWED_BULK_PRODUCT_FIELDS = [
  'status',
  'isFeatured',
  'price',
  'stock',
  'category',
  'tags',
];

// -------------------- USER MANAGEMENT --------------------

/**
 * GET /api/admin/users
 * Admin only
 */
exports.getAllUsers = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const {
      page = 1,
      limit = 20,
      role,
      isActive,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const { page: p, limit: l, skip } = parsePageLimit(page, limit);
    const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const filter = {};
    if (role) filter.role = role;
    if (isActive !== undefined) filter.isActive = String(isActive) === 'true';
    if (search) {
      const q = search.trim();
      filter.$or = [
        { firstName: { $regex: q, $options: 'i' } },
        { lastName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
        { businessName: { $regex: q, $options: 'i' } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('-password -refreshToken')
        .sort(sortOptions)
        .limit(l)
        .skip(skip)
        .lean(),
      User.countDocuments(filter),
    ]);

    respond(res, {
      data: users,
      pagination: {
        total,
        page: p,
        limit: l,
        pages: Math.ceil(total / l),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/users/:id
 */
exports.getUserDetails = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid user ID', 400);

    const user = await User.findById(id).select('-password -refreshToken').lean();
    if (!user) return respond(res, {}, 'User not found', 404);

    const [orderCount, totalSpentAgg] = await Promise.all([
      Order.countDocuments({ customer: id }),
      Order.aggregate([
        { $match: { customer: mongoose.Types.ObjectId(id), status: 'delivered' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
    ]);

    const totalSpent = totalSpentAgg[0]?.total || 0;

    respond(res, {
      data: {
        ...user,
        stats: { orderCount, totalSpent },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/users
 */
exports.createUser = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const {
      firstName,
      lastName,
      email,
      password,
      phone,
      role = 'customer',
      businessName,
      businessDescription,
    } = req.body;

    if (!email || !password) return respond(res, {}, 'Email and password are required', 400);

    const existing = await User.findOne({ email });
    if (existing) return respond(res, {}, 'User with this email already exists', 400);

    const userData = {
      firstName,
      lastName,
      email,
      password,
      phone,
      role,
      isActive: true,
    };

    if (role === 'supplier' && businessName) {
      userData.businessName = businessName;
      userData.businessDescription = businessDescription;
    }

    const user = await User.create(userData);
    const safeUser = await User.findById(user._id).select('-password -refreshToken').lean();

    respond(res, { data: safeUser }, 'User created successfully', 201);
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/users/:id
 */
exports.updateUser = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid user ID', 400);

    const allowed = [
      'firstName',
      'lastName',
      'phone',
      'role',
      'isActive',
      'businessName',
      'businessDescription',
    ];

    const updateData = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updateData[key] = req.body[key];
    }

    const user = await User.findByIdAndUpdate(id, updateData, { new: true, runValidators: true })
      .select('-password -refreshToken');

    if (!user) return respond(res, {}, 'User not found', 404);

    respond(res, { data: user }, 'User updated successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/admin/users/:id  (soft delete)
 */
exports.deleteUser = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid user ID', 400);

    const user = await User.findByIdAndUpdate(id, { isActive: false }, { new: true }).select('-password -refreshToken');
    if (!user) return respond(res, {}, 'User not found', 404);

    respond(res, { data: user }, 'User deactivated successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/users/:id/toggle-status
 */
exports.toggleUserStatus = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid user ID', 400);

    const user = await User.findById(id).select('-password -refreshToken');
    if (!user) return respond(res, {}, 'User not found', 404);

    user.isActive = !user.isActive;
    await user.save();

    respond(res, { data: user }, `User ${user.isActive ? 'activated' : 'deactivated'} successfully`);
  } catch (error) {
    next(error);
  }
};

// -------------------- PRODUCT MANAGEMENT --------------------

/**
 * GET /api/admin/products
 */
exports.getAllProducts = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const {
      page = 1,
      limit = 20,
      category,
      supplier,
      status,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const { page: p, limit: l, skip } = parsePageLimit(page, limit);
    const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const filter = {};
    if (category && isValidId(category)) filter.category = category;
    if (supplier && isValidId(supplier)) filter.supplier = supplier;
    if (status) filter.status = status;
    if (search) {
      const q = search.trim();
      filter.$or = [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { sku: { $regex: q, $options: 'i' } },
      ];
    }

    const [products, total] = await Promise.all([
      Product.find(filter)
        .populate('supplier', 'firstName lastName businessName email')
        .populate('category', 'name')
        .sort(sortOptions)
        .limit(l)
        .skip(skip)
        .lean(),
      Product.countDocuments(filter),
    ]);

    respond(res, {
      data: products,
      pagination: { total, page: p, limit: l, pages: Math.ceil(total / l) },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/products/:id/approve
 */
exports.approveProduct = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid product ID', 400);

    const product = await Product.findByIdAndUpdate(id, { status: 'active' }, { new: true })
      .populate('supplier', 'firstName lastName businessName');

    if (!product) return respond(res, {}, 'Product not found', 404);

    respond(res, { data: product }, 'Product approved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/products/:id/feature
 */
exports.featureProduct = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    const { isFeatured } = req.body;

    if (typeof isFeatured !== 'boolean') return respond(res, {}, 'isFeatured must be boolean', 400);
    if (!isValidId(id)) return respond(res, {}, 'Invalid product ID', 400);

    const product = await Product.findByIdAndUpdate(id, { isFeatured }, { new: true })
      .populate('supplier', 'firstName lastName businessName');

    if (!product) return respond(res, {}, 'Product not found', 404);

    respond(res, { data: product }, `Product ${isFeatured ? 'featured' : 'unfeatured'} successfully`);
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/products/bulk-update
 */
exports.bulkProductUpdate = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { productIds, updates } = req.body;
    if (!Array.isArray(productIds) || productIds.length === 0) {
      return respond(res, {}, 'Product IDs array is required', 400);
    }
    if (!updates || typeof updates !== 'object') {
      return respond(res, {}, 'Updates object is required', 400);
    }

    const invalid = productIds.some((id) => !isValidId(id));
    if (invalid) return respond(res, {}, 'One or more product IDs are invalid', 400);

    const safeUpdates = {};
    for (const key of Object.keys(updates)) {
      if (ALLOWED_BULK_PRODUCT_FIELDS.includes(key)) safeUpdates[key] = updates[key];
    }

    if (Object.keys(safeUpdates).length === 0) {
      return respond(res, {}, 'No allowed fields provided for update', 400);
    }

    const result = await Product.updateMany({ _id: { $in: productIds } }, { $set: safeUpdates }, { runValidators: true });

    respond(res, {
      data: {
        matchedCount: result.matchedCount ?? result.n ?? 0,
        modifiedCount: result.modifiedCount ?? result.nModified ?? 0,
      },
    }, 'Products updated successfully');
  } catch (error) {
    next(error);
  }
};

// -------------------- ORDER MANAGEMENT --------------------

/**
 * GET /api/admin/orders
 */
exports.getAllOrders = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const {
      page = 1,
      limit = 20,
      status,
      search,
      startDate,
      endDate,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const { page: p, limit: l, skip } = parsePageLimit(page, limit);
    const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const filter = {};
    if (status) filter.status = status;
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) {
        const d = new Date(endDate);
        d.setHours(23, 59, 59, 999);
        filter.createdAt.$lte = d;
      }
    }
    if (search) filter.orderNumber = { $regex: search.trim(), $options: 'i' };

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('customer', 'firstName lastName email')
        .populate({ path: 'items.product', select: 'name images price' })
        .sort(sortOptions)
        .limit(l)
        .skip(skip)
        .lean(),
      Order.countDocuments(filter),
    ]);

    respond(res, {
      data: orders,
      pagination: { total, page: p, limit: l, pages: Math.ceil(total / l) },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/orders/analytics
 */
exports.getOrderAnalytics = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { startDate, endDate } = req.query;
    const dateFilter = {};
    if (startDate || endDate) {
      dateFilter.createdAt = {};
      if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
      if (endDate) {
        const d = new Date(endDate);
        d.setHours(23, 59, 59, 999);
        dateFilter.createdAt.$lte = d;
      }
    }

    const [
      totalOrders,
      ordersByStatus,
      totalRevenueAgg,
      avgOrderValueAgg,
    ] = await Promise.all([
      Order.countDocuments(dateFilter),
      Order.aggregate([
        { $match: dateFilter },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: { ...dateFilter, status: 'delivered' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      Order.aggregate([
        { $match: dateFilter },
        { $group: { _id: null, avg: { $avg: '$total' } } },
      ]),
    ]);

    respond(res, {
      data: {
        totalOrders,
        ordersByStatus,
        totalRevenue: totalRevenueAgg[0]?.total || 0,
        avgOrderValue: avgOrderValueAgg[0]?.avg || 0,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/orders/:id/status
 * Admin override for order status; always logs statusHistory
 */
exports.updateOrderStatus = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    const { status, note } = req.body;

    if (!isValidId(id)) return respond(res, {}, 'Invalid order ID', 400);
    if (!status) return respond(res, {}, 'Status is required', 400);

    const update = {
      status,
      $push: {
        statusHistory: {
          status,
          note: note || '',
          updatedBy: req.user._id,
          timestamp: new Date(),
        },
      },
    };

    const order = await Order.findByIdAndUpdate(id, update, { new: true }).populate('customer', 'firstName lastName email');

    if (!order) return respond(res, {}, 'Order not found', 404);

    respond(res, { data: order }, 'Order status updated successfully');
  } catch (error) {
    next(error);
  }
};

// -------------------- SUPPLIER MANAGEMENT --------------------

/**
 * GET /api/admin/suppliers
 * Returns suppliers with aggregated metrics (single aggregation where possible)
 */
exports.getAllSuppliers = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const {
      page = 1,
      limit = 20,
      isActive,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const { page: p, limit: l, skip } = parsePageLimit(page, limit);
    const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const userFilter = { role: 'supplier' };
    if (isActive !== undefined) userFilter.isActive = String(isActive) === 'true';
    if (search) {
      const q = search.trim();
      userFilter.$or = [
        { firstName: { $regex: q, $options: 'i' } },
        { lastName: { $regex: q, $options: 'i' } },
        { businessName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ];
    }

    const suppliers = await User.find(userFilter)
      .select('-password -refreshToken')
      .sort(sortOptions)
      .limit(l)
      .skip(skip)
      .lean();

    const supplierIds = suppliers.map((s) => mongoose.Types.ObjectId(s._id));

    // Aggregate order metrics for these suppliers
    const orderMetrics = await Order.aggregate([
      { $unwind: '$items' },
      { $match: { 'items.supplier': { $in: supplierIds }, status: 'delivered' } },
      {
        $group: {
          _id: '$items.supplier',
          orderCount: { $sum: 1 },
          totalRevenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
        },
      },
    ]);

    const productCounts = await Product.aggregate([
      { $match: { supplier: { $in: supplierIds } } },
      { $group: { _id: '$supplier', productCount: { $sum: 1 } } },
    ]);

    const orderMap = new Map(orderMetrics.map((m) => [String(m._id), m]));
    const productMap = new Map(productCounts.map((p) => [String(p._id), p.productCount]));

    const suppliersWithMetrics = suppliers.map((s) => {
      const idStr = String(s._id);
      const m = orderMap.get(idStr) || { orderCount: 0, totalRevenue: 0 };
      const productCount = productMap.get(idStr) || 0;
      return {
        ...s,
        metrics: {
          productCount,
          orderCount: m.orderCount || 0,
          totalRevenue: m.totalRevenue || 0,
        },
      };
    });

    const total = await User.countDocuments(userFilter);

    respond(res, {
      data: suppliersWithMetrics,
      pagination: { total, page: p, limit: l, pages: Math.ceil(total / l) },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/suppliers/:id/approve
 */
exports.approveSupplier = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid supplier ID', 400);

    const supplier = await User.findOneAndUpdate(
      { _id: id, role: 'supplier' },
      { isActive: true, isEmailVerified: true },
      { new: true }
    ).select('-password -refreshToken');

    if (!supplier) return respond(res, {}, 'Supplier not found', 404);

    respond(res, { data: supplier }, 'Supplier approved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/suppliers/:id/suspend
 */
exports.suspendSupplier = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const { id } = req.params;
    if (!isValidId(id)) return respond(res, {}, 'Invalid supplier ID', 400);

    const supplier = await User.findOneAndUpdate(
      { _id: id, role: 'supplier' },
      { isActive: false },
      { new: true }
    ).select('-password -refreshToken');

    if (!supplier) return respond(res, {}, 'Supplier not found', 404);

    respond(res, { data: supplier }, 'Supplier suspended successfully');
  } catch (error) {
    next(error);
  }
};

// -------------------- CATEGORY MANAGEMENT --------------------

/**
 * GET /api/admin/categories
 */
exports.getAllCategories = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const {
      page = 1,
      limit = 20,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const { page: p, limit: l, skip } = parsePageLimit(page, limit);
    const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const filter = {};
    if (search) {
      const q = search.trim();
      filter.$or = [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
      ];
    }

    const [categories, total] = await Promise.all([
      Category.find(filter)
        .sort(sortOptions)
        .limit(l)
        .skip(skip)
        .lean(),
      Category.countDocuments(filter),
    ]);

    respond(res, {
      data: categories,
      pagination: { total, page: p, limit: l, pages: Math.ceil(total / l) },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/stats
 */
exports.getSystemStats = async (req, res, next) => {
  try {
    if (!ensureAdmin(req, res)) return;

    // Import additional models
    const Review = require('../models/Review');
    const RFQ = require('../models/RFQ');
    const Message = require('../models/Message');
    const Notification = require('../models/Notification');

    const [
      totalUsers,
      totalProducts,
      totalOrders,
      totalCategories,
      totalReviews,
      totalRFQs,
      totalMessages,
      totalNotifications,
      totalRevenueAgg,
      usersByRole,
      recentUsers,
      totalSuppliers,
      totalCustomers,
    ] = await Promise.all([
      User.countDocuments({ isActive: true }),
      Product.countDocuments(),
      Order.countDocuments(),
      Category.countDocuments(),
      Review.countDocuments(),
      RFQ.countDocuments(),
      Message.countDocuments(),
      Notification.countDocuments(),
      Order.aggregate([
        { $match: { status: 'delivered' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]),
      User.find({ isActive: true }).select('firstName lastName email role createdAt').sort({ createdAt: -1 }).limit(10).lean(),
      User.countDocuments({ role: 'supplier', isActive: true }),
      User.countDocuments({ role: 'customer', isActive: true }),
    ]);

    // Calculate platform commission (10% of total revenue)
    const totalRevenue = totalRevenueAgg[0]?.total || 0;
    const platformCommission = totalRevenue * 0.1;

    respond(res, {
      data: {
        totalUsers,
        totalSuppliers,
        totalCustomers,
        totalProducts,
        totalOrders,
        totalCategories,
        totalReviews,
        totalRFQs,
        totalMessages,
        totalNotifications,
        totalRevenue,
        platformCommission,
        usersByRole,
        recentUsers,
      },
    });
  } catch (error) {
    next(error);
  }
};
