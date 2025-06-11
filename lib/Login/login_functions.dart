import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Home/home_page.dart';
import '../encryption_helper.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    String googleEmail = googleUser.email;
    String googleName = googleUser.displayName ?? "Unknown";
    String googleProfile = googleUser.photoUrl ?? "";

    DocumentSnapshot adminSnapshot =
        await _firestore.collection("config").doc("admin_credential").get();

    if (adminSnapshot.exists) {
      String? storedAdminEmail = adminSnapshot["gmail"];

      if (storedAdminEmail == googleEmail) {
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

Future<void> signInWithEmailPassword(
    BuildContext context, String email, String password) async {
  try {
    List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
    if (signInMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No account found with this email!")),
      );
      return;
    }

    DocumentSnapshot userSnapshot =
        await _firestore.collection("config").doc("admin_credential").get();

    if (userSnapshot.exists) {
      String? storedEmail = userSnapshot["email"];
      String? encryptedPassword = userSnapshot["password"];

      if (storedEmail == email && encryptedPassword != null) {
        String decryptedPassword =
            EncryptionHelper.decryptData(encryptedPassword);

        if (password == decryptedPassword) {
          UserCredential userCredential =
              await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          User? user = userCredential.user;
          if (user != null) {
            await _storeUserData(user.uid, email, "Admin User", "");
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
      await userDoc.update({
        "updateDateandTime": DateTime.now().toIso8601String(),
      });
    } else {
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
