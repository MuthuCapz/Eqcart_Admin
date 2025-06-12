import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'coupon.dart';
import 'edit_coupon_page.dart';

class CreatedCouponsList extends StatelessWidget {
  const CreatedCouponsList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No coupons created yet.'));
        }

        final coupons = snapshot.data!.docs;

        return ListView.builder(
          itemCount: coupons.length,
          itemBuilder: (context, index) {
            final data = coupons[index].data() as Map<String, dynamic>;
            final coupon = Coupon.fromJson(data);

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                    '${coupon.code} - ${coupon.discount.toStringAsFixed(2)}%'),
                subtitle: Text(coupon.description),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditCouponPage(coupon: coupon),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
