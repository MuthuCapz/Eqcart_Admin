import 'package:flutter/material.dart';

import '../utils/colors.dart';

class ProductTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showVariants;
  final VoidCallback onToggleVariants;

  const ProductTile({
    super.key,
    required this.data,
    required this.showVariants,
    required this.onToggleVariants,
  });

  @override
  Widget build(BuildContext context) {
    final variants = data['variants'] ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.backgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Category
            Text(
              "Category: ${data['category_name']}",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            /// Product Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Image
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                    image: DecorationImage(
                      image: (data['image_url'] as String?)?.isNotEmpty == true
                          ? NetworkImage(data['image_url'])
                          : const AssetImage('assets/placeholder.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                /// Product Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['product_name'] ?? '',
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${data['product_price']} / ${data['product_weight']}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                /// Right Side Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('SKU: ${data['sku_id']}',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text('Stock: ${data['stock']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 6),
                    if ((data['discount'] ?? 0) > 0)
                      Text(
                        'Discount: ${data['discount']}%',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            /// Variants
            if (variants.isNotEmpty) ...[
              const Divider(height: 20, thickness: 1),
              InkWell(
                onTap: onToggleVariants,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Variants',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Icon(
                      showVariants
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (showVariants)
                Column(
                  children: List.generate(variants.length, (i) {
                    final variant = variants[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Left
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Volume: ${variant['volume']}',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              Text('Stock: ${variant['stock']}'),
                            ],
                          ),

                          /// Right
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Price: ₹${variant['price']}',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              Text('MRP: ₹${variant['mrp']}',
                                  style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.redAccent)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                )
            ]
          ],
        ),
      ),
    );
  }
}
