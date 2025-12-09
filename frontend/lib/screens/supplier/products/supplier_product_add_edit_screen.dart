import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart'; // Added XFile
// import 'dart:io'; // Removed dart:io import to prevent web errors

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/multi_image_upload_widget.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';
import '../../../services/product_service.dart';

/// ✏️ Supplier Product Add/Edit Screen
/// Modern, comprehensive form for creating/editing products
class SupplierProductAddEditScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const SupplierProductAddEditScreen({super.key, this.product, this.productId});

  @override
  State<SupplierProductAddEditScreen> createState() =>
      _SupplierProductAddEditScreenState();
}

class _SupplierProductAddEditScreenState
    extends State<SupplierProductAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  bool get _isEditMode => widget.product != null;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();

  // Image management
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];

  final List<Category> _categories = [];
  String _selectedCategoryId = '';
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFormWithProduct();
    }
    _loadCategories();
  }

  void _populateFormWithProduct() {
    final product = widget.product!;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _compareAtPriceController.text = product.compareAtPrice?.toString() ?? '';
    _stockController.text = product.stock.toString();
    _skuController.text = product.sku ?? '';
    _selectedCategoryId = product.categoryId;
    _isFeatured = product.isFeatured;

    // Populate existing images
    _uploadedImageUrls.addAll(product.images.map((img) => img.url));
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoriesLoading = true;
    });

    try {
      final result = await _productService.getCategories();
      if (result.success && mounted) {
        setState(() {
          _categories.clear();
          _categories.addAll(result.categories);
        });
      } else if (mounted) {
        _showErrorSnackBar(result.message ?? 'Failed to load categories');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading categories: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  void _onImagesSelected(List<XFile> images) {
    setState(() {
      _selectedImages.clear();
      _selectedImages.addAll(images);
    });
  }

  void _onImagesUploaded(List<String> urls) {
    setState(() {
      _uploadedImageUrls.clear();
      _uploadedImageUrls.addAll(urls);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId.isEmpty) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productFields = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text,
        'stock': _stockController.text,
        'category': _selectedCategoryId,
        'isFeatured': _isFeatured.toString(),
      };

      if (_compareAtPriceController.text.isNotEmpty) {
        productFields['compareAtPrice'] = _compareAtPriceController.text;
      }

      if (_skuController.text.isNotEmpty) {
        productFields['sku'] = _skuController.text.trim();
      }

      ProductResult result;

      if (_isEditMode) {
        result = await _productService.updateProduct(
          widget.product!.id,
          productFields,
          _selectedImages,
        );
      } else {
        if (_selectedImages.isEmpty) {
          if (!mounted) {
            setState(() => _isLoading = false);
            return;
          }
          _showErrorSnackBar('Please select at least one image');
          setState(() => _isLoading = false);
          return;
        }
        result = await _productService.createProduct(
          productFields,
          _selectedImages,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.success) {
          _showSuccessSnackBar(_isEditMode
              ? 'Product updated successfully!'
              : 'Product created successfully!');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar(result.message ?? 'Failed to save product');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('❌ Product creation error: $e');
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _isEditMode
                ? 'Update your product details'
                : 'Create a new listing',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      actions: [
        if (!_isLoading)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saveProduct,
              icon: Icon(
                _isEditMode ? Icons.save : Icons.add_circle,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                _isEditMode ? 'Save' : 'Create',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isEditMode ? 'Updating Product...' : 'Creating Product...',
            style: AppTypography.h6.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we save your changes',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product Images Card
          _buildCard(
            icon: Icons.photo_library,
            title: 'Product Images',
            subtitle: 'Add up to 10 images',
            child: MultiImageUploadWidget(
              initialImages: _uploadedImageUrls,
              maxImages: 10,
              onImagesSelected: _onImagesSelected,
              onImagesUploaded: _onImagesUploaded,
              uploadFolder: 'products',
            ),
          ),
          const SizedBox(height: 16),

          // Basic Information Card
          _buildCard(
            icon: Icons.info_outline,
            title: 'Basic Information',
            subtitle: 'Product name and description',
            child: Column(
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Product Title',
                  hint: 'e.g., Portland Cement 50kg',
                  prefixIcon: Icons.inventory_2,
                  required: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter product title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your product in detail...',
                  prefixIcon: Icons.description,
                  maxLines: 4,
                  required: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter product description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pricing Card
          _buildCard(
            icon: Icons.attach_money,
            title: 'Pricing',
            subtitle: 'Set your product price',
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Price (₹)',
                    hint: '0.00',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    required: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _compareAtPriceController,
                    label: 'Compare Price',
                    hint: 'Original price',
                    prefixIcon: Icons.price_change,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inventory Card
          _buildCard(
            icon: Icons.warehouse,
            title: 'Inventory',
            subtitle: 'Stock and SKU details',
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: 'Stock Quantity',
                    hint: '0',
                    prefixIcon: Icons.inventory,
                    keyboardType: TextInputType.number,
                    required: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _skuController,
                    label: 'SKU (Optional)',
                    hint: 'Product SKU',
                    prefixIcon: Icons.qr_code,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Card
          _buildCard(
            icon: Icons.category,
            title: 'Category',
            subtitle: 'Select product category',
            child: _buildCategorySelector(),
          ),
          const SizedBox(height: 16),

          // Featured Toggle Card
          _buildCard(
            icon: Icons.star,
            title: 'Featured Status',
            subtitle: 'Highlight your product',
            child: Container(
              decoration: BoxDecoration(
                color: _isFeatured
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isFeatured ? AppColors.primary : AppColors.border,
                  width: _isFeatured ? 2 : 1,
                ),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Icon(
                      _isFeatured ? Icons.star : Icons.star_border,
                      color:
                          _isFeatured ? Colors.amber : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Featured Product',
                      style: AppTypography.labelLarge.copyWith(
                        color: _isFeatured
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            _isFeatured ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    _isFeatured
                        ? 'This product will be highlighted in featured sections'
                        : 'Enable to show in featured sections',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          _buildSubmitButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_isCategoriesLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No categories available. Please try again later.'),
            ),
            TextButton(
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final isValidSelection =
        _categories.any((c) => c.id == _selectedCategoryId);
    final dropdownValue = isValidSelection ? _selectedCategoryId : null;

    return DropdownButtonFormField<String>(
      value: dropdownValue,
      decoration: InputDecoration(
        labelText: 'Select Category *',
        hintText: 'Choose a category',
        prefixIcon: Icon(Icons.category, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.folder,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditMode ? Icons.save : Icons.add_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              _isEditMode ? 'Update Product' : 'Create Product',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
