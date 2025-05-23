import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../../utils/colors.dart';

Future<void> fetchShopNameForSettings(
    String shopId, TextEditingController shopNameController) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String defaultName = "Eqcart Mart";
  String? shopName;
  try {
    // First check in 'shops'
    final shopDoc = await firestore.collection('shops').doc(shopId).get();
    if (shopDoc.exists && shopDoc.data()!.containsKey('shop_name')) {
      shopName = shopDoc['shop_name'];
    } else {
      // Then check in 'own_shops'
      final ownShopDoc =
          await firestore.collection('own_shops').doc(shopId).get();
      if (ownShopDoc.exists && ownShopDoc.data()!.containsKey('shop_name')) {
        shopName = ownShopDoc['shop_name'];
      }
    }
    shopNameController.text = shopName ?? defaultName;
  } catch (e) {
    shopNameController.text = defaultName;
  }
}

Future<List<Map<String, TimeOfDay>>> showSlotPickerDialog(
    BuildContext context, List<Map<String, TimeOfDay>> currentSlots) async {
  // If there are existing slots, use them; otherwise initialize with defaults.
  List<Map<String, TimeOfDay>> timeSlots = currentSlots.isNotEmpty
      ? List.from(currentSlots)
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

  bool isTimeWithinRange(TimeOfDay time, TimeOfDay minTime, TimeOfDay maxTime) {
    final int timeInMinutes = time.hour * 60 + time.minute;
    final int minTimeInMinutes = minTime.hour * 60 + minTime.minute;
    final int maxTimeInMinutes = maxTime.hour * 60 + maxTime.minute;
    return timeInMinutes >= minTimeInMinutes &&
        timeInMinutes <= maxTimeInMinutes;
  }

  // Show a dialog that allows picking and editing time slots.
  List<Map<String, TimeOfDay>> result = await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime(int index, bool isStart) async {
            final initialTime =
                isStart ? timeSlots[index]['start']! : timeSlots[index]['end']!;
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (picked != null && isTimeWithinRange(picked, minTime, maxTime)) {
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            onPressed: () {
                              setState(() {
                                timeSlots.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                        onPressed: () => Navigator.pop(context,
                            currentSlots), // return unchanged on Cancel
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, timeSlots);
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
  ) as List<Map<String, TimeOfDay>>;

  return result;
}
