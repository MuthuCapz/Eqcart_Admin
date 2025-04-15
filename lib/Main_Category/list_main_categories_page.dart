import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'category_dialogs.dart';

class ListMainCategoriesPage extends StatefulWidget {
  const ListMainCategoriesPage({super.key});

  @override
  State<ListMainCategoriesPage> createState() => _ListMainCategoriesPageState();
}

class _ListMainCategoriesPageState extends State<ListMainCategoriesPage> {
  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('main_categories')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      final categories =
          List<Map<String, dynamic>>.from(data['categories'] ?? []);
      setState(() {
        allCategories = categories;
        filteredCategories = categories;
      });
    }
  }

  void filterCategories(String query) {
    setState(() {
      searchQuery = query;
      filteredCategories = allCategories
          .where((cat) => cat['category_name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: filterCategories,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black26),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredCategories.isEmpty
                ? const Center(child: Text('No categories found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  cat['image_url'] ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                              ),
                              if ((cat['category_offer'] ?? '').isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    cat['category_offer'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            cat['category_name'] ?? '',
                            style: const TextStyle(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(cat['description'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.secondaryColor),
                                onPressed: () {
                                  showEditCategoryDialog(
                                    context: context,
                                    cat: cat,
                                    index: index,
                                    onCategoryUpdated: (updatedCat) {
                                      setState(() {
                                        allCategories[index] = updatedCat;
                                        filteredCategories =
                                            List.from(allCategories);
                                      });
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDeleteConfirmationDialog(
                                    context: context,
                                    cat: cat,
                                    onDeleteSuccess: () =>
                                        fetchCategories(), // Refresh categories
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
