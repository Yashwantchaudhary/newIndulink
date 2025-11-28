import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../config/app_constants.dart';
import '../../config/app_colors.dart';

class ProductCardGrid extends StatelessWidget {
  final List<Product>? products;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final VoidCallback? onTap;

  const ProductCardGrid({
    super.key,
    this.products,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
    this.spacing = 12.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productList = products ?? [];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: productList.length,
      itemBuilder: (context, index) {
        final product = productList[index];
        return Card(
          elevation: AppConstants.elevationLow,
          shape: const RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: AppColors.neutral400,
                    ),
                  ),
                ),
              ),

              // Product Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: AppConstants.paddingAll12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Price
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: 4),

                      // Rating (placeholder)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
