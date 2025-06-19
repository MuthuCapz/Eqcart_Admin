import 'package:flutter/material.dart';
import '../Shops/add_new_shop/coupons/created_shops_coupons_list.dart';
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
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.secondaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Coupons Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: AppColors.backgroundColor.withOpacity(0.7),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 20.0),
            ),
            indicatorWeight: 4,
            indicatorColor: Colors.white,
            labelStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Create Coupon'),
              Tab(text: 'Created Coupons'),
              Tab(text: 'Shops Created Coupons'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CouponCodeForm(),
            CreatedCouponsList(),
            CreatedShopsCouponsList(),
          ],
        ),
      ),
    );
  }
}
