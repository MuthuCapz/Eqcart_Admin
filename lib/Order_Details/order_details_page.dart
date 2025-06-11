import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'order_view_details_page.dart';
import '../../../utils/colors.dart'; // Import your AppColors

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  late Future<Map<String, String>> _shopNamesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shopNamesFuture = _loadAllShopNames();
  }

  Future<Map<String, String>> _loadAllShopNames() async {
    final shopsRef = FirebaseFirestore.instance.collection('shops');
    final ownShopsRef = FirebaseFirestore.instance.collection('own_shops');

    final shopsSnapshot = await shopsRef.get();
    final ownShopsSnapshot = await ownShopsRef.get();

    final shopNames = <String, String>{};
    shopNames[''] = 'Unknown Shop';

    for (var doc in shopsSnapshot.docs) {
      shopNames[doc.id] = doc.get('shop_name')?.toString() ?? 'Unnamed Shop';
    }
    for (var doc in ownShopsSnapshot.docs) {
      shopNames[doc.id] = doc.get('shop_name')?.toString() ?? 'Unnamed Shop';
    }
    return shopNames;
  }

  List<Map<String, dynamic>> _filterOrders(
    List<QueryDocumentSnapshot> orders,
    Map<String, String> shopNames,
    bool isCompleted,
  ) {
    return orders.map((doc) {
      final data =
          Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      final items = data['items'] as List?;
      String shopId = '';
      if (items != null && items.isNotEmpty) {
        shopId = items[0]['shopId']?.toString() ?? '';
      }
      data['shopName'] = shopNames[shopId] ?? 'Unknown Shop';
      return data;
    }).where((data) {
      final orderStatus = (data['orderStatus'] ?? '').toString().toLowerCase();
      final matchesTab =
          isCompleted ? orderStatus == 'delivered' : orderStatus != 'delivered';

      final matchesSearch = _searchQuery.isEmpty ||
          data['shopName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          orderStatus.contains(_searchQuery.toLowerCase());

      return matchesTab && matchesSearch;
    }).toList()
      ..sort((a, b) {
        const statusPriority = {
          'pending': 1,
          'accepted': 2,
          'picked': 3,
          'on the way': 4,
          'delivered': 5,
        };
        final priorityA =
            statusPriority[(a['orderStatus'] ?? '').toString().toLowerCase()] ??
                5;
        final priorityB =
            statusPriority[(b['orderStatus'] ?? '').toString().toLowerCase()] ??
                5;
        return priorityA.compareTo(priorityB);
      });
  }

  Widget _buildOrdersList(bool isCompleted) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return FutureBuilder<Map<String, String>>(
          future: _shopNamesFuture,
          builder: (context, shopNamesSnapshot) {
            if (!shopNamesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final shopNames = shopNamesSnapshot.data!;
            final orders = snapshot.data!.docs;
            final filteredOrders =
                _filterOrders(orders, shopNames, isCompleted);

            if (filteredOrders.isEmpty) {
              return const Center(child: Text("No orders found."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filteredOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderTile(order);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final status = (order['orderStatus'] ?? '').toString().toLowerCase();
    final isCancelled = status == 'cancelled';

    final statusColor = {
          'pending': Colors.orange,
          'accepted': Colors.blue,
          'picked': Colors.deepPurple,
          'on the way': Colors.teal,
          'delivered': Colors.green,
          'cancelled': Colors.red,
        }[status] ??
        AppColors.primaryColor;

    return Opacity(
      opacity: isCancelled ? 0.5 : 1.0, // Make cancelled slightly faded
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.backgroundColor,
        elevation: 4,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: AppColors.secondaryColor,
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          title: Text(
            "Order ID: ${order['orderId'] ?? 'N/A'}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Shop: ${order['shopName'] ?? 'Unknown Shop'}"),
                if (order['orderTotal'] != null)
                  Text("Total: ₹${order['orderTotal']}"),
                if (order['orderStatus'] != null)
                  Text(
                    "Status: ${order['orderStatus']}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsViewPage(
                  orderData: order,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Order History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "All Orders"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.backgroundColor,
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by shop or status",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              onChanged: (val) => setState(() {
                _searchQuery = val;
              }),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(false),
                _buildOrdersList(true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
