import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eqcart_admin/Product/product_listview_ui.dart';
import 'package:flutter/material.dart';

class AllProductsPage extends StatefulWidget {
  final String shopId;

  const AllProductsPage({required this.shopId, super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  Map<String, bool> variantVisibility = {};
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchAllProducts();
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    final productCollections = ['shops_products', 'own_shops_products'];
    List<Map<String, dynamic>> allProducts = [];

    for (String productCollection in productCollections) {
      final shopRef = FirebaseFirestore.instance
          .collection(productCollection)
          .doc(widget.shopId);

      List<String> categories = await getCategoryNames();

      final futures = categories.map((category) async {
        final snapshot = await shopRef.collection(category).get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['category_name'] = category;
          data['doc_id'] = doc.id;
          return data;
        }).toList();
      });

      final results = await Future.wait(futures);
      allProducts.addAll(results.expand((e) => e));
    }

    return allProducts;
  }

  Future<List<String>> getCategoryNames() async {
    final collections = ['shops_categories', 'own_shops_categories'];
    List<String> categoryNames = [];

    for (String collection in collections) {
      final docRef =
          FirebaseFirestore.instance.collection(collection).doc(widget.shopId);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      final categories = data?['categories'] as List<dynamic>?;

      if (categories != null) {
        for (var category in categories) {
          final name = category['category_name'];
          if (name is String) categoryNames.add(name);
        }
      }
    }

    return categoryNames;
  }

  Future<void> refreshProducts() async {
    setState(() {
      _productsFuture = fetchAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('No products found.'));

        final products = snapshot.data!;

        return RefreshIndicator(
          onRefresh: refreshProducts,
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index];
              final docId = data['doc_id'];

              return ProductTile(
                data: data,
                showVariants: variantVisibility[docId] ?? false,
                onToggleVariants: () {
                  setState(() {
                    variantVisibility[docId] =
                        !(variantVisibility[docId] ?? false);
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}
