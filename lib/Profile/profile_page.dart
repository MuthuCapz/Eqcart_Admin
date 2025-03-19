import 'package:eqcart_admin/start_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../utils/colors.dart';
import '../Firebase_Service/firebase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var auth = FirebaseService.auth;
  var firestore = FirebaseService.firestore;

  Future<void> showLogoutConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text("Logout",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to logout?",
              style: TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No",
                  style: TextStyle(fontSize: 18, color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => StartPage()));
              },
              child: Text("Yes",
                  style: TextStyle(fontSize: 18, color: Colors.green[900])),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = auth.currentUser;
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('admins').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String profilePicUrl = userData['profile'] ?? '';
          String name = userData['username'] ?? 'N/A';
          String email = userData['email'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const SizedBox(height: 60),
                  buildProfileField('Name', name),
                  buildProfileField('Email', email),
                  const SizedBox(height: 100),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => showLogoutConfirmationDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("Logout",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildProfileField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    ),
  );
}

Widget buildProfilePicture(String? profilePicUrl, VoidCallback onTap) {
  return Center(
    child: Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
              ? NetworkImage(profilePicUrl)
              : null,
          child: profilePicUrl == null || profilePicUrl.isEmpty
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onTap,
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white,
              child: Icon(Icons.edit, size: 18, color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    ),
  );
}
