import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/colors.dart';
import 'ImageViewerPage.dart';

class RiderDetailPage extends StatefulWidget {
  final String riderId;

  const RiderDetailPage({super.key, required this.riderId});

  @override
  State<RiderDetailPage> createState() => _RiderDetailPageState();
}

class _RiderDetailPageState extends State<RiderDetailPage> {
  bool calledRider = false;
  bool emailedRider = false;
  bool loading = false;

  void approveRider() async {
    setState(() => loading = true);
    await FirebaseFirestore.instance
        .collection('riders_info')
        .doc(widget.riderId)
        .update({'approval_status': 'approved'});

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rider approved successfully')),
    );
    Navigator.pop(context);
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot make phone call")));
    }
  }

  void _sendEmailGmailOnly(String email) async {
    final String subject = Uri.encodeComponent('Eqcart Rider Verification');
    final String body = Uri.encodeComponent(
        '''Hello, this is an admin confirmation mail regarding your rider registration. Your registration process is fully processed. Welcome to EqCart delivery journey.

If any further details are needed from EqCart's side, we will immediately call or email you, so please stay active.

Regards,
EqCart Admin''');
    final Uri mailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");

    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: mailUri.toString(),
      package: 'com.google.android.gm',
    );

    try {
      await intent.launch();
    } catch (e) {
      debugPrint('Gmail not available, falling back to mailto');
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No email app available")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Rider Details"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('riders_info')
            .doc(widget.riderId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(data['profile_picture']),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detailRow("Name", data['name']),
                        detailRow("Vehicle No", data['vehicle_no']),
                        detailRow("Approval", data['approval_status']),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: detailRow("Phone", data['phone']),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.phone, color: Colors.green),
                              onPressed: () => _makePhoneCall(data['phone']),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: detailRow("Email", data['email']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.email, color: Colors.blue),
                              onPressed: () =>
                                  _sendEmailGmailOnly(data['email']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageViewerPage(imageUrl: data['license_url']),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: const Text(
                            "License Image",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          child: Image.network(
                            data['license_url'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (data['approval_status'] != 'approved') ...[
                  CheckboxListTile(
                    title: const Text("I have called the rider"),
                    value: calledRider,
                    onChanged: (val) => setState(() => calledRider = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text("I have emailed the rider"),
                    value: emailedRider,
                    onChanged: (val) => setState(() => emailedRider = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (calledRider && emailedRider && !loading)
                        ? approveRider
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Approve Rider",
                            style: TextStyle(fontSize: 16)),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
