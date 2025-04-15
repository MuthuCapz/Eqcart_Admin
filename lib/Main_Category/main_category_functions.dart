import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MainCategoryController {
  final formKey = GlobalKey<FormState>();
  final categoryNameController = TextEditingController();
  final headerDescriptionController = TextEditingController();
  final categoryOfferController = TextEditingController();
  File? selectedImage;
  bool isLoading = false;

  Future<void> pickImage(
      BuildContext context, Function(File) onImagePicked) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        onImagePicked(File(pickedFile.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No image selected")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: ${e.toString()}")),
      );
    }
  }

  Future<String> uploadImage(File imageFile) async {
    String fileName = Uuid().v4();
    Reference storageRef =
        FirebaseStorage.instance.ref().child('main_categories/$fileName');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> submitForm(BuildContext context, Function(bool) onLoadingChange,
      File? selectedImage) async {
    if (!formKey.currentState!.validate()) return;

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a category image")),
      );
      return;
    }

    onLoadingChange(true);
    try {
      String imageUrl = await uploadImage(selectedImage);
      String categoryId = Uuid().v4();
      Timestamp currentTime = Timestamp.now();

      final CollectionReference mainCategoryCollection =
          FirebaseFirestore.instance.collection('main_categories');

      final QuerySnapshot existingDocs =
          await mainCategoryCollection.limit(1).get();

      DocumentReference targetDoc;

      if (existingDocs.docs.isEmpty) {
        targetDoc = await mainCategoryCollection.add({'categories': []});
      } else {
        targetDoc = existingDocs.docs.first.reference;
      }

      Map<String, dynamic> newCategory = {
        'category_id': categoryId,
        'category_name': categoryNameController.text.trim(),
        'description': headerDescriptionController.text.trim(),
        'category_offer': categoryOfferController.text.trim(),
        'image_url': imageUrl,
        'createDateTime': currentTime,
        'updateDateTime': currentTime,
      };

      await targetDoc.set({
        'categories': FieldValue.arrayUnion([newCategory])
      }, SetOptions(merge: true));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving category: ${e.toString()}")),
      );
    } finally {
      onLoadingChange(false);
    }
  }
}
