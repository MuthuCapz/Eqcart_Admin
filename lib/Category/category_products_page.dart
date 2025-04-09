import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'category_product_list.dart'; // contains ProductCard

class CategoryProductsPage extends StatefulWidget {
  final String shopId;
  final String categoryName;

  const CategoryProductsPage({
    Key? key,
    required this.shopId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  String? validCollection;

  @override
  void initState() {
    super.initState();
    _checkValidCollection();
  }

  Future<void> _checkValidCollection() async {
    final shopId = widget.shopId;
    final category = widget.categoryName;

    final shopsRef =
        FirebaseFirestore.instance.collection('shops_products').doc(shopId);
    final ownRef =
        FirebaseFirestore.instance.collection('own_shops_products').doc(shopId);

    final shopsSnapshot = await shopsRef.collection(category).limit(1).get();
    if (shopsSnapshot.docs.isNotEmpty) {
      setState(() => validCollection = 'shops_products');
      return;
    }

    final ownSnapshot = await ownRef.collection(category).limit(1).get();
    if (ownSnapshot.docs.isNotEmpty) {
      setState(() => validCollection = 'own_shops_products');
      return;
    }

    setState(() => validCollection = null); // No data found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: validCollection == null
          ? Center(child: Text("No products found in ${widget.categoryName}"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(validCollection!)
                  .doc(widget.shopId)
                  .collection(widget.categoryName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child:
                          Text("No products found in ${widget.categoryName}"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ProductCard(product: data);
                  },
                );
              },
            ),
    );
  }
}
