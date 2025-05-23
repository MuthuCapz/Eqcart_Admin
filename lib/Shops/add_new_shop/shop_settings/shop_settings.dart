import 'package:flutter/material.dart';
import 'shop_settings_form.dart';

class ShopSettings extends StatelessWidget {
  final String shopId;
  const ShopSettings({Key? key, required this.shopId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShopSettingsForm(shopId: shopId);
  }
}
