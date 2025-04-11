import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Product/all_products_page.dart';
import '../utils/colors.dart';
import 'category_list_functions.dart';
import 'category_tab.dart';
import 'csv_import_export_service.dart';

class CategoryListpage extends StatefulWidget {
  final String shopId;
  const CategoryListpage({super.key, required this.shopId});

  @override
  _CategoryListpageState createState() => _CategoryListpageState();
}

class _CategoryListpageState extends State<CategoryListpage> {
  String? validCollection;
  bool isChecking = true;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  TextEditingController searchController = TextEditingController();

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
              filteredCategories = updatedCategories;
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

  void filterCategories(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredCategories = categories.where((category) {
        final name = category['category_name']?.toLowerCase() ?? '';
        return name.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> handleExport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching products...')),
    );
    await CSVExportService.exportToCSV(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text('Shop Management',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.secondaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'export') {
                  await handleExport(context);
                } else if (value == 'import') {
                  await CSVImportService.importCSV(widget.shopId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'export', child: Text('Export')),
                const PopupMenuItem(value: 'import', child: Text('Import')),
              ],
            )
          ],
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.secondaryColor,
              child: const TabBar(
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
                  // ---------- Category Tab ---------- //

                  CategoryTab(
                    isChecking: isChecking,
                    categories: categories,
                    filteredCategories: filteredCategories,
                    searchController: searchController,
                    shopId: widget.shopId,
                    validCollection: validCollection,
                    onUpdate: (updatedList) {
                      setState(() {
                        categories = updatedList;
                        filteredCategories = updatedList
                            .where((category) =>
                                category['category_name']
                                    ?.toLowerCase()
                                    .contains(
                                        searchController.text.toLowerCase()) ??
                                false)
                            .toList();
                      });
                    },
                  ),

                  // ---------- All Products Tab ---------- //
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
