import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class ShopSettings extends StatefulWidget {
  final String shopId;
  const ShopSettings({required this.shopId});

  @override
  State<ShopSettings> createState() => _ShopSettingsPageState();
}

class _ShopSettingsPageState extends State<ShopSettings> {
  List<Map<String, TimeOfDay>> timeSlots = [];

  @override
  void initState() {
    super.initState();
    fetchShopName();
  }

  Future<void> fetchShopName() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String defaultName = "Eqcart Mart";
    String? shopName;

    try {
      // First check in 'shops'
      final shopDoc =
          await firestore.collection('shops').doc(widget.shopId).get();

      if (shopDoc.exists && shopDoc.data()!.containsKey('shop_name')) {
        shopName = shopDoc['shop_name'];
      } else {
        // If not found, check in 'own_shops'
        final ownShopDoc =
            await firestore.collection('own_shops').doc(widget.shopId).get();
        if (ownShopDoc.exists && ownShopDoc.data()!.containsKey('shop_name')) {
          shopName = ownShopDoc['shop_name'];
        }
      }

      setState(() {
        shopNameController.text = shopName ?? defaultName;
      });
    } catch (e) {
      // If error, fallback to default
      setState(() {
        shopNameController.text = defaultName;
      });
    }
  }

  Future<void> showSlotPickerDialog() async {
    timeSlots = timeSlots.isNotEmpty
        ? List.from(timeSlots)
        : [
            {
              "start": TimeOfDay(hour: 8, minute: 0),
              "end": TimeOfDay(hour: 10, minute: 0)
            },
            {
              "start": TimeOfDay(hour: 11, minute: 0),
              "end": TimeOfDay(hour: 13, minute: 0)
            },
            {
              "start": TimeOfDay(hour: 15, minute: 0),
              "end": TimeOfDay(hour: 17, minute: 0)
            },
          ];

    final TimeOfDay minTime = TimeOfDay(hour: 5, minute: 0); // 5 AM
    final TimeOfDay maxTime = TimeOfDay(hour: 23, minute: 0); // 11 PM

    bool isTimeWithinRange(
        TimeOfDay time, TimeOfDay minTime, TimeOfDay maxTime) {
      final int timeInMinutes = time.hour * 60 + time.minute;
      final int minTimeInMinutes = minTime.hour * 60 + minTime.minute;
      final int maxTimeInMinutes = maxTime.hour * 60 + maxTime.minute;
      return timeInMinutes >= minTimeInMinutes &&
          timeInMinutes <= maxTimeInMinutes;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickTime(int index, bool isStart) async {
              final initialTime = isStart
                  ? timeSlots[index]['start']!
                  : timeSlots[index]['end']!;
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (picked != null &&
                  isTimeWithinRange(picked, minTime, maxTime)) {
                setState(() {
                  timeSlots[index][isStart ? 'start' : 'end'] = picked;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Please select a time between 5 AM and 11 PM.")),
                );
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Delivery Time Slots",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryColor)),
                    const SizedBox(height: 16),
                    ...timeSlots.asMap().entries.map((entry) {
                      int i = entry.key;
                      var slot = entry.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                color: AppColors.secondaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "${slot['start']!.format(context)} - ${slot['end']!.format(context)}",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await pickTime(i, true);
                                await pickTime(i, false);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => timeSlots.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: timeSlots.length >= 4
                          ? null
                          : () {
                              setState(() {
                                timeSlots.add({
                                  "start": TimeOfDay(hour: 18, minute: 0),
                                  "end": TimeOfDay(hour: 20, minute: 0),
                                });
                              });
                            },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Add New Slot",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final slotsText = timeSlots
                                .map((slot) =>
                                    "${slot['start']!.format(context)} - ${slot['end']!.format(context)}")
                                .join(", ");
                            setState(() {
                              fields['slotTiming']!.text = slotsText;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Save",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  final TextEditingController shopNameController =
      TextEditingController(text: "Loading...");

  final Map<String, TextEditingController> fields = {
    'userDistance': TextEditingController(text: '15'),
    'riderDistance': TextEditingController(text: '20'),
    'baseFare': TextEditingController(text: '20'),
    'peakCharge': TextEditingController(text: '10'),
    'speedCharge': TextEditingController(text: '20'),
    'distancePerKM': TextEditingController(text: '5'),
    'serviceCharge': TextEditingController(text: '5'),
    'freeDeliveryAmount': TextEditingController(),
    'slotTiming': TextEditingController(),
  };

  bool freeDelivery = false;

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
              onTap: showSlotPickerDialog,
              suffix: Icon(Icons.access_alarm, color: AppColors.secondaryColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Validation
                String? error;

                // Helper function
                bool isValidNumber(String val, int maxDigits) {
                  return RegExp(r'^\d{1,' + maxDigits.toString() + r'}$')
                      .hasMatch(val);
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

                // Format timeSlots
                List<String> formattedSlots = timeSlots.map((slot) {
                  return "${slot['start']!.format(context)} - ${slot['end']!.format(context)}";
                }).toList();

                // Prepare data
                final data = {
                  "shop_name": shopNameController.text.trim(),
                  "userDistance": fields['userDistance']!.text.trim(),
                  "riderDistance": fields['riderDistance']!.text.trim(),
                  "baseFare": fields['baseFare']!.text.trim(),
                  "peakCharge": fields['peakCharge']!.text.trim(),
                  "speedCharge": fields['speedCharge']!.text.trim(),
                  "distancePerKM": fields['distancePerKM']!.text.trim(),
                  "serviceCharge": fields['serviceCharge']!.text.trim(),
                  "freeDelivery": freeDelivery,
                  "freeDeliveryAmount":
                      fields['freeDeliveryAmount']!.text.trim(),
                  "slotTiming": formattedSlots,
                  "createdAt": FieldValue.serverTimestamp(),
                  "updatedAt": FieldValue.serverTimestamp(),
                };

                final FirebaseFirestore firestore = FirebaseFirestore.instance;

                try {
                  // Check which collection has this shopId
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
