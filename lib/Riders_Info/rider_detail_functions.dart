import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ImageViewerPage.dart';

void openLicenseImage(BuildContext context, String url) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ImageViewerPage(imageUrl: url),
    ),
  );
}

Widget infoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$label: $value",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

Widget phoneRow(BuildContext context, String phone) {
  return Row(
    children: [
      infoRow(Icons.phone, "Phone", phone),
      IconButton(
        icon: const Icon(Icons.call, color: Colors.green),
        onPressed: () => makePhoneCall(context, phone),
      ),
    ],
  );
}

Widget emailRow(BuildContext context, String email) {
  return Row(
    children: [
      infoRow(Icons.email, "Email", email),
      IconButton(
        icon: const Icon(Icons.email, color: Colors.blue),
        onPressed: () => sendEmailGmailOnly(context, email),
      ),
    ],
  );
}

Future<void> approveRider(
  BuildContext context,
  String riderId,
  VoidCallback onStart,
  VoidCallback onComplete,
) async {
  onStart();
  await FirebaseFirestore.instance
      .collection('riders_info')
      .doc(riderId)
      .update({'approval_status': 'approved'});

  onComplete();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Rider approved successfully')),
  );
  Navigator.pop(context);
}

Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cannot make phone call")),
    );
  }
}

Future<void> sendEmailGmailOnly(BuildContext context, String email) async {
  final String subject = Uri.encodeComponent('Eqcart Rider Verification');
  final String body = Uri.encodeComponent('''
Hello, this is an admin confirmation mail regarding your rider registration. Your registration process is fully processed. Welcome to EqCart delivery journey.

If any further details are needed from EqCart's side, we will immediately call or email you, so please stay active.

Regards,
EqCart Admin
''');
  final Uri mailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");

  final intent = AndroidIntent(
    action: 'android.intent.action.SENDTO',
    data: mailUri.toString(),
    package: 'com.google.android.gm',
  );

  try {
    await intent.launch();
  } catch (e) {
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No email app available")),
      );
    }
  }
}
