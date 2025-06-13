import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eqcart_admin/Users_Queries/users_queries_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Riders_Info/ImageViewerPage.dart';
import '../utils/colors.dart';

class QueryCard extends StatelessWidget {
  final QueryDocumentSnapshot queryDoc;

  const QueryCard({super.key, required this.queryDoc});

  void launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> sendEmailGmailOnly(
      BuildContext context, String email, String queryId) async {
    final String subject = Uri.encodeComponent('Welcome Eqcart');
    final String body = Uri.encodeComponent(
        '''Thank you for reaching out. You’ll hear from us within 24–48 hours.\n\nRegards,\nEqCart Shopping''');
    final Uri mailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");

    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: mailUri.toString(),
      package: 'com.google.android.gm',
    );

    try {
      await intent.launch();
      await FirebaseFirestore.instance
          .collection('user_queries')
          .doc(queryId)
          .update({'emailSent': true});
    } catch (_) {
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
        await FirebaseFirestore.instance
            .collection('user_queries')
            .doc(queryId)
            .update({'emailSent': true});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No email app available")),
        );
      }
    }
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('user_queries')
        .doc(id)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final data = queryDoc.data() as Map<String, dynamic>;
    final queryId = queryDoc.id;
    final status = (data['status'] ?? 'Active') as String;

    bool isClosed = status == 'Closed';

    return Opacity(
      opacity: isClosed ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondaryColor,
                    child: Text(
                      data['userName']?[0].toUpperCase() ?? '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['userName'] ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(data['email'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54)),
                        Text(data['phone'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text("Query ID: ${data['query_id'] ?? queryId}",
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                                fontStyle: FontStyle.italic)),
                        Text("Status: $status",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'Closed'
                                    ? Colors.red
                                    : AppColors.primaryColor)),
                      ],
                    ),
                  ),
                  if (data['imageUrl'] != null &&
                      data['imageUrl'].toString().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ImageViewerPage(imageUrl: data['imageUrl']),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              /// Message Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(data['message'] ?? '',
                    style:
                        const TextStyle(color: Colors.black87, fontSize: 15)),
              ),
              const SizedBox(height: 16),

              /// Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text("Send Email"),
                      onPressed: () async {
                        await sendEmailGmailOnly(
                            context, data['email'], queryId);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone),
                      label: const Text("Call"),
                      onPressed: () => launchPhone(data['phone']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              StatusFlowWidget(
                currentStatus: data['status'] ?? '',
                onStatusChange: (newStatus) async {
                  await FirebaseFirestore.instance
                      .collection('user_queries')
                      .doc(queryId)
                      .update({'status': newStatus});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
