import 'package:flutter/material.dart';
import '../Product/all_products_page.dart';
import '../utils/colors.dart';
import 'category_list_functions.dart';
import 'category_products_page.dart';

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
    checkShopIdExists(widget.shopId, onCollectionValidated: (collection) {
      validCollection = collection;
      if (validCollection != null) {
        listenForCategoryUpdates(
          validCollection!,
          widget.shopId,
          onUpdate: (updatedCategories) {
            setState(() {
              categories = updatedCategories;
              isChecking = false;
            });
          },
        );
      } else {
        setState(() {
          isChecking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text('Shop Management', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.secondaryColor,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.secondaryColor,
              child: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    child: Text(
                      'Category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'All Product',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // -------- Category Tab -------- //
                  isChecking
                      ? Center(child: CircularProgressIndicator())
                      : categories.isEmpty
                          ? Center(child: Text("No categories found"))
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryProductsPage(
                                          shopId: widget.shopId,
                                          categoryName:
                                              category['category_name'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
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
                                        ClipOval(
                                          child: Image.network(
                                            category['image_url'],
                                            height: 60,
                                            width: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category['category_name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.secondaryColor,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                category['description'] ?? '',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit,
                                                  color:
                                                      AppColors.secondaryColor),
                                              onPressed: () => showEditDialog(
                                                context,
                                                index,
                                                categories,
                                                validCollection!,
                                                widget.shopId,
                                                onUpdate: (updatedList) =>
                                                    setState(() => categories =
                                                        updatedList),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  showDeleteConfirmationDialog(
                                                context,
                                                index,
                                                categories,
                                                validCollection!,
                                                widget.shopId,
                                                onDelete: (updatedList) =>
                                                    setState(() => categories =
                                                        updatedList),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                  // -------- All Product Tab -------- //
                  AllProductsPage(shopId: widget.shopId),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
