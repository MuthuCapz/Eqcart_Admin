import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/colors.dart';
import '../shop_main_page/shop_main_page.dart';

class ViewShopPage extends StatefulWidget {
  @override
  _ViewShopPageState createState() => _ViewShopPageState();
}

class _ViewShopPageState extends State<ViewShopPage> {
  List<DocumentSnapshot> cachedShops = []; // Cache last fetched data

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<DocumentSnapshot>>.value(
      value: FirebaseFirestore.instance.collection('shops').snapshots().map(
        (snapshot) {
          List<DocumentSnapshot> docs = snapshot.docs;
          if (docs.isNotEmpty)
            cachedShops = docs; // Update cache only if new data comes
          return docs;
        },
      ).distinct(), // Prevents unnecessary rebuilds if data is unchanged
      initialData: cachedShops, // Show cached data instantly
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text('View Shop',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.secondaryColor,
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: ShopListView(),
      ),
    );
  }
}

class ShopListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> shops = Provider.of<List<DocumentSnapshot>>(context);

    if (shops.isEmpty) {
      return Center(
        child: Text('No shops found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        var shop = shops[index];
        String shopId = shop.id;
        String shopName = shop['shop_name'] ?? 'No Name';
        String ownerPhone = shop['owner_phone'] ?? 'No Phone';
        String address = shop['location']['city'] ?? 'No Address';
        bool isActive =
            shop['isActive'] ?? true; // Default to active if not set

        return ShopListItem(
          shopId: shopId,
          shopName: shopName,
          ownerPhone: ownerPhone,
          address: address,
          isActive: isActive,
        );
      },
    );
  }
}

class ShopListItem extends StatefulWidget {
  final String shopId;
  final String shopName;
  final String ownerPhone;
  final String address;
  final bool isActive;

  const ShopListItem({
    required this.shopId,
    required this.shopName,
    required this.ownerPhone,
    required this.address,
    required this.isActive,
  });

  @override
  _ShopListItemState createState() => _ShopListItemState();
}

class _ShopListItemState extends State<ShopListItem> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isActive
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopMainPage(shopId: widget.shopId),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: _isActive ? 1.0 : 0.6,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.secondaryColor.withOpacity(0.2)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with shop name and dropdown
                Row(
                  children: [
                    Icon(Icons.storefront,
                        color: AppColors.primaryColor, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.shopName,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status dropdown
                    _buildStatusDropdown(),
                  ],
                ),
                SizedBox(height: 6),

                // Owner Phone
                Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(widget.ownerPhone,
                        style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
                SizedBox(height: 6),

                // Address
                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: AppColors.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.address,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => editShop(context, widget.shopId),
                      icon: Icon(Icons.edit, size: 16, color: Colors.white),
                      label: Text('Edit',
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: AppColors.secondaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => deleteShop(widget.shopId),
                      icon: Icon(Icons.delete, size: 16, color: Colors.white),
                      label: Text('Delete',
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _isActive ? 'Active' : 'Inactive',
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(
          color: _isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _isActive = newValue == 'Active';
            // Update the status in Firestore
            FirebaseFirestore.instance
                .collection('shops')
                .doc(widget.shopId)
                .update({'isActive': _isActive});
          });
        },
        items: <String>['Active', 'Inactive']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  void editShop(BuildContext context, String shopId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditShopPage(shopId: shopId)),
    );
  }

  void deleteShop(String shopId) {
    FirebaseFirestore.instance.collection('shops').doc(shopId).delete();
  }
}

class EditShopPage extends StatelessWidget {
  final String shopId;
  EditShopPage({required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Shop")),
      body: Center(child: Text("Edit shop ID: $shopId")),
    );
  }
}
