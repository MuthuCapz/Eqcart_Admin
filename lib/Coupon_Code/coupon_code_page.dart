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

  DateTime? expiryDate;
  CouponType selectedType = CouponType.common;
  List<String> selectedShopIds = [];
  List<Map<String, String>> availableShops = [];

  Future<void> submitCoupon() async {
    final code = codeController.text.trim();
    final discount = double.tryParse(discountController.text.trim()) ?? 0.0;
    final description = descriptionController.text.trim();
    final maxUsage = int.tryParse(usageLimitController.text.trim()) ?? 1;

    if (code.isEmpty || discount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.')),
      );
      return;
    }

    final now = DateTime.now();
    final selectedShops = availableShops
        .where((shop) => selectedShopIds.contains(shop['id']))
        .map((shop) => {
              'id': shop['id']!,
              'name': shop['name']!,
            })
        .toList();

    final coupon = Coupon(
      code: code,
      description: description,
      discount: discount,
      expiryDate: expiryDate ?? now.add(const Duration(days: 30)),
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
      setState(() {
        selectedType = CouponType.common;
        selectedShopIds.clear();
        availableShops.clear();
        expiryDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving coupon: $e')),
      );
    }
  }

  Future<void> selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        expiryDate = picked;
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Coupon Code'),
            ),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount %'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: usageLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Max Usage per User (count)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CouponType>(
              value: selectedType,
              items: CouponType.values.map((type) {
                String label;
                switch (type) {
                  case CouponType.common:
                    label = 'Common';
                    break;
                  case CouponType.specificShop:
                    label = 'Own Shops';
                    break;
                  case CouponType.multiShop:
                    label = 'Multiple Shops';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(label),
                );
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
              decoration: const InputDecoration(labelText: 'Coupon Type'),
            ),
            if (selectedType == CouponType.specificShop ||
                selectedType == CouponType.multiShop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Select Shops:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableShops.map((shop) {
                      final isSelected = selectedShopIds.contains(shop['id']);
                      return FilterChip(
                        label: Text(shop['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected &&
                                !selectedShopIds.contains(shop['id'])) {
                              selectedShopIds.add(shop['id']!);
                            } else if (!selected) {
                              selectedShopIds.remove(shop['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    expiryDate != null
                        ? 'Expires: ${expiryDate!.toLocal().toString().split(' ')[0]}'
                        : 'No expiry date selected',
                  ),
                ),
                TextButton(
                  onPressed: () => selectExpiryDate(context),
                  child: const Text('Pick Expiry Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: submitCoupon,
              child: const Text('Save Coupon'),
            ),
          ],
        ),
      ),
    );
  }
}
// Models

enum CouponType {
  common,
  specificShop, // own shops
  multiShop, // multiple shops
}

class Coupon {
  final String code;
  final String description;
  final double discount;
  final DateTime expiryDate;
  final CouponType type;
  final List<Map<String, String>> applicableShops;
  final DateTime createdAt;
  final int maxUsagePerUser;

  Coupon({
    required this.code,
    required this.description,
    required this.discount,
    required this.expiryDate,
    required this.type,
    required this.applicableShops,
    required this.createdAt,
    required this.maxUsagePerUser,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discount': discount,
        'expiryDate': expiryDate.toIso8601String(),
        'type': type.name,
        'applicableShops': applicableShops,
        'createdAt': createdAt.toIso8601String(),
        'maxUsagePerUser': maxUsagePerUser,
      };

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code'],
        description: json['description'],
        discount: (json['discount'] as num).toDouble(),
        expiryDate: DateTime.parse(json['expiryDate']),
        type: CouponType.values.firstWhere((e) => e.name == json['type']),
        applicableShops: List<Map<String, String>>.from(
          (json['applicableShops'] as List)
              .map((e) => Map<String, String>.from(e)),
        ),
        createdAt: DateTime.parse(json['createdAt']),
        maxUsagePerUser: json['maxUsagePerUser'] ?? 1,
      );
}
