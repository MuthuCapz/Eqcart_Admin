import 'package:eqcart_admin/Banner/add_banner_page.dart';
import 'package:flutter/material.dart';
import '../../Category/category_page.dart';
import '../../Product/product_page.dart';
import '../../utils/colors.dart';

class OwnShopMainPage extends StatelessWidget {
  final String shopId;

  OwnShopMainPage({required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title:
            Text('Own Shop Main Page', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMenuButton(context, Icons.category, "Category",
                    AddCategoryPage(shopId: shopId)),
                _buildMenuButton(context, Icons.shopping_cart, "Product",
                    AddProductPage(shopId: shopId)),
              ],
            ),
            SizedBox(height: 16), // Space between rows

            _buildMenuButton(context, Icons.post_add, "Banner",
                AddBannerPage(shopId: shopId)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[350],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.primaryColor),
            SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
