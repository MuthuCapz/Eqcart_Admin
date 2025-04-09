import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool showVariants = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product['variants'] as List<dynamic>?;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.network(
                  product['image_url'] ?? '',
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['product_name'] ?? '',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      product['description'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                        "₹${product['product_price']} / ${product['product_weight']}"),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("SKU: ${product['sku_id']}"),
                  Text("Stock: ${product['stock']}",
                      style: TextStyle(color: Colors.green)),
                  Text("Discount: ${product['discount']}%",
                      style: TextStyle(color: Colors.red)),
                ],
              )
            ],
          ),
          if (variants != null && variants.isNotEmpty)
            Column(
              children: [
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    setState(() => showVariants = !showVariants);
                  },
                  child: Row(
                    children: [
                      Text("Variants",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(showVariants
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
                if (showVariants)
                  Column(
                    children: variants.map((variant) {
                      return Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Volume: ${variant['volume']}"),
                                Text("Stock: ${variant['stock']}"),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Price: ₹${variant['price']}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  "MRP: ₹${variant['mrp']}",
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  )
              ],
            )
        ],
      ),
    );
  }
}
