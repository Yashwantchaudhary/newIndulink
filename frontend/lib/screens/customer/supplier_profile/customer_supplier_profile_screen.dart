import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';

/// 👥 Customer Supplier Profile View Screen
/// Shows public supplier information to customers
class CustomerSupplierProfileScreen extends StatefulWidget {
  final String supplierId;

  const CustomerSupplierProfileScreen({
    super.key,
    required this.supplierId,
  });

  @override
  State<CustomerSupplierProfileScreen> createState() =>
      _CustomerSupplierProfileScreenState();
}

class _CustomerSupplierProfileScreenState
    extends State<CustomerSupplierProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _supplierData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSupplierProfile();
  }

  Future<void> _loadSupplierProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement API call to fetch supplier public profile
      // For now, simulate loading
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - replace with actual API call
      setState(() {
        _supplierData = {
          'businessName': 'ABC Building Materials',
          'contactPerson': 'John Smith',
          'email': 'contact@abcbuilding.com',
          'phone': '+977 9800000000',
          'businessDescription': 'Leading supplier of construction materials with over 10 years of experience. We provide high-quality cement, steel, bricks, and other building materials.',
          'established': '2015',
          'totalProducts': 150,
          'rating': 4.5,
          'totalReviews': 89,
          'address': 'Kathmandu, Nepal',
          'specialties': ['Cement', 'Steel', 'Bricks', 'Sand'],
          'certifications': ['ISO 9001', 'Quality Certified'],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load supplier profile';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: LoadingSpinner())
          : _errorMessage != null
              ? ErrorStateWidget(
                  message: _errorMessage!,
                  onRetry: _loadSupplierProfile,
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final supplier = _supplierData!;
    final businessName = supplier['businessName'] as String;
    final rating = supplier['rating'] as double? ?? 0.0;

    return CustomScrollView(
      slivers: [
        // Header with business info
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Business Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        businessName[0].toUpperCase(),
                        style: AppTypography.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Business Name
                    Text(
                      businessName,
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} (${supplier['totalReviews']} reviews)',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Description
              _buildSectionCard(
                'About',
                Text(
                  supplier['businessDescription'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),

              // Contact Information
              _buildSectionCard(
                'Contact Information',
                Column(
                  children: [
                    _buildContactRow(
                      Icons.person,
                      'Contact Person',
                      supplier['contactPerson'] as String,
                    ),
                    const Divider(height: 16),
                    _buildContactRow(
                      Icons.email,
                      'Email',
                      supplier['email'] as String,
                    ),
                    const Divider(height: 16),
                    _buildContactRow(
                      Icons.phone,
                      'Phone',
                      supplier['phone'] as String,
                    ),
                    const Divider(height: 16),
                    _buildContactRow(
                      Icons.location_on,
                      'Address',
                      supplier['address'] as String,
                    ),
                  ],
                ),
              ),

              // Business Details
              _buildSectionCard(
                'Business Details',
                Column(
                  children: [
                    _buildDetailRow(
                      'Established',
                      supplier['established'] as String,
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Total Products',
                      '${supplier['totalProducts']} products',
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Specialties',
                      (supplier['specialties'] as List<dynamic>).join(', '),
                    ),
                  ],
                ),
              ),

              // Certifications
              if (supplier['certifications'] != null)
                _buildSectionCard(
                  'Certifications',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (supplier['certifications'] as List<dynamic>)
                        .map<Widget>((cert) => Chip(
                              label: Text(cert as String),
                              backgroundColor: AppColors.primaryLightest,
                              labelStyle: TextStyle(color: AppColors.primary),
                            ))
                        .toList(),
                  ),
                ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to supplier's products
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('View Products - Coming Soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.inventory),
                        label: const Text('View Products'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Start chat with supplier
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact Supplier - Coming Soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Contact Supplier'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}