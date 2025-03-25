import 'dart:io';

import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'package:image_picker/image_picker.dart';

class AddShopPage extends StatefulWidget {
  @override
  _AddShopPageState createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, TextEditingController>> extraContacts = [];

  XFile? _logoImage;
  final ImagePicker _picker = ImagePicker();

  void _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _logoImage = pickedFile;
    });
  }

  void _addExtraContact() {
    setState(() {
      extraContacts.add({
        'contactName': TextEditingController(),
        'phone': TextEditingController(),
        'email': TextEditingController(),
      });
    });
  }

  void _removeExtraContact(int index) {
    setState(() {
      extraContacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Add New Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Shop Name', _shopNameController),
              _buildTextField('Shop Email', _shopEmailController),
              _buildTextField('Password', _passwordController,
                  obscureText: true),
              _buildTextField('Description', _descriptionController,
                  maxLines: 3),
              _buildTextField('Type', _typeController),
              _buildImagePicker(),
              _buildTextField('Location', _locationController),
              _buildTextField('Owner Name', _ownerNameController),
              _buildTextField('Phone', _phoneController),
              SizedBox(height: 10),
              Text('Additional Contacts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...extraContacts
                  .asMap()
                  .entries
                  .map((entry) =>
                      _buildExtraContactFields(entry.key, entry.value))
                  .toList(),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle,
                        color: AppColors.secondaryColor, size: 30),
                    onPressed: _addExtraContact,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
                    side: BorderSide(
                        color: AppColors.primaryColor,
                        width: 1), // Outline color
                  ),
                  child: Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.secondaryColor),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: 230,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondaryColor),
        ),
        child: _logoImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_logoImage!.path),
                    width: double.infinity, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload,
                      color: AppColors.secondaryColor, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Upload shop logo for png',
                    style: TextStyle(color: AppColors.secondaryColor),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExtraContactFields(
      int index, Map<String, TextEditingController> contact) {
    return Column(
      children: [
        _buildTextField('Contact Person Name', contact['contactName']!),
        _buildTextField('Phone', contact['phone']!),
        _buildTextField('Email', contact['email']!),
        Row(
          mainAxisSize: MainAxisSize.min, // Ensures minimal space usage
          children: [
            Text(
              "If you want to remove this contact, please click",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            SizedBox(width: 1), // Small gap between text and icon
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red, size: 30),
              onPressed: () => _removeExtraContact(index),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
