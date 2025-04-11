import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CSVExportService {
  static Future<void> exportToCSV(String shopId) async {
    final productCollections = ['shops_products', 'own_shops_products'];
    List<List<String>> csvData = [];

    // CSV header
    csvData.add([
      'SKU ID',
      'Product Name',
      'Category',
      'Price',
      'Weight',
      'Stock',
      'Discount',
      'Description',
      'Image URL',
      'Variants'
    ]);

    for (String productCollection in productCollections) {
      final shopRef =
          FirebaseFirestore.instance.collection(productCollection).doc(shopId);

      final categories = await _getCategoryNames(shopId);

      for (String category in categories) {
        final snapshot = await shopRef.collection(category).get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final stockStatus = _getStockStatus(data['stock']);

          String variantText = '';
          if (data['variants'] is List) {
            final List variants = data['variants'];
            variantText = variants.map((variant) {
              final volume = variant['volume'] ?? '';
              final price = variant['price'] ?? '';
              final mrp = variant['mrp'] ?? '';
              final stock = _getStockStatus(variant['stock']);
              return '($volume - ₹$price / ₹$mrp - $stock)';
            }).join(' | ');
          }

          csvData.add([
            (data['sku_id'] ?? '').toString(),
            (data['product_name'] ?? '').toString(),
            category.toString(),
            (data['product_price'] ?? '').toString(),
            (data['product_weight'] ?? '').toString(),
            stockStatus,
            (data['discount'] ?? '').toString(),
            (data['description'] ?? '').toString(),
            (data['image_url'] ?? '').toString(),
            variantText,
          ]);
        }
      }
    }

    final directory = Directory('/storage/emulated/0/Download');
    final path = '${directory.path}/all_products_export.csv';
    final file = File(path);
    await file.writeAsString(const ListToCsvConverter().convert(csvData));

    Fluttertoast.showToast(msg: 'CSV Exported to $path');
  }

  static Future<List<String>> _getCategoryNames(String shopId) async {
    final collections = ['shops_categories', 'own_shops_categories'];
    List<String> categoryNames = [];

    for (String collection in collections) {
      final docRef =
          FirebaseFirestore.instance.collection(collection).doc(shopId);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      final categories = data?['categories'] as List?;

      if (categories != null) {
        for (var category in categories) {
          final name = category['category_name'];
          if (name is String) categoryNames.add(name);
        }
      }
    }

    return categoryNames;
  }

  static String _getStockStatus(dynamic stockVal) {
    if (stockVal is num) {
      return stockVal > 0 ? 'Instock' : 'Outstock';
    } else if (stockVal is String) {
      return stockVal.toLowerCase() == 'instock' ? 'Instock' : 'Outstock';
    }
    return 'Outstock';
  }
}

// import function

class CSVImportService {
  static Future<void> importCSV(String shopId) async {
    // Pick CSV file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      Fluttertoast.showToast(msg: "No file selected.");
      return;
    }

    final file = File(result.files.first.path!);

    if (!await file.exists()) {
      Fluttertoast.showToast(msg: "Selected file does not exist.");
      return;
    }

    // Validate Firestore collection
    final validCollection = await _getValidProductCollection(shopId);
    if (validCollection == null) {
      Fluttertoast.showToast(msg: "No valid Firestore collection found.");
      return;
    }

    final csvString = await file.readAsString();
    final csvData = const CsvToListConverter().convert(csvString);

    if (csvData.length < 2) {
      Fluttertoast.showToast(msg: "CSV is empty or missing data.");
      return;
    }

    final headers = csvData[0]
        .map((e) => e.toString().toLowerCase().replaceAll(RegExp(r'\s+'), '_'))
        .toList();
    final requiredHeaders = [
      'sku_id',
      'product_name',
      'category',
      'price',
      'weight',
      'stock',
      'discount',
      'description',
      'image_url',
      'variants',
    ];

    final hasAllHeaders = requiredHeaders
        .every((header) => headers.contains(header.toLowerCase().trim()));

    if (!hasAllHeaders) {
      Fluttertoast.showToast(
          msg: "Invalid CSV format. Please select a valid file.");
      return;
    }

    // Process rows
    final dataRows = csvData.skip(1);

    for (var row in dataRows) {
      if (row.length < 10) continue; // Ensure all fields are present

      final skuId = row[0].toString();
      final productName = row[1].toString();
      final category = row[2].toString();
      final price = row[3];
      final weight = row[4];
      final stock = row[5].toString().toLowerCase() == 'instock' ? 1 : 0;
      final discount = row[6];
      final description = row[7];
      final imageUrl = row[8]?.toString() ?? '';
      final variantRaw = row[9]?.toString() ?? '';

      final variants = _parseVariants(variantRaw);

      final docRef = FirebaseFirestore.instance
          .collection(validCollection)
          .doc(shopId)
          .collection(category)
          .doc(skuId);

      await docRef.set({
        'sku_id': skuId,
        'product_name': productName,
        'product_price': price,
        'product_weight': weight,
        'stock': stock,
        'discount': discount,
        'description': description,
        'image_url': imageUrl,
        'variants': variants,
        'updateDateTime': DateTime.now(),
      }, SetOptions(merge: true));
    }

    Fluttertoast.showToast(msg: "CSV imported successfully.");
  }

  static Future<String?> _getValidProductCollection(String shopId) async {
    final categoryCollectionMap = {
      'shops_categories': 'shops_products',
      'own_shops_categories': 'own_shops_products',
    };

    for (var entry in categoryCollectionMap.entries) {
      final categoryDocRef =
          FirebaseFirestore.instance.collection(entry.key).doc(shopId);
      final categoryDoc = await categoryDocRef.get();

      if (categoryDoc.exists) {
        // Now ensure the matching products collection also exists
        final productsDocRef =
            FirebaseFirestore.instance.collection(entry.value).doc(shopId);
        final productsDoc = await productsDocRef.get();

        if (!productsDoc.exists) {
          print('Created ${entry.value}/$shopId');
        }

        return entry.value;
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> _parseVariants(String text) {
    List<Map<String, dynamic>> variants = [];

    final parts = text.split('|');
    for (var part in parts) {
      part = part.trim();
      if (part.isEmpty || !part.contains('₹')) continue;

      // Remove parentheses
      part = part.replaceAll('(', '').replaceAll(')', '');

      try {
        final regex = RegExp(r'^(.*?) - ₹(.*?) / ₹(.*?) - (.*?)$');
        final match = regex.firstMatch(part);

        if (match != null) {
          final volume = match.group(1)?.trim();
          final price = double.tryParse(match.group(2)?.trim() ?? '');
          final mrp = double.tryParse(match.group(3)?.trim() ?? '');
          final stockStr = match.group(4)?.trim().toLowerCase();
          final stock = (stockStr == 'instock') ? 1 : 0;

          variants.add({
            'volume': volume,
            'price': price,
            'mrp': mrp,
            'stock': stock,
          });
        }
      } catch (e) {
        print('Variant parse error: $e');
      }
    }

    return variants;
  }
}
