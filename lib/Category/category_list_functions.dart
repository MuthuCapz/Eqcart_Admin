import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';

void checkShopIdExists(
  String shopId, {
  required Function(String?) onCollectionValidated,
}) async {
  final ownShopsRef =
      FirebaseFirestore.instance.collection('own_shops_categories').doc(shopId);
  final shopsRef =
      FirebaseFirestore.instance.collection('shops_categories').doc(shopId);

  final ownShopsDoc = await ownShopsRef.get();
  final shopsDoc = await shopsRef.get();

  if (ownShopsDoc.exists) {
    onCollectionValidated('own_shops_categories');
  } else if (shopsDoc.exists) {
    onCollectionValidated('shops_categories');
  } else {
    onCollectionValidated(null);
  }
}

void listenForCategoryUpdates(
  String collection,
  String shopId, {
  required Function(List<Map<String, dynamic>>) onUpdate,
}) {
  FirebaseFirestore.instance
      .collection(collection)
      .doc(shopId)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final updatedCategories =
          List<Map<String, dynamic>>.from(data['categories'] ?? []);
      onUpdate(updatedCategories);
    }
  });
}

void showDeleteConfirmationDialog(
  BuildContext context,
  int index,
  List<Map<String, dynamic>> categories,
  String collection,
  String shopId, {
  required Function(List<Map<String, dynamic>>) onDelete,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
            SizedBox(height: 16),
            Text(
              "Delete Category?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Are you sure you want to delete this category?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("No", style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    categories.removeAt(index);
                    await FirebaseFirestore.instance
                        .collection(collection)
                        .doc(shopId)
                        .update({'categories': categories});
                    onDelete(List.from(categories));
                  },
                  child: Text("Yes", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void showEditDialog(
  BuildContext context,
  int index,
  List<Map<String, dynamic>> categories,
  String collection,
  String shopId, {
  required Function(List<Map<String, dynamic>>) onUpdate,
}) {
  TextEditingController descriptionController =
      TextEditingController(text: categories[index]['description']);
  String imageUrl = categories[index]['image_url'];
  File? selectedImage;
  bool isSaving = false;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);
    }
  }

  Future<String> uploadImageAndReplaceOld(File file, String existingUrl) async {
    Uri uri = Uri.parse(existingUrl);
    String fileName = Uri.decodeFull(uri.pathSegments.last);
    String storagePath = fileName.contains("categories/")
        ? fileName.split("categories/").last
        : fileName;

    Reference storageRef =
        FirebaseStorage.instance.ref().child('categories/$storagePath');
    await storageRef.putFile(file);
    return await storageRef.getDownloadURL();
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit Category",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryColor,
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    await pickImage();
                    setState(() {});
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : NetworkImage(imageUrl) as ImageProvider,
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.secondaryColor,
                        child: Icon(Icons.edit, size: 16, color: Colors.white),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: "Enter category description",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setState(() => isSaving = true);
                              String updatedDesc =
                                  descriptionController.text.trim();

                              try {
                                if (selectedImage != null) {
                                  imageUrl = await uploadImageAndReplaceOld(
                                      selectedImage!, imageUrl);
                                }

                                categories[index]['image_url'] = imageUrl;
                                categories[index]['description'] = updatedDesc;
                                categories[index]['updateDateTime'] =
                                    DateTime.now();

                                await FirebaseFirestore.instance
                                    .collection(collection)
                                    .doc(shopId)
                                    .update({'categories': categories});

                                onUpdate(List.from(categories));
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Update failed: $e")),
                                );
                                setState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: isSaving
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Save",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
