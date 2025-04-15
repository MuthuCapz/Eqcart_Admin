import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'main_category_functions.dart';

class MainCategoryPage extends StatefulWidget {
  const MainCategoryPage({super.key});

  @override
  State<MainCategoryPage> createState() => _MainCategoryPageState();
}

class _MainCategoryPageState extends State<MainCategoryPage> {
  final controller = MainCategoryController();
  File? _selectedImage;
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _onImagePicked(File file) {
    setState(() {
      _selectedImage = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabel("Category Name"),
              buildTextFormField(
                controller.categoryNameController,
                hintText: "Enter category name",
                maxLength: 30,
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Please enter a category name"
                    : null,
              ),
              SizedBox(height: 16),
              buildLabel("Category Description (Optional)"),
              buildTextFormField(
                controller.headerDescriptionController,
                hintText: "Tell customers what this category is about...",
                maxLines: 5,
                maxLength: 150,
              ),
              SizedBox(height: 16),
              buildLabel("Category Offer (Optional)"),
              buildTextFormField(
                controller.categoryOfferController,
                hintText: "e.g. Up to 60%, 20 mins delivery, etc.",
                maxLength: 50,
              ),
              SizedBox(height: 16),
              buildLabel("Category Image"),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => controller.pickImage(context, _onImagePicked),
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
                  onPressed: _isLoading
                      ? null
                      : () => controller.submitForm(
                          context, _setLoading, _selectedImage),
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

  Widget buildLabel(String text) {
    return Text(text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget buildTextFormField(
    TextEditingController controller, {
    required String hintText,
    int maxLength = 100,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
        ),
      ],
    );
  }
}
