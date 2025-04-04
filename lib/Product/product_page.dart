import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController skuController = TextEditingController();

  String? selectedCategory;
  String? selectedStatus;
  File? _image;
  String? imageUrl;

  List<String> categories = [
    'Electronics',
    'Clothing',
    'Food',
    'Books',
    'Others'
  ];
  List<String> statusOptions = ['Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _generateSKU();
  }

  void _generateSKU() {
    int randomNum = Random().nextInt(900000) + 100000;
    skuController.text = 'SKU-$randomNum';
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String skuId = skuController.text;
      String? uploadedImageUrl;

      if (_image != null) {
        uploadedImageUrl = await _uploadImage(skuId);
      }

      Map<String, dynamic> productData = {
        'product_name': nameController.text.trim(),
        'sku_id': skuId,
        'product_price': double.parse(priceController.text),
        'product_weight': double.parse(weightController.text),
        'category': selectedCategory,
        'description': descriptionController.text.trim(),
        'status': selectedStatus,
        'discount': double.parse(discountController.text),
        'image_url': uploadedImageUrl ?? '',
        'createDateTime': FieldValue.serverTimestamp(),
        'updateDateTime': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('products').doc(skuId).set(productData);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Product added successfully')));
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String> _uploadImage(String skuId) async {
    try {
      Reference storageRef = _storage.ref().child('product_images/$skuId.jpg');
      UploadTask uploadTask = storageRef.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Image upload failed';
    }
  }

  void _resetForm() {
    nameController.clear();
    priceController.clear();
    weightController.clear();
    descriptionController.clear();
    discountController.clear();
    selectedCategory = null;
    selectedStatus = null;
    _image = null;
    _generateSKU();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Add New Product', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Product Name', nameController),
                _buildReadOnlyField('SKU ID', skuController),
                _buildTextField('Product Price', priceController,
                    isNumber: true),
                _buildTextField('Product Weight', weightController,
                    isNumber: true),
                _buildDropdown('Category', categories, selectedCategory,
                    (value) => setState(() => selectedCategory = value)),
                _buildTextField('Product Description', descriptionController,
                    maxLines: 3),
                _buildDropdown('Status', statusOptions, selectedStatus,
                    (value) => setState(() => selectedStatus = value)),
                _buildTextField('Discount', discountController, isNumber: true),
                SizedBox(height: 10),
                _imagePickerWidget(),
                SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value!.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedItem,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedItem,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Select a $label' : null,
      ),
    );
  }

  Widget _imagePickerWidget() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _image == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                    Text('Tap to upload product image',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : Image.file(_image!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Add Product',
            style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
