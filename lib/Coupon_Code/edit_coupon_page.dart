// shops_coupons_edit_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'coupon.dart'; // Importing from the correct location

class EditCouponPage extends StatefulWidget {
  final Coupon coupon;

  const EditCouponPage({super.key, required this.coupon});

  @override
  State<EditCouponPage> createState() => _EditCouponPageState();
}

class _EditCouponPageState extends State<EditCouponPage> {
  late TextEditingController codeController;
  late TextEditingController discountController;
  late TextEditingController fixedAmountController;
  late TextEditingController descriptionController;
  late TextEditingController usageLimitController;
  late TextEditingController minimumOrderController;
  DateTime? validFrom;
  DateTime? validTo;
  late CouponType selectedType;
  List<String> selectedShopIds = [];
  List<Map<String, String>> availableShops = [];

  @override
  void initState() {
    super.initState();
    final coupon = widget.coupon;

    codeController = TextEditingController(text: coupon.code);
    if (coupon.fixedAmount != null && coupon.fixedAmount! > 0) {
      fixedAmountController = TextEditingController(
        text: coupon.fixedAmount!.toString(),
      );
      discountController = TextEditingController(text: '');
    } else {
      discountController = TextEditingController(
        text: coupon.discount.toString(),
      );
      fixedAmountController = TextEditingController(text: '');
    }

    descriptionController = TextEditingController(text: coupon.description);
    usageLimitController =
        TextEditingController(text: coupon.maxUsagePerUser.toString());
    minimumOrderController =
        TextEditingController(text: coupon.minimumOrderValue.toString());

    validFrom = coupon.validFrom;
    validTo = coupon.validTo;
    selectedType = coupon.type;
    selectedShopIds = coupon.applicableShops.map((e) => e['id']!).toList();
    discountController.addListener(() => setState(() {}));
    fixedAmountController.addListener(() => setState(() {}));

    fetchShopsForType(selectedType);
  }

  Future<void> selectDate(BuildContext context, DateTime? currentDate,
      ValueChanged<DateTime> onDatePicked,
      {bool isStartDate = false}) async {
    final now = DateTime.now();
    final initialDate = currentDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: isStartDate
          ? now
          : validFrom ?? now, // For end date, can't be before start date
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onDatePicked(picked);
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

  Future<void> updateCoupon() async {
    final code = codeController.text.trim();
    final discount = double.tryParse(discountController.text.trim()) ?? 0.0;
    final description = descriptionController.text.trim();
    final maxUsage = int.tryParse(usageLimitController.text.trim()) ?? 1;
    final minimumOrderValue =
        double.tryParse(minimumOrderController.text.trim()) ?? 0.0;

    final fixedAmount =
        double.tryParse(fixedAmountController.text.trim()) ?? 0.0;

    if (code.isEmpty ||
        (discount <= 0 && fixedAmount <= 0) ||
        (discount > 0 && fixedAmount > 0) ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill either Discount or Fixed Amount (not both).')),
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
      discount: discount > 0 ? discount : 0,
      fixedAmount: fixedAmount > 0 ? fixedAmount : null,
      type: selectedType,
      applicableShops: selectedType == CouponType.common ? [] : selectedShops,
      createdAt: widget.coupon.createdAt,
      maxUsagePerUser: maxUsage,
      minimumOrderValue: minimumOrderValue,
      validFrom: validFrom!,
      validTo: validTo!,
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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Coupon',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Coupon Details'),
            _buildTextField('Coupon Code', codeController, enabled: false),
            _buildTextField(
              'Discount (%)',
              discountController,
              inputType: TextInputType.number,
              enabled: fixedAmountController.text.isEmpty,
            ),
            _buildTextField(
              'Fixed Amount',
              fixedAmountController,
              inputType: TextInputType.number,
              enabled: discountController.text.isEmpty,
            ),
            _buildTextField('Description', descriptionController),
            _buildTextField('Max Usage per User', usageLimitController,
                inputType: TextInputType.number),
            _buildTextField('Minimum Order Value', minimumOrderController,
                inputType: TextInputType.number),
            const SizedBox(height: 20),
            _buildSectionTitle('Coupon Type'),
            DropdownButtonFormField<CouponType>(
              value: selectedType,
              dropdownColor: Colors.white,
              decoration: _inputDecoration('Coupon Type'),
              items: CouponType.values.map((type) {
                final label = switch (type) {
                  CouponType.common => 'Common',
                  CouponType.specificShop => 'Own Shops',
                  CouponType.multiShop => 'Multiple Shops',
                };
                return DropdownMenuItem(value: type, child: Text(label));
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
            const SizedBox(height: 16),
            if (selectedType == CouponType.specificShop ||
                selectedType == CouponType.multiShop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Select Shops'),
                  Wrap(
                    spacing: 8,
                    children: availableShops.map((shop) {
                      final isSelected = selectedShopIds.contains(shop['id']);
                      return FilterChip(
                        label: Text(shop['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedShopIds.add(shop['id']!);
                            } else {
                              selectedShopIds.remove(shop['id']);
                            }
                          });
                        },
                        selectedColor:
                            AppColors.secondaryColor.withOpacity(0.8),
                        checkmarkColor: Colors.white,
                        backgroundColor:
                            AppColors.secondaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            _buildSectionTitle('Validity Period'),
            _buildDateSelector('Valid From', validFrom, () {
              selectDate(context, validFrom, (picked) {
                setState(() => validFrom = picked);
              }, isStartDate: true);
            }),
            const SizedBox(height: 10),
            _buildDateSelector('Valid To', validTo, () {
              if (validFrom == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select start date first')),
                );
                return;
              }
              selectDate(context, validTo, (picked) {
                setState(() => validTo = picked);
              }, isStartDate: false);
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: updateCoupon,
                icon: const Icon(Icons.save),
                label: const Text('Update Coupon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        enabled: enabled,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            date != null
                ? '$label: ${date.toLocal().toString().split(' ')[0]}'
                : 'No date selected',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text('Pick Date',
              style: TextStyle(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    discountController.dispose();
    fixedAmountController.dispose();
    descriptionController.dispose();
    usageLimitController.dispose();
    minimumOrderController.dispose();
    super.dispose();
  }
}
