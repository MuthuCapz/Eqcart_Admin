import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'created_shops_coupons_list.dart';
import '../../../utils/colors.dart';

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
  final fixedAmountController = TextEditingController();

  final descriptionController = TextEditingController();
  final maxUsageController = TextEditingController();
  final minOrderController = TextEditingController();

  DateTime? validFrom;
  DateTime? validTo;
  final isDiscountEnabled = ValueNotifier<bool>(true);
  final isFixedAmountEnabled = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    discountController.addListener(() {
      final hasValue = discountController.text.trim().isNotEmpty;
      isFixedAmountEnabled.value = !hasValue;
    });

    fixedAmountController.addListener(() {
      final hasValue = fixedAmountController.text.trim().isNotEmpty;
      isDiscountEnabled.value = !hasValue;
    });
  }

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
    final discountText = discountController.text.trim();
    final fixedText = fixedAmountController.text.trim();

    final isDiscountFilled = discountText.isNotEmpty;
    final isFixedAmountFilled = fixedText.isNotEmpty;

    if (isDiscountFilled && isFixedAmountFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please enter only Discount or Fixed amount, not both.')),
      );
      return;
    }

    if (!isDiscountFilled && !isFixedAmountFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter either Discount or Fixed amount.')),
      );
      return;
    }

    final data = {
      'couponCode': code,
      'discount': double.tryParse(discountText) ?? 0,
      'fixedAmount': double.tryParse(fixedText) ?? 0,
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

    await FirebaseFirestore.instance
        .collection('coupons_by_shops')
        .doc(code)
        .set(data);

    couponCodeController.clear();
    discountController.clear();
    fixedAmountController.clear();
    descriptionController.clear();
    maxUsageController.clear();
    minOrderController.clear();

    isDiscountEnabled.value = true;
    isFixedAmountEnabled.value = true;
    setState(() {
      validFrom = null;
      validTo = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon saved successfully!')),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller,
      TextInputType? keyboardType,
      bool enabled = true,
      String? Function(String?)? validator}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        validator: validator,
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
                    ValueListenableBuilder<bool>(
                      valueListenable: isDiscountEnabled,
                      builder: (context, value, _) {
                        return _buildTextField(
                          'Discount (%)',
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          enabled: value,
                          validator: null, // <--- no individual validation
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: isFixedAmountEnabled,
                      builder: (context, value, _) {
                        return _buildTextField(
                          'Fixed amount',
                          controller: fixedAmountController,
                          keyboardType: TextInputType.number,
                          enabled: value,
                          validator: null, // <--- no individual validation
                        );
                      },
                    ),
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
                        final discountText = discountController.text.trim();
                        final fixedText = fixedAmountController.text.trim();

                        final isDiscountFilled = discountText.isNotEmpty;
                        final isFixedAmountFilled = fixedText.isNotEmpty;

                        if (isDiscountFilled && isFixedAmountFilled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Enter only Discount or Fixed amount, not both.')),
                          );
                          return;
                        }

                        if (!isDiscountFilled && !isFixedAmountFilled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Enter either Discount or Fixed amount.')),
                          );
                          return;
                        }

                        if (_formKey.currentState!.validate()) {
                          saveCoupon(shopName);
                        }
                      },
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text('Save Coupon',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title:
              Text('Coupons Management', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.secondaryColor,
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Create Coupon'),
              Tab(text: 'Created Coupons'),
            ],
          ),
        ),
        body: FutureBuilder<String>(
          future: fetchShopName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final shopName = snapshot.data!;
            return TabBarView(
              children: [
                _buildCreateForm(shopName),
                CreatedShopsCouponsList(),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    couponCodeController.dispose();
    discountController.dispose();
    fixedAmountController.dispose();
    descriptionController.dispose();
    maxUsageController.dispose();
    minOrderController.dispose();
    super.dispose();
  }
}
