import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eqcart_admin/Shops/add_new_shop/shop_settings/shop_settings_function.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class ShopSettingsForm extends StatefulWidget {
  final String shopId;
  const ShopSettingsForm({Key? key, required this.shopId}) : super(key: key);

  @override
  _ShopSettingsFormState createState() => _ShopSettingsFormState();
}

class _ShopSettingsFormState extends State<ShopSettingsForm> {
  // Holds the time slots as a list of maps. Each map contains a 'start' and 'end' TimeOfDay.
  List<Map<String, TimeOfDay>> timeSlots = [];

  // Controller for the shop name; starts with a "Loading..." value.
  final TextEditingController shopNameController =
      TextEditingController(text: "Loading...");

  // Controllers for various settings fields.
  final Map<String, TextEditingController> fields = {
    'userDistance': TextEditingController(text: '15'),
    'riderDistance': TextEditingController(text: '20'),
    'baseFare': TextEditingController(text: '20'),
    'peakCharge': TextEditingController(text: '10'),
    'speedCharge': TextEditingController(text: '20'),
    'distancePerKM': TextEditingController(text: '5'),
    'estiTime': TextEditingController(text: '30'),
    'cancelledTime': TextEditingController(text: '2'),
    'serviceCharge': TextEditingController(text: '5'),
    'freeDeliveryAmount': TextEditingController(),
    'slotTiming': TextEditingController(),
  };

  bool freeDelivery = false;

  @override
  void initState() {
    super.initState();
    // Fetch the shop name from Firestore using the service function.
    fetchShopNameForSettings(widget.shopId, shopNameController);
  }

  // Helper widget to build a labeled text field.
  Widget buildTextField(String label, TextEditingController controller,
      {bool optional = false,
      Widget? suffix,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: optional ? 'Optional' : null,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Helper to build a row that contains two text fields.
  Widget buildRow(String label1, TextEditingController c1, String label2,
      TextEditingController c2) {
    return Row(
      children: [
        Expanded(child: buildTextField(label1, c1)),
        const SizedBox(width: 12),
        Expanded(child: buildTextField(label2, c2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title:
            const Text("Shop Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField("Shop Name", shopNameController),
            const SizedBox(height: 16),
            buildRow("User Distance", fields['userDistance']!, "Rider Distance",
                fields['riderDistance']!),
            const SizedBox(height: 16),
            buildRow("Base Fare", fields['baseFare']!, "Peak Charge",
                fields['peakCharge']!),
            const SizedBox(height: 16),
            buildRow("Speed Charge", fields['speedCharge']!, "Distance Per KM",
                fields['distancePerKM']!),
            const SizedBox(height: 16),
            buildRow("Estimated Time (min)", fields['estiTime']!,
                "Cancelled Time (min)", fields['cancelledTime']!),
            const SizedBox(height: 16),
            buildTextField("Service Charge", fields['serviceCharge']!),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Choose Delivery Type",
                  style: TextStyle(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: freeDelivery,
                  activeColor: AppColors.secondaryColor,
                  onChanged: (val) => setState(() => freeDelivery = val!),
                ),
                const Text("Free Delivery", style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            buildTextField("Enter amount (Up to 500 ₹) for Free Delivery",
                fields['freeDeliveryAmount']!,
                optional: true),
            const SizedBox(height: 16),
            buildTextField(
              "Add Slot Timing",
              fields['slotTiming']!,
              optional: true,
              readOnly: true,
              onTap: () async {
                // Show the slot picker dialog using our service function.
                List<Map<String, TimeOfDay>> updatedSlots =
                    await showSlotPickerDialog(context, timeSlots);
                setState(() {
                  timeSlots = updatedSlots;
                  fields['slotTiming']!.text = timeSlots
                      .map((slot) =>
                          "${slot['start']!.format(context)} - ${slot['end']!.format(context)}")
                      .join(", ");
                });
              },
              suffix: Icon(Icons.access_alarm, color: AppColors.secondaryColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Validation
                String? error;

                // Helper function to validate if a string represents a number with given max digits.
                bool isValidNumber(String val, int maxDigits) {
                  return RegExp(r'^\d{1,' + maxDigits.toString() + r'}$')
                      .hasMatch(val);
                }

                int? estiTime = int.tryParse(fields['estiTime']!.text.trim());
                int? cancelledTime =
                    int.tryParse(fields['cancelledTime']!.text.trim());

                if (estiTime == null || estiTime < 30 || estiTime > 180) {
                  error = "Estimated Time must be between 30 and 180 minutes.";
                } else if (cancelledTime == null ||
                    cancelledTime < 1 ||
                    cancelledTime > 30) {
                  error = "Cancelled Time must be between 1 and 30 minutes.";
                }

                if (shopNameController.text.trim().isEmpty) {
                  error = "Shop Name cannot be empty.";
                } else if (!isValidNumber(
                    fields['userDistance']!.text.trim(), 2)) {
                  error = "User Distance must be a 2-digit number.";
                } else if (!isValidNumber(
                    fields['riderDistance']!.text.trim(), 2)) {
                  error = "Rider Distance must be a 2-digit number.";
                } else if (!isValidNumber(fields['baseFare']!.text.trim(), 2)) {
                  error = "Base Fare must be a 2-digit number.";
                } else if (!isValidNumber(
                    fields['peakCharge']!.text.trim(), 3)) {
                  error = "Peak Charge must be a 3-digit number.";
                } else if (!isValidNumber(
                    fields['speedCharge']!.text.trim(), 3)) {
                  error = "Speed Charge must be a 3-digit number.";
                } else if (!isValidNumber(
                    fields['distancePerKM']!.text.trim(), 2)) {
                  error = "Distance per KM must be a 2-digit number.";
                } else if (!isValidNumber(
                    fields['serviceCharge']!.text.trim(), 2)) {
                  error = "Service Charge must be a 2-digit number.";
                } else if (freeDelivery &&
                    fields['freeDeliveryAmount']!.text.trim().isEmpty) {
                  error = "Please enter amount for Free Delivery.";
                } else if (timeSlots.length < 3) {
                  error = "At least 3 delivery slots are required.";
                }

                if (error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                  return;
                }

                // Format timeSlots into a list of string representations.
                List<String> formattedSlots = timeSlots.map((slot) {
                  return "${slot['start']!.format(context)} - ${slot['end']!.format(context)}";
                }).toList();

                // Prepare the data to be saved.
                final data = {
                  "shop_name": shopNameController.text.trim(),
                  "userDistance": fields['userDistance']!.text.trim(),
                  "riderDistance": fields['riderDistance']!.text.trim(),
                  "baseFare": fields['baseFare']!.text.trim(),
                  "peakCharge": fields['peakCharge']!.text.trim(),
                  "speedCharge": fields['speedCharge']!.text.trim(),
                  "distancePerKM": fields['distancePerKM']!.text.trim(),
                  "serviceCharge": fields['serviceCharge']!.text.trim(),
                  "estimatedTime": estiTime,
                  "cancelledTime": cancelledTime,
                  "freeDelivery": freeDelivery,
                  "freeDeliveryAmount":
                      fields['freeDeliveryAmount']!.text.trim(),
                  "slotTiming": formattedSlots,
                  "createdAt": FieldValue.serverTimestamp(),
                  "updatedAt": FieldValue.serverTimestamp(),
                };

                final FirebaseFirestore firestore = FirebaseFirestore.instance;

                try {
                  // Check if the shop exists in the "shops" collection.
                  final shopDoc = await firestore
                      .collection('shops')
                      .doc(widget.shopId)
                      .get();
                  final isOwnShop = !shopDoc.exists;
                  final settingsPath =
                      isOwnShop ? 'own_shops_settings' : 'shops_settings';

                  await firestore
                      .collection(settingsPath)
                      .doc(widget.shopId)
                      .set(data);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Shop settings saved successfully!")),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving settings: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Continue",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
