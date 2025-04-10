import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final String validCollection;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.validCollection,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  late TextEditingController discountController;

  late String imageUrl;
  late int stockStatus;
  late List<Map<String, dynamic>> variants;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    nameController = TextEditingController(text: p['product_name']);
    descController = TextEditingController(text: p['description']);
    priceController =
        TextEditingController(text: p['product_price'].toString());
    weightController =
        TextEditingController(text: p['product_weight'].toString());
    discountController = TextEditingController(text: p['discount'].toString());
    imageUrl = p['image_url'] ?? '';
    stockStatus = p['stock'] == 0 ? 0 : 1;
    variants = List<Map<String, dynamic>>.from(p['variants'] ?? []);
  }

  Future<String?> uploadImageToStorage(XFile imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await storageRef.putData(await imageFile.readAsBytes());
    return await uploadTask.ref.getDownloadURL();
  }

  void saveProduct() async {
    final updatedData = {
      'product_name': nameController.text,
      'description': descController.text,
      'product_price': double.tryParse(priceController.text) ?? 0,
      'product_weight': weightController.text,
      'stock': stockStatus,
      'discount': int.tryParse(discountController.text) ?? 0,
      'image_url': imageUrl,
      'variants': variants,
    };

    await FirebaseFirestore.instance
        .collection(widget.validCollection)
        .doc(widget.product['shop_id'])
        .collection(widget.product['category'])
        .doc(widget.product['sku_id'])
        .update(updatedData);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.green),
          const SizedBox(width: 8),
          Text("Edit Product", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  final url = await uploadImageToStorage(picked);
                  if (url != null) {
                    setState(() => imageUrl = url);
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, height: 120)
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(Icons.image, size: 40),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(nameController, "Product Name"),
            _buildTextField(descController, "Description"),
            _buildTextField(priceController, "Price", TextInputType.number),
            _buildTextField(weightController, "Weight"),
            _buildDropdownStock(),
            _buildTextField(
                discountController, "Discount", TextInputType.number),
            const Divider(height: 24),
            Row(
              children: const [
                Icon(Icons.list_alt_rounded, color: Colors.orange),
                SizedBox(width: 6),
                Text("Variants", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...variants.asMap().entries.map((entry) {
              int index = entry.key;
              var variant = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildVariantField(variant, 'volume', 'Volume'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVariantField(variant, 'price', 'Price',
                                isNumber: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildVariantField(variant, 'mrp', 'MRP',
                                isNumber: true),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: variant['stock'] == 0
                                  ? 'Outstock'
                                  : 'Instock',
                              decoration: InputDecoration(labelText: 'Stock'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Instock', child: Text("Instock")),
                                DropdownMenuItem(
                                    value: 'Outstock', child: Text("Outstock")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  variant['stock'] =
                                      value == 'Outstock' ? 0 : 1;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => variants.removeAt(index)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    variants.add(
                        {'volume': '', 'price': 0.0, 'mrp': 0.0, 'stock': 0});
                  });
                },
                icon: Icon(Icons.add_circle_outline, color: Colors.green),
                label: Text("Add Variant"),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.black))),
        ElevatedButton.icon(
          onPressed: saveProduct,
          icon: const Icon(Icons.save, color: Colors.white),
          label: Text("Save",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildVariantField(
      Map<String, dynamic> variant, String key, String label,
      {bool isNumber = false}) {
    return TextFormField(
      initialValue: variant[key].toString(),
      decoration:
          InputDecoration(labelText: label, border: OutlineInputBorder()),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: (v) => variant[key] = isNumber ? double.tryParse(v) ?? 0.0 : v,
    );
  }

  Widget _buildDropdownStock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<int>(
        value: stockStatus,
        items: const [
          DropdownMenuItem(value: 1, child: Text("In Stock")),
          DropdownMenuItem(value: 0, child: Text("Out of Stock")),
        ],
        onChanged: (val) => setState(() => stockStatus = val ?? 1),
        decoration: InputDecoration(
          labelText: 'Stock Status',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
