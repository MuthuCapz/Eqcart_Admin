import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'coupon_code_page.dart';
import 'created_coupons_list.dart';

class CouponManagementPage extends StatefulWidget {
  const CouponManagementPage({super.key});

  @override
  State<CouponManagementPage> createState() => _CouponManagementPageState();
}

class _CouponManagementPageState extends State<CouponManagementPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text('Coupons Management',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.secondaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create Coupon'),
              Tab(text: 'Created Coupons'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CouponCodeForm(),
            CreatedCouponsList(),
          ],
        ),
      ),
    );
  }
}
