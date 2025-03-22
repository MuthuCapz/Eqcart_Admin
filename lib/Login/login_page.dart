import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../utils/colors.dart';

import '../Home/home_page.dart';
import '../encryption_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User canceled sign-in
      }

      String googleEmail = googleUser.email;
      String googleName = googleUser.displayName ?? "Unknown";
      String googleProfile = googleUser.photoUrl ?? "";

      // Check if email exists in Firestore admin credentials
      DocumentSnapshot adminSnapshot =
          await _firestore.collection("config").doc("admin_credential").get();

      if (adminSnapshot.exists) {
        String? storedAdminEmail = adminSnapshot["gmail"];

        if (storedAdminEmail == googleEmail) {
          // Authenticate user with Firebase
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          User? user = userCredential.user;
          if (user != null) {
            await _storeUserData(
                user.uid, googleEmail, googleName, googleProfile);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Access denied! Not an authorized admin.")),
          );
        }
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
    }
  }

  Future<void> signInWithEmailPassword() async {
    String enteredEmail = emailController.text.trim();
    String enteredPassword = passwordController.text;

    try {
      // 🔍 Check if email exists in Firebase Authentication
      List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(enteredEmail);
      if (signInMethods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No account found with this email!")),
        );
        return;
      }

      // 🔑 Retrieve stored encrypted password from Firestore
      DocumentSnapshot userSnapshot =
          await _firestore.collection("config").doc("admin_credential").get();

      if (userSnapshot.exists) {
        String? storedEmail = userSnapshot["email"];
        String? encryptedPassword = userSnapshot["password"];

        if (storedEmail == enteredEmail && encryptedPassword != null) {
          String decryptedPassword =
              EncryptionHelper.decryptData(encryptedPassword);

          if (enteredPassword == decryptedPassword) {
            // Authenticate user with Firebase Auth
            UserCredential userCredential =
                await _auth.signInWithEmailAndPassword(
              email: enteredEmail,
              password: enteredPassword,
            );

            User? user = userCredential.user;
            if (user != null) {
              await _storeUserData(user.uid, enteredEmail, "Admin User", "");

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Invalid password!")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid email!")),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _storeUserData(
      String uid, String email, String username, String profileUrl) async {
    try {
      DocumentReference userDoc = _firestore.collection("admins").doc(uid);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        // Update existing user (updateDateandTime)
        await userDoc.update({
          "updateDateandTime": DateTime.now().toIso8601String(),
        });
      } else {
        // Store new user data
        await userDoc.set({
          "email": email,
          "username": username,
          "profile": profileUrl,
          "createDateandTime": DateTime.now().toIso8601String(),
          "updateDateandTime": DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print("Firestore Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Login"),
        backgroundColor: AppColors.backgroundColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signInWithEmailPassword,
              child: Text("Login with Email/Password"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: Text("Login with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
