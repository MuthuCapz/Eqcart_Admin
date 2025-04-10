import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_product_edit_dialog.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String validCollection;

  const ProductCard({
    Key? key,
    required this.product,
    required this.validCollection,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool showVariants = false;

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (_) => EditProductDialog(
        product: widget.product,
        validCollection: widget.validCollection,
      ),
    );
  }

  void _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Product"),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this product? This action cannot be undone.",
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Delete", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(widget.validCollection)
          .doc(widget.product['shop_id'])
          .collection(widget.product['category'])
          .doc(widget.product['sku_id'])
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product['variants'] as List<dynamic>?;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product['image_url'] ?? '',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['product_name'] ?? '',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(product['description'] ?? '',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[700])),
                    SizedBox(height: 4),
                    Text(
                        "₹${product['product_price']} / ${product['product_weight']}",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              // Right-aligned meta + menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 4),
                  Text("SKU: ${product['sku_id']}",
                      style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Text("Stock: ${product['stock']}",
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                  SizedBox(height: 4),
                  Text("Disc: ${product['discount']}%",
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ],
          ),

          // Variants Toggle
          if (variants != null && variants.isNotEmpty) ...[
            Divider(height: 24),
            GestureDetector(
              onTap: () => setState(() => showVariants = !showVariants),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Variants",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Icon(showVariants ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ],

          // Variants Details
          if (showVariants)
            Column(
              children: variants!.map((variant) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "Vol: ${variant['volume']} | Stock: ${variant['stock']}",
                          style: TextStyle(fontSize: 13)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${variant['price']}",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("MRP: ₹${variant['mrp']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              )),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: _showEditDialog,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteProduct,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
