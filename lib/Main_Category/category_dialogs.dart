import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import '../utils/colors.dart';

Future<void> showEditCategoryDialog({
  required BuildContext context,
  required Map<String, dynamic> cat,
  required int index,
  required Function(Map<String, dynamic>) onCategoryUpdated,
}) async {
  final descController = TextEditingController(text: cat['description'] ?? '');
  final offerController =
      TextEditingController(text: cat['category_offer'] ?? '');
  String imageUrl = cat['image_url'] ?? '';
  File? newImageFile;

  final picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      newImageFile = File(picked.path);
    }
  }

  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Category"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: newImageFile != null
                        ? FileImage(newImageFile!)
                        : (imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null)
                            as ImageProvider?,
                    child: imageUrl.isEmpty && newImageFile == null
                        ? const Icon(Icons.image, size: 40)
                        : null,
                  ),
                  Positioned(
                    bottom: -10,
                    right: 0,
                    child: IconButton(
                      icon:
                          const Icon(Icons.edit, color: AppColors.primaryColor),
                      onPressed: () async {
                        await pickImage();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: cat['category_name'],
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Category Name (not editable)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: offerController,
                decoration: const InputDecoration(labelText: 'Category Offer'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close the dialog

              // Upload image if a new one is selected
              String? uploadedUrl;
              if (newImageFile != null) {
                final filename = basename(newImageFile!.path);
                final ref =
                    FirebaseStorage.instance.ref('main_categories/$filename');
                await ref.putFile(newImageFile!);
                uploadedUrl = await ref.getDownloadURL();
              }

              // Generate a timestamp for the update
              final updateTimestamp = FieldValue.serverTimestamp();

              // Prepare the updated category object (this is the array element)
              final updatedCategory = {
                'category_id': cat['category_id'], // Keep the category_id
                'category_name':
                    cat['category_name'], // Keep the original category_name
                'createDateTime':
                    cat['createDateTime'], // Keep the original createDateTime
                'description': descController.text, // Update description
                'category_offer': offerController.text, // Update category_offer
                'image_url':
                    uploadedUrl ?? imageUrl, // Update image_url if changed
              };

              // Fetch the document reference for the category
              final snapshot = await FirebaseFirestore.instance
                  .collection('main_categories')
                  .limit(1)
                  .get();

              if (snapshot.docs.isNotEmpty) {
                final docRef = snapshot.docs.first.reference;
                final categories = List<Map<String, dynamic>>.from(
                    snapshot.docs.first['categories'] ?? []);

                // Find the category index and update it
                final categoryIndex = categories.indexWhere((c) =>
                    c['category_id'] ==
                    cat['category_id']); // Use category_id to find it
                if (categoryIndex != -1) {
                  categories[categoryIndex] = updatedCategory;

                  // Update the Firestore document with the updated categories list
                  await docRef.update({
                    'categories':
                        categories, // Update the array with the new category data
                    'updateDateTime':
                        updateTimestamp, // Store the update timestamp separately
                  });

                  // Invoke the callback with the updated category
                  onCategoryUpdated(updatedCategory);
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    ),
  );
}

Future<void> showDeleteConfirmationDialog({
  required BuildContext context,
  required Map<String, dynamic> cat,
  required Function onDeleteSuccess,
}) async {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Delete Category?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to delete this category?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("No"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();

                    // Delete from Firestore
                    final snapshot = await FirebaseFirestore.instance
                        .collection('main_categories')
                        .limit(1)
                        .get();

                    if (snapshot.docs.isNotEmpty) {
                      final docRef = snapshot.docs.first.reference;
                      final categories = List<Map<String, dynamic>>.from(
                        snapshot.docs.first['categories'] ?? [],
                      );

                      categories.removeWhere(
                          (c) => c['category_name'] == cat['category_name']);

                      await docRef.update({'categories': categories});
                      onDeleteSuccess(); // Refresh UI
                    }
                  },
                  child: const Text("Yes"),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}
