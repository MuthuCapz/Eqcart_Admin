import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'created_coupons_page.dart';

class ShopsCouponsPage extends StatefulWidget {
  final String shopId;
  const ShopsCouponsPage({Key? key, required this.shopId}) : super(key: key);

  @override
  State<ShopsCouponsPage> createState() => _ShopsCouponsPageState();
}

class _ShopsCouponsPageState extends State<ShopsCouponsPage> {
  final _formKey = GlobalKey<FormState>();
  final couponCodeController = TextEditingController();
  final discountController = TextEditingController();
  final descriptionController = TextEditingController();
  final maxUsageController = TextEditingController();
  final minOrderController = TextEditingController();
  bool showCreatedCoupons = false;
  DateTime? validFrom;
  DateTime? validTo;

  Future<String> fetchShopName() async {
    final docA = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .get();
    if (docA.exists) return docA.data()?['shop_name'] ?? 'Unnamed Shop';

    final docB = await FirebaseFirestore.instance
        .collection('own_shops')
        .doc(widget.shopId)
        .get();
    if (docB.exists) return docB.data()?['shop_name'] ?? 'Unnamed Shop';

    throw 'Shop not found';
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

  Future<void> saveCoupon(String shopName) async {
    final code = couponCodeController.text.trim();
    final data = {
      'couponCode': code,
      'discount': double.tryParse(discountController.text) ?? 0,
      'description': descriptionController.text,
      'maxUsagePerUser': int.tryParse(maxUsageController.text) ?? 1,
      'minimumOrderValue': double.tryParse(minOrderController.text) ?? 0,
      'validFrom': validFrom,
      'validTo': validTo,
      'shopName': shopName,
      'createDateTime': FieldValue.serverTimestamp(),
      'createdBy': shopName,
      'shopId': widget.shopId,
    };
    await FirebaseFirestore.instance.collection('coupons').doc(code).set(data);

    couponCodeController.clear();
    discountController.clear();
    descriptionController.clear();
    maxUsageController.clear();
    minOrderController.clear();
    setState(() {
      validFrom = null;
      validTo = null;
      showCreatedCoupons = true;
    });
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller,
      TextInputType? keyboardType}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (v) => v?.isEmpty == true ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCreateForm(String shopName) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Create a New Coupon',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    _buildTextField('Coupon Code',
                        controller: couponCodeController),
                    _buildTextField('Discount (%)',
                        controller: discountController,
                        keyboardType: TextInputType.number),
                    _buildTextField('Description',
                        controller: descriptionController),
                    _buildTextField('Max Usage per User',
                        controller: maxUsageController,
                        keyboardType: TextInputType.number),
                    _buildTextField('Minimum Order Value',
                        controller: minOrderController,
                        keyboardType: TextInputType.number),
                    SizedBox(height: 10),
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
                    SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      initialValue: shopName,
                      decoration: InputDecoration(
                        labelText: 'Shop Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          saveCoupon(shopName);
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text('Save Coupon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title:
            Text('Coupons Management', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: FutureBuilder<String>(
        future: fetchShopName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final shopName = snapshot.data!;
          return Column(
            children: [
              ToggleButtonsHeader(
                selected: showCreatedCoupons,
                onToggle: (val) => setState(() => showCreatedCoupons = val),
              ),
              Expanded(
                child: showCreatedCoupons
                    ? CreatedCouponsPage(shopId: widget.shopId)
                    : _buildCreateForm(shopName),
              )
            ],
          );
        },
      ),
    );
  }
}

class ToggleButtonsHeader extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onToggle;

  const ToggleButtonsHeader({
    Key? key,
    required this.selected,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !selected
                      ? AppColors.backgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Create Coupon",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: !selected ? Colors.black : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected ? AppColors.backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Created Coupons",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.black : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
