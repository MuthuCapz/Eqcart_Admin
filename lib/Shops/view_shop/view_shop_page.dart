import 'package:flutter/material.dart';

import '../../utils/colors.dart';

class ViewShopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('View Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text("View Shop Page Content Here"),
      ),
    );
  }
}
