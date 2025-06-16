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
  late TextEditingController discountController;
  late TextEditingController descriptionController;
  late TextEditingController maxUsageController;
  late TextEditingController minOrderController;

  DateTime? validFrom;
  DateTime? validTo;

  @override
  void initState() {
    super.initState();

    discountController = TextEditingController(
        text: widget.couponData['discount']?.toString() ?? '0');
    descriptionController =
        TextEditingController(text: widget.couponData['description'] ?? '');
    maxUsageController = TextEditingController(
        text: widget.couponData['maxUsagePerUser']?.toString() ?? '1');
    minOrderController = TextEditingController(
        text: widget.couponData['minimumOrderValue']?.toString() ?? '0');

    validFrom = (widget.couponData['validFrom'] as Timestamp?)?.toDate();
    validTo = (widget.couponData['validTo'] as Timestamp?)?.toDate();
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
    final updatedFields = {
      'discount': double.tryParse(discountController.text) ?? 0,
      'description': descriptionController.text,
      'maxUsagePerUser': int.tryParse(maxUsageController.text) ?? 1,
      'minimumOrderValue': double.tryParse(minOrderController.text) ?? 0,
      'validFrom': validFrom,
      'validTo': validTo,
      'updateDateTime': FieldValue.serverTimestamp(), // ✅ Add update time
      'shopName': widget.couponData['shopName'], // ✅ Ensure shopName stays
    };

    await FirebaseFirestore.instance
        .collection('coupons')
        .doc(widget.docId)
        .set(updatedFields,
            SetOptions(merge: true)); // ✅ Merge instead of overwrite

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
            _buildTextField('Discount (%)', controller: discountController),
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

  Widget _buildTextField(String label,
      {required TextEditingController controller,
      TextInputType? keyboardType}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
