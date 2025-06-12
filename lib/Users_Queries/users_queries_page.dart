import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/colors.dart';

class UsersQueriesPage extends StatelessWidget {
  const UsersQueriesPage({super.key});

  Future<void> sendEmailToUser(String queryId, String email) async {
    final url = Uri.parse(
        'https://<your-api-endpoint>/send-email'); // Replace with your backend endpoint
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'queryId': queryId, 'email': email}),
      );
      if (response.statusCode == 200) {
        // Update Firestore to confirm email was sent
        await FirebaseFirestore.instance
            .collection('user_queries')
            .doc(queryId)
            .update({
          'emailSent': true,
        });
      } else {
        throw Exception('Failed to send email');
      }
    } catch (e) {
      print('Email sending error: $e');
    }
  }

  void launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title:
            const Text('User Queries', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('user_queries').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("No queries found",
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final queryId = docs[index].id;

              return Card(
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${data['userName'] ?? ''}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("Email: ${data['email']}",
                          style: const TextStyle(color: Colors.white70)),
                      Text("Phone: ${data['phone']}",
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text("Message: ${data['message']}",
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryColor),
                            icon: const Icon(Icons.email),
                            label: const Text("Send Email"),
                            onPressed: () async {
                              await sendEmailToUser(queryId, data['email']);
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            icon: const Icon(Icons.phone),
                            label: const Text("Call"),
                            onPressed: () => launchPhone(data['phone']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            data['emailSent'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: data['emailSent'] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            data['emailSent'] == true
                                ? "Email sent"
                                : "Email not sent",
                            style: TextStyle(
                                color: data['emailSent'] == true
                                    ? Colors.green
                                    : Colors.red),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
