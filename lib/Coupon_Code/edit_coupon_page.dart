import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'coupon.dart';

class EditCouponPage extends StatefulWidget {
  final Coupon coupon;

  const EditCouponPage({super.key, required this.coupon});

  @override
  State<EditCouponPage> createState() => _EditCouponPageState();
}

class _EditCouponPageState extends State<EditCouponPage> {
  late TextEditingController codeController;
  late TextEditingController discountController;
  late TextEditingController descriptionController;
  late TextEditingController usageLimitController;

  DateTime? expiryDate;
  late CouponType selectedType;
  List<String> selectedShopIds = [];
  List<Map<String, String>> availableShops = [];

  @override
  void initState() {
    super.initState();
    final coupon = widget.coupon;

    codeController = TextEditingController(text: coupon.code);
    discountController =
        TextEditingController(text: coupon.discount.toString());
    descriptionController = TextEditingController(text: coupon.description);
    usageLimitController =
        TextEditingController(text: coupon.maxUsagePerUser.toString());

    expiryDate = coupon.expiryDate;
    selectedType = coupon.type;
    selectedShopIds = coupon.applicableShops.map((e) => e['id']!).toList();

    fetchShopsForType(selectedType);
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

  Future<void> updateCoupon() async {
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

    final selectedShops = availableShops
        .where((shop) => selectedShopIds.contains(shop['id']))
        .map((shop) => {
              'id': shop['id']!,
              'name': shop['name']!,
            })
        .toList();

    final updatedCoupon = Coupon(
      code: code,
      description: description,
      discount: discount,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      type: selectedType,
      applicableShops: selectedType == CouponType.common ? [] : selectedShops,
      createdAt: widget.coupon.createdAt,
      maxUsagePerUser: maxUsage,
    );

    try {
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(updatedCoupon.code)
          .set(updatedCoupon.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating coupon: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Coupon', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Coupon Code'),
              enabled: false, // Prevent editing coupon code
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
              decoration:
                  const InputDecoration(labelText: 'Max Usage per User'),
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
                            if (selected && !isSelected) {
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
              onPressed: updateCoupon,
              child: const Text('Update Coupon'),
            ),
          ],
        ),
      ),
    );
  }
}
