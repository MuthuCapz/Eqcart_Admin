// coupon_code_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import 'coupon.dart';

class CouponCodeForm extends StatefulWidget {
  const CouponCodeForm({super.key});

  @override
  State<CouponCodeForm> createState() => _CouponCodeFormState();
}

class _CouponCodeFormState extends State<CouponCodeForm> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController usageLimitController = TextEditingController();
  final TextEditingController minimumOrderController = TextEditingController();

  DateTime? validFrom;
  DateTime? validTo;
  CouponType selectedType = CouponType.common;
  List<String> selectedShopIds = [];
  List<Map<String, String>> availableShops = [];

  InputDecoration inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  Future<void> submitCoupon() async {
    final code = codeController.text.trim();
    final discount = double.tryParse(discountController.text.trim()) ?? 0.0;
    final description = descriptionController.text.trim();
    final maxUsage = int.tryParse(usageLimitController.text.trim()) ?? 1;
    final minOrderValue =
        double.tryParse(minimumOrderController.text.trim()) ?? 0.0;

    if (code.isEmpty || discount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.')),
      );
      return;
    }

    if (validFrom == null || validTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select validity dates.')),
      );
      return;
    }

    final now = DateTime.now();
    final selectedShops = availableShops
        .where((shop) => selectedShopIds.contains(shop['id']))
        .map((shop) => {'id': shop['id']!, 'name': shop['name']!})
        .toList();

    final coupon = Coupon(
      code: code,
      description: description,
      discount: discount,
      minimumOrderValue: minOrderValue,
      validFrom: validFrom!,
      validTo: validTo!,
      type: selectedType,
      applicableShops: selectedType == CouponType.common ? [] : selectedShops,
      createdAt: now,
      maxUsagePerUser: maxUsage,
    );

    try {
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(coupon.code)
          .set(coupon.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon saved successfully!')),
      );

      // Clear form
      codeController.clear();
      discountController.clear();
      descriptionController.clear();
      minimumOrderController.clear();
      setState(() {
        selectedType = CouponType.common;
        selectedShopIds.clear();
        availableShops.clear();
        validFrom = null;
        validTo = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving coupon: $e')),
      );
    }
  }

  Future<void> selectValidDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.backgroundColor,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        validFrom = picked.start;
        validTo = picked.end;
      });
    }
  }

  Future<void> fetchShopsForType(CouponType type) async {
    QuerySnapshot snapshot;
    if (type == CouponType.specificShop) {
      snapshot = await FirebaseFirestore.instance.collection('own_shops').get();
    } else if (type == CouponType.multiShop) {
      snapshot = await FirebaseFirestore.instance.collection('shops').get();
    } else {
      return;
    }

    setState(() {
      availableShops = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': (data['shop_id'] ?? '').toString(),
          'name': (data['shop_name'] ?? 'Unnamed Shop').toString(),
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor),
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: TextStyle(color: AppColors.secondaryColor),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Create a New Coupon',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                            controller: codeController,
                            decoration: inputDecoration('Coupon Code')),
                        const SizedBox(height: 16),
                        TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Discount (%)'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: descriptionController,
                            decoration: inputDecoration('Description')),
                        const SizedBox(height: 16),
                        TextField(
                          controller: usageLimitController,
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Max Usage per User'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: minimumOrderController,
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Minimum Order Value'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                validFrom != null && validTo != null
                                    ? 'Valid: ${validFrom!.toLocal().toString().split(' ')[0]} - ${validTo!.toLocal().toString().split(' ')[0]}'
                                    : 'No Validity Range Selected',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: const Text('Pick Dates'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.secondaryColor,
                              ),
                              onPressed: () => selectValidDateRange(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<CouponType>(
                          value: selectedType,
                          decoration: inputDecoration('Coupon Type'),
                          items: CouponType.values.map((type) {
                            final label = {
                              CouponType.common: 'Common',
                              CouponType.specificShop: 'Own Shops',
                              CouponType.multiShop: 'Multiple Shops',
                            }[type];
                            return DropdownMenuItem(
                                value: type, child: Text(label!));
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() {
                                selectedType = value;
                                selectedShopIds.clear();
                                availableShops.clear();
                              });
                              await fetchShopsForType(value);
                            }
                          },
                        ),
                        if (selectedType != CouponType.common) ...[
                          const SizedBox(height: 16),
                          const Text('Select Shops:',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: availableShops.map((shop) {
                              final isSelected =
                                  selectedShopIds.contains(shop['id']);
                              return FilterChip(
                                label: Text(shop['name']!),
                                selected: isSelected,
                                selectedColor:
                                    AppColors.secondaryColor.withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                checkmarkColor: AppColors.primaryColor,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedShopIds.add(shop['id']!);
                                    } else {
                                      selectedShopIds.remove(shop['id']);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save,
                              color: Colors.white), // icon color
                          label: const Text('Save Coupon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor:
                                Colors.white, // sets color for icon & label
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: submitCoupon,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
