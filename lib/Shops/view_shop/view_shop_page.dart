import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';

class ViewShopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('View Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No shops found'));
          }

          var shops = snapshot.data!.docs;

          return ListView.builder(
            itemCount: shops.length,
            itemBuilder: (context, index) {
              var shop = shops[index];
              String shopName = shop['shop_name'] ?? 'No Name';
              String ownerPhone = shop['owner_phone'] ?? 'No Phone';
              String address = shop['location']['city'] ?? 'No Address';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront,
                              color: AppColors.secondaryColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shopName,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, color: AppColors.secondaryColor),
                          SizedBox(width: 8),
                          Text(ownerPhone, style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: AppColors.secondaryColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(address,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => editShop(context, shop.id),
                            icon: Icon(Icons.edit, color: Colors.orange),
                            label: Text('Edit',
                                style: TextStyle(color: Colors.orange)),
                          ),
                          TextButton.icon(
                            onPressed: () => deleteShop(shop.id),
                            icon: Icon(Icons.delete, color: Colors.red),
                            label: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void editShop(BuildContext context, String shopId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit shop: $shopId')),
    );
  }

  void deleteShop(String shopId) {
    FirebaseFirestore.instance.collection('shops').doc(shopId).delete();
  }
}
