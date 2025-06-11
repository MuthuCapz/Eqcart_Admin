import 'package:flutter/material.dart';

import '../utils/colors.dart';

class OrderDetailsViewPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsViewPage({
    super.key,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List<dynamic>? ?? [];
    final status = (orderData['orderStatus'] ?? '').toString().toLowerCase();
    final isCancelled = status == 'cancelled';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            const Text("Order Details", style: TextStyle(color: Colors.white)),
      ),
      body: AbsorbPointer(
        absorbing: false, // allow click even if blurred
        child: Opacity(
          opacity: isCancelled ? 0.5 : 1.0,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(status, orderData),
              const SizedBox(height: 20),
              _buildSectionTitle(Icons.shopping_bag, "Items"),
              ...items.map((item) => _buildItemCard(item)).toList(),
              const SizedBox(height: 20),
              _buildSectionTitle(Icons.location_on, "Shipping Address"),
              _buildInfoCard(orderData['shippingAddress']),
              const SizedBox(height: 20),
              _buildSectionTitle(Icons.payment, "Payment"),
              _buildInfoCard(
                "${orderData['paymentMethod']} (${orderData['paymentStatus']})\nTip: ₹${orderData['deliveryTip'] ?? 0}",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(Icons.person, "User ID"),
              _buildInfoCard(orderData['userId']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String status, Map<String, dynamic> data) {
    final statusColor = _getStatusColor(status);
    final statusText = status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(
                "₹${data['orderTotal']}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Order ID: #${data['orderId']}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final itemMap = item as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              itemMap['imageUrl'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 60),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemMap['productName'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text("₹${itemMap['price']} × ${itemMap['quantity']}"),
                Text("${itemMap['variantWeight']}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String? value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Text(
        value ?? 'N/A',
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'picked':
      case 'on the way':
        return Colors.teal;
      case 'delivered':
        return AppColors.primaryColor;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
