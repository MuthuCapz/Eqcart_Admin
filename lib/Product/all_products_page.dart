import 'package:flutter/material.dart';

class AllProductsPage extends StatelessWidget {
  final String shopId;

  AllProductsPage({required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'All Products for Shop: $shopId',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
