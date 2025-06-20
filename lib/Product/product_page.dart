import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';

class AddProductPage extends StatefulWidget {
  final String shopId;
  AddProductPage({required this.shopId});
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

  List<String> categories = [];
  List<Map<String, dynamic>> variants = [];

  List<String> statusOptions = ['Instock', 'Outstock'];

  @override
  void initState() {
    super.initState();
    _generateSKU();
    _fetchCategories();
  }

  void _generateSKU() {
    int randomNum = Random().nextInt(900000) + 100000;
    skuController.text = 'SKU-$randomNum';
  }

  Future<void> _fetchCategories() async {
    List<String> fetchedCategories = [];

    try {
      // if shop exists in `shops_categories`
      DocumentSnapshot shopCategoriesDoc = await _firestore
          .collection('shops_categories')
          .doc(widget.shopId)
          .get();

      if (shopCategoriesDoc.exists) {
        var data = shopCategoriesDoc.data() as Map<String, dynamic>;
        if (data.containsKey('categories') && data['categories'] is List) {
          fetchedCategories = (data['categories'] as List)
              .where((category) =>
                  category is Map<String, dynamic> &&
                  category.containsKey('category_name'))
              .map((category) => category['category_name'].toString())
              .toList();
        }
      }

      // If no categories found in `shops_categories`, check `own_shops_categories`
      if (fetchedCategories.isEmpty) {
        DocumentSnapshot ownShopCategoriesDoc = await _firestore
            .collection('own_shops_categories')
            .doc(widget.shopId)
            .get();

        if (ownShopCategoriesDoc.exists) {
          var data = ownShopCategoriesDoc.data() as Map<String, dynamic>;
          if (data.containsKey('categories') && data['categories'] is List) {
            fetchedCategories = (data['categories'] as List)
                .where((category) =>
                    category is Map<String, dynamic> &&
                    category.containsKey('category_name'))
                .map((category) => category['category_name'].toString())
                .toList();
          }
        }
      }

      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
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
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a category or add a category first'),
      ));
      return;
    }

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
        'product_weight': weightController.text.trim(),
        'variants': variants,
        'category': selectedCategory,
        'description': descriptionController.text.trim(),
        'discount': double.parse(discountController.text),
        'image_url': uploadedImageUrl ?? '',
        'stock': selectedStatus,
        'createDateTime': FieldValue.serverTimestamp(),
        'updateDateTime': FieldValue.serverTimestamp(),
      };

      // Check if shopId exists in 'shops'
      DocumentSnapshot shopDoc =
          await _firestore.collection('shops').doc(widget.shopId).get();
      if (shopDoc.exists) {
        await _storeProduct('shops_products', productData);
        return;
      }

      // Check if shopId exists in 'own_shops'
      DocumentSnapshot ownShopDoc =
          await _firestore.collection('own_shops').doc(widget.shopId).get();
      if (ownShopDoc.exists) {
        await _storeProduct('own_shops_products', productData);
        return;
      }

      // If shopId is not found in either, show error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: Shop ID not found in shops or own_shops')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

// Function to store product in the correct Firestore path
  Future<void> _storeProduct(
      String collection, Map<String, dynamic> productData) async {
    String categoryId = selectedCategory ?? 'Others';

    await _firestore
        .collection(collection)
        .doc(widget.shopId)
        .set({}, SetOptions(merge: true)); // Ensure shopId exists

    await _firestore
        .collection(collection)
        .doc(widget.shopId)
        .collection(categoryId)
        .doc(productData['sku_id'])
        .set(productData);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Product added successfully')));

    _resetForm();
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
                _buildTextField('Product Price', priceController),
                _buildTextField(
                    'Product Weight (e.g. 500ml or 1kg)', weightController),
                _buildDropdown('Category', categories, selectedCategory,
                    (value) => setState(() => selectedCategory = value)),
                _buildTextField('Product Description', descriptionController,
                    maxLines: 3),
                _buildDropdown('Stock', statusOptions, selectedStatus,
                    (value) => setState(() => selectedStatus = value)),
                _buildTextField('Discount', discountController, isNumber: true),
                SizedBox(height: 10),
                Text("Product Variants",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...variants.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> variant = entry.value;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _variantTextField(
                                'Volume', (val) => variant['volume'] = val),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _variantTextField(
                                'Price',
                                (val) => variant['price'] =
                                    double.tryParse(val) ?? 0),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _variantTextField(
                                'MRP',
                                (val) =>
                                    variant['mrp'] = double.tryParse(val) ?? 0),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: variant['stock'],
                              decoration: InputDecoration(
                                labelText: 'Stock',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              items: ['Instock', 'Outstock'].map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  variant['stock'] = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select stock status' : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => variants.removeAt(index)),
                          ),
                        ],
                      ),
                      Divider(),
                    ],
                  );
                }).toList(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Variant'),
                    onPressed: () {
                      setState(() {
                        variants.add({
                          "volume": "",
                          "price": 0.0,
                          "mrp": 0.0,
                          "stock": "Instock",
                        });
                      });
                    },
                  ),
                ),
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

  Widget _variantTextField(String hint, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
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
