import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../add_new_shop/MapSelectionPage.dart';
import '../add_new_shop/shop_settings/shop_settings.dart';
import '../add_new_shop/validators.dart';

class AddOwnShopPage extends StatefulWidget {
  @override
  _AddOwnShopPageState createState() => _AddOwnShopPageState();
}

class _AddOwnShopPageState extends State<AddOwnShopPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _passwordVisible = false;

  XFile? _logoImage;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, TextEditingController>> extraContacts = [];
  void _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _logoImage = pickedFile;
    });
  }

  void _selectLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapSelectionPage()),
    );

    if (selectedLocation != null) {
      setState(() {
        _locationController.text = selectedLocation;
      });
    }
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String shopId =
          FirebaseFirestore.instance.collection('own_shops').doc().id;
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      String? imageUrl;
      double? latitude;
      double? longitude;
      String? city;

      // Get latitude & longitude from address
      try {
        List<Location> locations =
            await locationFromAddress(_locationController.text);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;

          List<Placemark> placemarks =
              await placemarkFromCoordinates(latitude, longitude);
          city = placemarks.isNotEmpty ? placemarks.first.locality ?? '' : '';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch location coordinates')),
        );
        return;
      }

      // Upload Image to Firebase Storage
      if (_logoImage != null) {
        try {
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('own_shop_logos/$shopId.png');
          await storageRef.putFile(File(_logoImage!.path));
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image')),
          );
          return;
        }
      }
      // Filter only filled extra contacts
      List<Map<String, String>> filteredContacts = extraContacts
          .where((contact) =>
              contact['contactName']!.text.isNotEmpty ||
              contact['phone']!.text.isNotEmpty ||
              contact['email']!.text.isNotEmpty)
          .map((contact) => {
                'contact_person_name': contact['contactName']!.text,
                'contact_person_phone': contact['phone']!.text,
                'contact_person_email': contact['email']!.text,
              })
          .toList();

      Map<String, dynamic> shopData = {
        'shop_name': _shopNameController.text,
        'shop_email': _shopEmailController.text,
        'shop_id': shopId,
        'password': _passwordController.text,
        'description': _descriptionController.text,
        'type': _typeController.text,
        'location': _locationController.text,
        'owner_name': _ownerNameController.text,
        'owner_phone': _phoneController.text,
        'createDateTime': formattedDate,
        'updateDateTime': formattedDate,
        'shop_logo': imageUrl,
        'isActive': true,
        'location': {
          'address': _locationController.text,
          'latitude': latitude,
          'longitude': longitude,
          'city': city,
        }
      };

      // Only add 'additional_contacts' if there are valid entries
      if (filteredContacts.isNotEmpty) {
        shopData['additional_contacts'] = filteredContacts;
      }

      await FirebaseFirestore.instance
          .collection('own_shops')
          .doc(shopId)
          .set(shopData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shop added successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ShopSettings(shopId: shopId)),
      );
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Shop Name', _shopNameController,
                    validator: Validators.validateShopName),
                _buildTextField('Shop Email', _shopEmailController,
                    validator: Validators.validateEmail),
                _buildPasswordField(),
                _buildTextField('Description', _descriptionController,
                    validator: Validators.validateDescription, maxLines: 3),
                _buildTextField('Type', _typeController,
                    validator: Validators.validateType),
                _buildImagePicker(),
                _buildTextField1('Location', _locationController,
                    readOnly: true, onTap: _selectLocation),
                _buildTextField('Owner Name', _ownerNameController,
                    validator: Validators.validateShopName),
                _buildTextField('Phone', _phoneController,
                    validator: Validators.validatePhone),
                SizedBox(height: 10),
                Text('Additional Contacts',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      side: BorderSide(
                          color: AppColors.primaryColor,
                          width: 1), // Outline color
                    ),
                    child:
                        Text('Submit', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: AppColors.secondaryColor), // Label color
        border: OutlineInputBorder(
          // Full box style
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: BorderSide(color: AppColors.secondaryColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          // Highlight border on focus
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.secondaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          // Default border
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
        ),
        filled: true, // Background fill
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.secondaryColor,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
      validator: Validators.validatePassword,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.secondaryColor),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor, width: 2.0),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        validator: validator, // Now validator is supported
      ),
    );
  }

  Widget _buildTextField1(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.secondaryColor,
          ),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: onTap != null
              ? Icon(Icons.location_on, color: AppColors.secondaryColor)
              : null,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.secondaryColor,
              width: 2.0,
            ),
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
          color: Colors.white,
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
        _buildTextField(
          'Contact Person Name',
          contact['contactName']!,
          validator: (value) {
            // Validate only if any of the fields are filled
            if (value!.isNotEmpty ||
                contact['phone']!.text.isNotEmpty ||
                contact['email']!.text.isNotEmpty) {
              return Validators.validateShopName(value);
            }
            return null; // No validation if all fields are empty
          },
        ),
        _buildTextField(
          'Phone',
          contact['phone']!,
          validator: (value) {
            if (value!.isNotEmpty ||
                contact['contactName']!.text.isNotEmpty ||
                contact['email']!.text.isNotEmpty) {
              return Validators.validatePhone(value);
            }
            return null;
          },
        ),
        _buildTextField(
          'Email',
          contact['email']!,
          validator: (value) {
            if (value!.isNotEmpty ||
                contact['contactName']!.text.isNotEmpty ||
                contact['phone']!.text.isNotEmpty) {
              return Validators.validateEmail(value);
            }
            return null;
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "If you want to remove this contact, please click",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            SizedBox(width: 1),
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
