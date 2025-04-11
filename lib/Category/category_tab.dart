import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'category_list_functions.dart';
import 'category_products_page.dart';
import 'category_search_bar.dart';

class CategoryTab extends StatelessWidget {
  final bool isChecking;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> filteredCategories;
  final TextEditingController searchController;
  final String shopId;
  final String? validCollection;
  final Function(List<Map<String, dynamic>>) onUpdate;

  const CategoryTab({
    super.key,
    required this.isChecking,
    required this.categories,
    required this.filteredCategories,
    required this.searchController,
    required this.shopId,
    required this.validCollection,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return isChecking
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              CategorySearchBar(
                controller: searchController,
                onChanged: (query) {
                  final lowerQuery = query.toLowerCase();
                  onUpdate(categories.where((category) {
                    final name = category['category_name']?.toLowerCase() ?? '';
                    return name.contains(lowerQuery);
                  }).toList());
                },
              ),
              Expanded(
                child: filteredCategories.isEmpty
                    ? const Center(child: Text("No categories found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryProductsPage(
                                    shopId: shopId,
                                    categoryName: category['category_name'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
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
                                  const SizedBox(width: 12),
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
                                            color: AppColors.secondaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: AppColors.secondaryColor),
                                        onPressed: () => showEditDialog(
                                          context,
                                          index,
                                          filteredCategories,
                                          validCollection!,
                                          shopId,
                                          onUpdate: (updatedList) =>
                                              onUpdate(updatedList),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            showDeleteConfirmationDialog(
                                          context,
                                          index,
                                          filteredCategories,
                                          validCollection!,
                                          shopId,
                                          onDelete: (updatedList) =>
                                              onUpdate(updatedList),
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
              ),
            ],
          );
  }
}
