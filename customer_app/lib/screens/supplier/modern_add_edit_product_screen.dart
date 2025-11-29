import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Modern Supplier Add/Edit Product Screen
class ModernAddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId; // null for add, productId for edit

  const ModernAddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<ModernAddEditProductScreen> createState() =>
      _ModernAddEditProductScreenState();
}

class _ModernAddEditProductScreenState
    extends ConsumerState<ModernAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();

  String _selectedCategory = '';
  bool _isFeatured = false;
  bool _isActive = true;
  final List<String> _imageUrls = [];
  bool _isLoading = false;

  final _categories = [
    'Building Materials',
    'Cement & Concrete',
    'Steel & Iron',
    'Bricks & Blocks',
    'Wood & Timber',
    'Paints & Coatings',
    'Tools & Equipment',
    'Electrical',
  ];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.productId != null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: AppConstants.paddingAll20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Product' : 'Add New Product',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isEdit
                              ? 'Update product information'
                              : 'Create a new product listing',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverPadding(
            padding: AppConstants.paddingAll20,
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Images Section
                    const SectionHeader(
                      title: 'Product Images',
                      icon: Icons.image,
                    ),
                    const SizedBox(height: 12),
                    _buildImageUploadSection(isDark),
                    const SizedBox(height: 24),

                    // Basic Information
                    const SectionHeader(
                      title: 'Basic Information',
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _titleController,
                      label: 'Product Title',
                      hint: 'Enter product name',
                      icon: Icons.title,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Describe your product',
                      icon: Icons.description,
                      maxLines: 4,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(isDark),
                    const SizedBox(height: 24),

                    // Pricing
                    const SectionHeader(
                      title: 'Pricing',
                      icon: Icons.local_offer,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: _priceController,
                            label: 'Price',
                            hint: '0.00',
                            icon: Icons.currency_rupee,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Price is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernTextField(
                            controller: _compareAtPriceController,
                            label: 'Compare Price',
                            hint: '0.00',
                            icon: Icons.compare_arrows,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Inventory
                    const SectionHeader(
                      title: 'Inventory',
                      icon: Icons.inventory,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: _stockController,
                            label: 'Stock Quantity',
                            hint: '0',
                            icon: Icons.storage,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Stock is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernTextField(
                            controller: _skuController,
                            label: 'SKU',
                            hint: 'PROD-001',
                            icon: Icons.qr_code,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (value.trim().length < 3) {
                                  return 'SKU must be at least 3 characters';
                                }

                                if (value.trim().length > 20) {
                                  return 'SKU must be less than 20 characters';
                                }

                                // Check for valid SKU format (alphanumeric, hyphens, underscores)
                                final skuRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
                                if (!skuRegex.hasMatch(value.trim())) {
                                  return 'SKU can only contain letters, numbers, hyphens, and underscores';
                                }
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Settings
                    const SectionHeader(
                      title: 'Settings',
                      icon: Icons.settings,
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      'Featured Product',
                      'Show this product in featured section',
                      _isFeatured,
                      (value) => setState(() => _isFeatured = value),
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      'Active',
                      'Product is visible to customers',
                      _isActive,
                      (value) => setState(() => _isActive = value),
                      isDark,
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AnimatedButton(
                            text: isEdit ? 'Update Product' : 'Add Product',
                            icon: isEdit ? Icons.check : Icons.add,
                            onPressed: _saveProduct,
                            gradient: AppColors.primaryGradient,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection(bool isDark) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // Upload Button
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                borderRadius: AppConstants.borderRadiusMedium,
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add Image',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Image Previews
          Expanded(
            child: _imageUrls.isEmpty
                ? const Center(
                    child: Text(
                      'No images added',
                      style: TextStyle(color: AppColors.lightTextSecondary),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: AppConstants.borderRadiusMedium,
                          image: DecorationImage(
                            image: NetworkImage(_imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _imageUrls.removeAt(index));
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        border: const OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMedium,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category, color: AppColors.primaryBlue),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMedium,
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategory = value ?? '');
      },
      validator: (value) => value == null ? 'Category is required' : null,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // In production, upload to storage and get URL
      setState(() {
        _imageUrls.add(image.path); // Replace with actual URL after upload
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.productId != null
              ? 'Product updated successfully'
              : 'Product added successfully'),
        ),
      );
      Navigator.pop(context);
    }
  }
}
