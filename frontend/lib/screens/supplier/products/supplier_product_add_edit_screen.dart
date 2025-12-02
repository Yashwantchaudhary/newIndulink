import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/multi_image_upload_widget.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';
import '../../../services/api_service.dart';
import '../../../services/product_service.dart';
import '../../../services/image_service.dart';
import '../../../routes/navigation_service.dart';

/// ✏️ Supplier Product Add/Edit Screen
/// Comprehensive form for creating/editing products
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
  final ApiService _apiService = ApiService();
  final ProductService _productService = ProductService();
  final ImageService _imageService = ImageService();

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
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  late final MultiImageUploadWidget _imageUploadWidget;

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
      }
    } catch (e) {
      // Handle error silently or show message
    } finally {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
        });
      }
    }
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

  void _onImagesSelected(List<File> images) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images first if any new images selected
      List<String> imageUrls = List.from(_uploadedImageUrls);
      if (_selectedImages.isNotEmpty) {
        final uploadedUrls = await _imageService.uploadMultipleImagesToBackend(
          _selectedImages,
          folder: 'products',
        );
        imageUrls.addAll(uploadedUrls);
      }

      final productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'compareAtPrice': _compareAtPriceController.text.isNotEmpty
            ? double.parse(_compareAtPriceController.text)
            : null,
        'stock': int.parse(_stockController.text),
        'sku': _skuController.text.trim(),
        'category': _selectedCategoryId,
        'isFeatured': _isFeatured,
        'images': imageUrls,
      };

      // If editing, include product ID
      final isEdit = _isEditMode;
      final endpoint =
          isEdit ? '/api/products/${widget.product!.id}' : '/api/products';

      final response = isEdit
          ? await _apiService.put(endpoint, body: productData)
          : await _apiService.post(endpoint, body: productData);

      if (response.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Product updated successfully'
                : 'Product created successfully'),
          ),
        );
        NavigationService().pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to save product')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
          children: [
            // Product Images Section
            _buildSectionTitle('Product Images'),
            MultiImageUploadWidget(
              initialImages: _uploadedImageUrls,
              maxImages: 10,
              onImagesSelected: _onImagesSelected,
              onImagesUploaded: _onImagesUploaded,
              uploadFolder: 'products',
            ),
            const SizedBox(height: 24),

            // Basic Information
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title *',
                hintText: 'e.g., Portland Cement 50kg',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your product...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Pricing
            _buildSectionTitle('Pricing'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      hintText: '0.00',
                      prefixText: '₹ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _compareAtPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Compare Price (₹)',
                      hintText: '0.00',
                      prefixText: '₹ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Inventory
            _buildSectionTitle('Inventory'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity *',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
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
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      hintText: 'Optional',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category
            _buildSectionTitle('Category'),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Featured Toggle
            SwitchListTile(
              title: Text(
                'Featured Product',
                style: AppTypography.labelLarge,
              ),
              subtitle: Text(
                'Show this product in featured sections',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEditMode ? 'Update Product' : 'Create Product'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.h5.copyWith(
        fontWeight: AppTypography.bold,
      ),
    );
  }


  Widget _buildCategorySelector() {
    if (_isCategoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      decoration: const InputDecoration(
        labelText: 'Select Category *',
        hintText: 'Choose a category',
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.name),
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
}
