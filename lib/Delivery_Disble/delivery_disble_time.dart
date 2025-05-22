import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'delivery_disable_time_ui.dart';

class DeliveryDisableTime extends StatefulWidget {
  const DeliveryDisableTime({super.key});

  @override
  State<DeliveryDisableTime> createState() => _DeliveryDisableTimeState();
}

class _DeliveryDisableTimeState extends State<DeliveryDisableTime> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final String docId = 'delivery_time';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() {
    FirebaseFirestore.instance
        .collection('deliver_disble_time')
        .doc(docId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          if (data['start_time'] != null) {
            final parts = (data['start_time'] as String).split(':');
            startTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          if (data['end_time'] != null) {
            final parts = (data['end_time'] as String).split(':');
            endTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          setState(() {});
        }
      }
    });
  }

  Future<void> pickTime(bool isStart) async {
    final TimeOfDay initialTime =
        isStart ? (startTime ?? TimeOfDay.now()) : (endTime ?? TimeOfDay.now());

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  void saveTime() async {
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end time')),
      );
      return;
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final diff = (endMinutes - startMinutes + 1440) % 1440;

    if (diff < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum gap must be 5 hours')),
      );
      return;
    }

    final docRef =
        FirebaseFirestore.instance.collection('deliver_disble_time').doc(docId);

    final now = DateTime.now();
    final doc = await docRef.get();
    final isFirst = !doc.exists;

    await docRef.set({
      'start_time':
          '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}',
      if (isFirst) 'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryDisableTimeUI(
      startTime: startTime,
      endTime: endTime,
      formatTime: formatTime,
      onPickTime: pickTime,
      onSave: saveTime,
    );
  }
}
