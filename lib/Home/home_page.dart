import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../Profile/profile_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Home Page"),
        backgroundColor: AppColors.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.menu), // Three-dot menu icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage()), // Navigate to ProfilePage
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text("Admin Home Page", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
