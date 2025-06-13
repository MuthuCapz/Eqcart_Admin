import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'query_card.dart';

class UsersQueriesPage extends StatefulWidget {
  const UsersQueriesPage({super.key});

  @override
  State<UsersQueriesPage> createState() => _UsersQueriesPageState();
}

class _UsersQueriesPageState extends State<UsersQueriesPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text('User Queries',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 4,
          bottom: const TabBar(
            labelColor: Colors.white, // Selected tab text
            unselectedLabelColor: Colors.white70, // Unselected tab text
            indicatorColor: Colors.white, // Underline color
            tabs: [
              Tab(text: 'All Queries'),
              Tab(text: 'Closed Queries'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() => searchQuery = value.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search by Query ID or Status',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildQueryList(showClosed: false), // All/Active
                  buildQueryList(showClosed: true), // Closed only
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQueryList({required bool showClosed}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_queries')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']?.toString().toLowerCase() ?? '';
          final queryId = data['query_id']?.toString().toLowerCase() ?? '';
          final input = searchQuery.trim().toLowerCase();

          final matchesSearch =
              queryId.contains(input) || status.contains(input);
          final isClosed = status == 'closed';

          return (showClosed ? isClosed : !isClosed) && matchesSearch;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Text("No queries found",
                style: TextStyle(color: Colors.black54, fontSize: 18)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return QueryCard(queryDoc: filteredDocs[index]);
          },
        );
      },
    );
  }
}

class StatusFlowWidget extends StatelessWidget {
  final String currentStatus;
  final Function(String newStatus) onStatusChange;

  const StatusFlowWidget({
    super.key,
    required this.currentStatus,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(label: "Review", icon: Icons.search),
      _StepData(label: "Processing", icon: Icons.settings),
      _StepData(label: "Closed", icon: Icons.check_circle_outlined),
    ];

    final currentIndex = _statusOrder(currentStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final bool isCompleted = index < currentIndex;
        final bool isActive = index == currentIndex;
        final bool isClickable = index == currentIndex;

        return GestureDetector(
          onTap: isClickable ? () => onStatusChange(step.label) : null,
          child: Opacity(
            opacity: currentStatus == 'Closed' ? 0.8 : 1.0,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade50 : Colors.white,
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.grey.shade300,
                      width: isActive ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(step.icon,
                          size: 18,
                          color: isCompleted || isActive
                              ? Colors.green
                              : Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        step.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isCompleted || isActive
                              ? Colors.green
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          ),
        );
      }),
    );
  }

  int _statusOrder(String status) {
    switch (status) {
      case 'Review':
        return 1;
      case 'Processing':
        return 2;
      case 'Closed':
        return 3;
      default:
        return 0;
    }
  }
}

class _StepData {
  final String label;
  final IconData icon;
  const _StepData({required this.label, required this.icon});
}
