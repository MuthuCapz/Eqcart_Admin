import 'package:flutter/material.dart';

import '../utils/colors.dart';

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), // Same height as HomePage
        child: Stack(
          children: [
            Container(
              height: 90, // Green box height
              color: AppColors.secondaryColor, // Top green background
            ),
            Positioned(
              top: 53, // Positioning title inside the green box
              left: 70,
              child: Text(
                "Product Page", // Same title as HomePage
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white), // Back icon
                onPressed: () {
                  Navigator.pop(context); // Go back to the previous page
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          "This is Product Page",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
