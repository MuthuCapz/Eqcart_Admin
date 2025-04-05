import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../Firebase_Service/firebase_service.dart';
import '../utils/colors.dart';

class AddCategoryPage extends StatefulWidget {
  final String shopId;
  AddCategoryPage({required this.shopId});
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController categoryNameController = TextEditingController();
  TextEditingController headerDescriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No image selected")),
        );
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: ${e.toString()}")),
      );
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = Uuid().v4();
    Reference storageRef =
        FirebaseStorage.instance.ref().child('categories/$fileName');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a category image")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image
      String imageUrl = await _uploadImage(_selectedImage!);
      String categoryId = Uuid().v4();
      String? collectionPath;
      Timestamp currentTime = Timestamp.now();
      var firestore = FirebaseService.firestore;

      var results = await Future.wait([
        firestore.collection('own_shops').doc(widget.shopId).get(),
        firestore.collection('shops').doc(widget.shopId).get(),
      ]);

      DocumentSnapshot ownShopDoc = results[0];
      DocumentSnapshot shopDoc = results[1];

      if (ownShopDoc.exists) {
        collectionPath = "own_shops_categories";
      } else if (shopDoc.exists) {
        collectionPath = "shops_categories";
      }

      if (collectionPath != null) {
        DocumentReference shopCategoryRef =
            firestore.collection(collectionPath).doc(widget.shopId);

        Map<String, dynamic> newCategory = {
          'category_id': categoryId,
          'category_name': categoryNameController.text.trim(),
          'description': headerDescriptionController.text.trim(),
          'image_url': imageUrl,
          'createDateTime': currentTime,
          'updateDateTime': currentTime,
        };

        await shopCategoryRef.set({
          'categories': FieldValue.arrayUnion([newCategory])
        }, SetOptions(merge: true));

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid shop ID. Category not saved.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving category: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Add New Category",
            style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Category Name",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              TextFormField(
                controller: categoryNameController,
                decoration: InputDecoration(
                  hintText: "Enter category name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLength: 30,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a category name";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text("Category Description (Optional)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              TextFormField(
                controller: headerDescriptionController,
                decoration: InputDecoration(
                  hintText: "Tell customers what this category is about...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 5,
                maxLength: 150,
              ),
              SizedBox(height: 16),
              Text("Category Image",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Tap to upload category image",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Add Category",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
