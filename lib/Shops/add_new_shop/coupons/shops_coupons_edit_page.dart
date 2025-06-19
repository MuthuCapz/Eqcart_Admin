import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class ShopsCouponsEditPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> couponData;

  const ShopsCouponsEditPage({
    Key? key,
    required this.docId,
    required this.couponData,
  }) : super(key: key);

  @override
  State<ShopsCouponsEditPage> createState() => _ShopsCouponsEditPage();
}

class _ShopsCouponsEditPage extends State<ShopsCouponsEditPage> {
  // Initialize controllers immediately instead of using late
  final TextEditingController discountController = TextEditingController();
  final TextEditingController fixedAmountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxUsageController = TextEditingController();
  final TextEditingController minOrderController = TextEditingController();

  DateTime? validFrom;
  DateTime? validTo;

  final isDiscountEnabled = ValueNotifier<bool>(true);
  final isFixedAmountEnabled = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    // Assign values to controllers
    discountController.text = widget.couponData['discount']?.toString() ?? '';
    fixedAmountController.text =
        widget.couponData['fixedAmount']?.toString() ?? '';
    descriptionController.text = widget.couponData['description'] ?? '';
    maxUsageController.text =
        widget.couponData['maxUsagePerUser']?.toString() ?? '1';
    minOrderController.text =
        widget.couponData['minimumOrderValue']?.toString() ?? '0';

    validFrom = _convertToDate(widget.couponData['validFrom']);
    validTo = _convertToDate(widget.couponData['validTo']);

    // Initialize enable state based on actual values (non-zero, non-empty)
    final hasDiscount = _hasRealValue(discountController.text);
    final hasFixedAmount = _hasRealValue(fixedAmountController.text);

    isDiscountEnabled.value = !hasFixedAmount;
    isFixedAmountEnabled.value = !hasDiscount;

    // Add listeners
    discountController.addListener(() {
      final hasDiscount = _hasRealValue(discountController.text);
      final hasFixed = _hasRealValue(fixedAmountController.text);

      if (hasDiscount) {
        fixedAmountController.clear();
        isFixedAmountEnabled.value = false;
      } else if (!hasFixed) {
        isFixedAmountEnabled.value = true;
      }
    });

    fixedAmountController.addListener(() {
      final hasFixed = _hasRealValue(fixedAmountController.text);
      final hasDiscount = _hasRealValue(discountController.text);

      if (hasFixed) {
        discountController.clear();
        isDiscountEnabled.value = false;
      } else if (!hasDiscount) {
        isDiscountEnabled.value = true;
      }
    });
  }

  bool _hasRealValue(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final value = double.tryParse(trimmed);
    return value != null && value != 0.0;
  }

  DateTime? _convertToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> selectValidDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 1)),
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

  Future<void> updateCoupon() async {
    final discountText = discountController.text.trim();
    final fixedText = fixedAmountController.text.trim();

    final isDiscountFilled = discountText.isNotEmpty;
    final isFixedFilled = fixedText.isNotEmpty;

    if (isDiscountFilled && isFixedFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter only Discount or Fixed amount, not both.'),
        ),
      );
      return;
    }

    if (!isDiscountFilled && !isFixedFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter either Discount or Fixed amount.'),
        ),
      );
      return;
    }

    final updatedFields = {
      'discount': double.tryParse(discountText) ?? 0,
      'fixedAmount': double.tryParse(fixedText) ?? 0,
      'description': descriptionController.text,
      'maxUsagePerUser': int.tryParse(maxUsageController.text) ?? 1,
      'minimumOrderValue': double.tryParse(minOrderController.text) ?? 0,
      'validFrom': validFrom,
      'validTo': validTo,
      'updateDateTime': FieldValue.serverTimestamp(),
      'shopName': widget.couponData['shopName'],
    };

    await FirebaseFirestore.instance
        .collection('coupons_by_shops')
        .doc(widget.docId)
        .set(updatedFields, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon updated')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.couponData['shopName'] ?? 'Unnamed Shop';
    final couponCode = widget.couponData['couponCode'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Coupon', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: couponCode,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Coupon Code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: shopName,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Discount field
            ValueListenableBuilder<bool>(
              valueListenable: isDiscountEnabled,
              builder: (context, value, _) {
                return _buildTextField(
                  'Discount (%)',
                  controller: discountController,
                  enabled: value,
                  keyboardType: TextInputType.number,
                );
              },
            ),

            // Fixed Amount field
            ValueListenableBuilder<bool>(
              valueListenable: isFixedAmountEnabled,
              builder: (context, value, _) {
                return _buildTextField(
                  'Fixed Amount',
                  controller: fixedAmountController,
                  enabled: value,
                  keyboardType: TextInputType.number,
                );
              },
            ),

            _buildTextField('Description', controller: descriptionController),
            _buildTextField('Max Usage per User',
                controller: maxUsageController,
                keyboardType: TextInputType.number),
            _buildTextField('Minimum Order Value',
                controller: minOrderController,
                keyboardType: TextInputType.number),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    validFrom != null && validTo != null
                        ? 'Valid: ${validFrom!.toLocal().toString().split(' ')[0]} - ${validTo!.toLocal().toString().split(' ')[0]}'
                        : 'No Validity Range Selected',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => selectValidDateRange(context),
                  icon: Icon(Icons.calendar_today, size: 16),
                  label: Text('Pick Dates'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: updateCoupon,
              icon: Icon(Icons.save),
              label: Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    discountController.dispose();
    fixedAmountController.dispose();
    descriptionController.dispose();
    maxUsageController.dispose();
    minOrderController.dispose();
    super.dispose();
  }
}
