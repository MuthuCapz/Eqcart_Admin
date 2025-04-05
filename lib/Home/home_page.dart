import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../Banner/add_banner_page.dart';
import '../Profile/profile_page.dart';
import '../Category/category_page.dart';
import '../Product/product_page.dart';
import '../Shops/add_new_shop/add_shop_page.dart';
import '../Shops/add_own_shop/add_own_shop_page.dart';
import '../Shops/view_own_shop/view_own_shop_page.dart';
import '../Shops/view_shop/view_shop_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: Stack(
          children: [
            Container(
              height: 90,
              color: AppColors.secondaryColor,
            ),
            Positioned(
              top: 50,
              left: 16,
              child: Text(
                "Eqcart Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBox(
                    context, Icons.store, "Add Own Shop", AddOwnShopPage()),
                _buildBox(context, Icons.visibility, "View Own Shop",
                    ViewOwnShopPage()),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBox(context, Icons.store, "Add New Shop", AddShopPage()),
                _buildBox(
                    context, Icons.visibility, "View Shop", ViewShopPage()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(
      BuildContext context, IconData icon, String title, Widget page) {
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
            Text(title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
