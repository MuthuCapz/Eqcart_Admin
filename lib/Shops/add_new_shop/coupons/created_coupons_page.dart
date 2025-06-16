import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eqcart_admin/Shops/add_new_shop/coupons/shops_coupons_edit_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../Coupon_Code/edit_coupon_page.dart';
import '../../../utils/colors.dart';

class CreatedCouponsPage extends StatelessWidget {
  final String shopId;
  const CreatedCouponsPage({Key? key, required this.shopId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final couponsRef = FirebaseFirestore.instance
        .collection('coupons')
        .where('shopId', isEqualTo: shopId);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: couponsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text('No coupons created.'));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final coupon = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(coupon['couponCode'] ?? ''),
                subtitle: Text('Discount: ${coupon['discount']}%'),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopsCouponsEditPage(
                          docId: docs[index].id,
                          couponData:
                              docs[index].data() as Map<String, dynamic>,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
