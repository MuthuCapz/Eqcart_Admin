import 'package:flutter/material.dart';

import '../utils/colors.dart';

class CouponCodePage extends StatelessWidget {
  const CouponCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Coupon Code', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('Coupon Code', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
