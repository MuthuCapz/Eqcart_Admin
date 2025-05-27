import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import 'package:eqcart_admin/Riders_Info/rider_detail_page.dart';

class RidersInfoPage extends StatelessWidget {
  const RidersInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Riders Info"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('riders_info').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final riders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: riders.length,
            itemBuilder: (context, index) {
              final rider = riders[index];
              final name = rider['name'];
              final phone = rider['phone'];
              final status = rider['approval_status'];
              final profileUrl = rider['profile_picture'];

              final isApproved = status.toLowerCase() == "approved";

              return Opacity(
                opacity: isApproved ? 0.4 : 1.0,
                child: AbsorbPointer(
                  absorbing: isApproved,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(profileUrl),
                        backgroundColor:
                            AppColors.secondaryColor.withOpacity(0.2),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                "+91 $phone",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Status: $status",
                              style: TextStyle(
                                fontSize: 12,
                                color: isApproved
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: !isApproved
                          ? const Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.black54)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiderDetailPage(riderId: rider.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
