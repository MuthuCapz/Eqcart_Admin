import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'coupon.dart';
import 'edit_coupon_page.dart';
import '../utils/colors.dart';

class CreatedCouponsList extends StatelessWidget {
  const CreatedCouponsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No coupons created yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              try {
                final coupon =
                    Coupon.fromJson(doc.data() as Map<String, dynamic>);

                if (coupon.code == 'INVALID') return const SizedBox.shrink();

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white,
                  shadowColor: AppColors.secondaryColor.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondaryColor,
                      child: Text(
                        coupon.code.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${coupon.code.toUpperCase()} - ${coupon.discount.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.description,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${coupon.validFrom.toLocal().toString().split(' ')[0]} - ${coupon.validTo.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: AppColors.primaryColor),
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
              } catch (e) {
                debugPrint('Error displaying coupon ${doc.id}: $e');
                return ListTile(
                  title: const Text('Invalid coupon'),
                  subtitle: Text('ID: ${doc.id}'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
