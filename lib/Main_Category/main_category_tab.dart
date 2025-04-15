import 'package:flutter/material.dart';

import 'list_main_categories_page.dart';
import 'main_category_page.dart';

class MainCategoryTabPage extends StatelessWidget {
  const MainCategoryTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Main Categories",
              style: TextStyle(fontSize: 18, color: Colors.white)),
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Add Category"),
              Tab(text: "List Categories"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MainCategoryPage(),
            ListMainCategoriesPage(),
          ],
        ),
      ),
    );
  }
}
