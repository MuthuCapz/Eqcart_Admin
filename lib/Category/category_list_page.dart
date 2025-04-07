import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CategoryListpage extends StatefulWidget {
  final String shopId;

  CategoryListpage({required this.shopId});

  @override
  _CategoryListpageState createState() => _CategoryListpageState();
}

class _CategoryListpageState extends State<CategoryListpage> {
  String? validCollection;
  bool isChecking = true;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    checkShopIdExists();
  }

  Future<void> checkShopIdExists() async {
    final ownShopsRef = FirebaseFirestore.instance
        .collection('own_shops_categories')
        .doc(widget.shopId);
    final shopsRef = FirebaseFirestore.instance
        .collection('shops_categories')
        .doc(widget.shopId);

    final ownShopsDoc = await ownShopsRef.get();
    final shopsDoc = await shopsRef.get();

    if (ownShopsDoc.exists) {
      validCollection = 'own_shops_categories';
    } else if (shopsDoc.exists) {
      validCollection = 'shops_categories';
    } else {
      validCollection = null;
    }

    if (validCollection != null) {
      listenForCategoryUpdates();
    } else {
      setState(() {
        isChecking = false;
      });
    }
  }

  /// Listens for real-time category updates when a change occurs
  void listenForCategoryUpdates() {
    FirebaseFirestore.instance
        .collection(validCollection!)
        .doc(widget.shopId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final updatedCategories =
            List<Map<String, dynamic>>.from(data['categories'] ?? []);

        setState(() {
          categories = updatedCategories;
          isChecking = false;
        });
      }
    });
  }

  Future<void> showDeleteConfirmationDialog(int index) async {
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
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      deleteCategory(index); // Then delete
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

  Future<void> deleteCategory(int index) async {
    try {
      categories.removeAt(index);

      await FirebaseFirestore.instance
          .collection(validCollection!)
          .doc(widget.shopId)
          .update({'categories': categories});

      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete category: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Category List', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isChecking
          ? Center(child: CircularProgressIndicator()) // Show loading only once
          : categories.isEmpty
              ? Center(
                  child: Text("No categories found")) // Show if no categories
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // Circle image
                          ClipOval(
                            child: Image.network(
                              category['image_url'],
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12),
                          // Category details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['category_name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  category['description'] ?? '',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          // Edit/Delete icons
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: AppColors.secondaryColor),
                                onPressed: () {
                                  // TODO: Handle edit
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    showDeleteConfirmationDialog(index),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
