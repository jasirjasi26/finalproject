import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  String selectedFilter = 'All';

  Future<void> updateRequestStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickups')
          .doc(docId)
          .update({'status': newStatus});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request status updated to $newStatus'),
          backgroundColor: newStatus.toLowerCase() == 'accepted' || newStatus.toLowerCase() == 'approved'
              ? Colors.green
              : newStatus.toLowerCase() == 'rejected'
                  ? Colors.red
                  : Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> makePhoneCall(BuildContext context, String userId, String initialPhone) async {
    String phone = initialPhone.trim();

    if (phone.isEmpty && userId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          phone = (doc.data()?['number'] ?? doc.data()?['phone'] ?? '').toString().trim();
        }
      } catch (_) {}
    }

    if (phone.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number found for this user.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling $phone...'),
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData getWasteIcon(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'organic':
        return Icons.eco;
      case 'recyclable':
        return Icons.recycling;
      case 'e-waste':
        return Icons.smartphone;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'All User Pickup Requests',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pickups').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading Firebase data:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No pickup requests found in Firebase.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Sort manually by timestamp descending
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Filter docs based on selected filter
          final filteredDocs = sortedDocs.where((doc) {
            if (selectedFilter == 'All') return true;
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'Pending').toString();
            return status.toLowerCase() == selectedFilter.toLowerCase();
          }).toList();

          // Statistics
          final totalCount = sortedDocs.length;
          final pendingCount = sortedDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'Pending').toString().toLowerCase() == 'pending';
          }).length;
          final acceptedCount = sortedDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final s = (data['status'] ?? '').toString().toLowerCase();
            return s == 'accepted' || s == 'approved';
          }).length;

          return Column(
            children: [
              // Stats Summary Bar
              Container(
                color: Colors.green.shade700,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildStatCard('Total Requests', '$totalCount', Colors.white, Colors.green.shade900),
                    const SizedBox(width: 8),
                    _buildStatCard('Pending', '$pendingCount', Colors.white, Colors.orange.shade800),
                    const SizedBox(width: 8),
                    _buildStatCard('Accepted', '$acceptedCount', Colors.white, Colors.teal.shade800),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                height: 50,
                color: Colors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: ['All', 'Pending', 'Accepted', 'Completed', 'Rejected'].map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter),
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // List of Requests
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text(
                          'No $selectedFilter requests found.',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;

                          final userId = data['userId'] ?? '';
                          final userEmail = data['userEmail'] ?? '';
                          final userPhone = data['userPhone'] ?? '';
                          final wasteType = data['wasteType'] ?? 'General';
                          final address = data['address'] ?? 'No address provided';
                          final pickupDateTime = data['pickupDateTime'] ?? 'Not specified';
                          final status = (data['status'] ?? 'Pending').toString();
                          final timestamp = data['timestamp'] as Timestamp?;

                          final isAccepted = status.toLowerCase() == 'accepted' || status.toLowerCase() == 'approved';
                          final isRejected = status.toLowerCase() == 'rejected' || status.toLowerCase() == 'cancelled';
                          final isPending = status.toLowerCase() == 'pending';
                          final statusColor = getStatusColor(status);
                          final wasteIcon = getWasteIcon(wasteType.toString());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Icon + Waste Type + Status Badge
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        radius: 20,
                                        child: Icon(wasteIcon, color: Colors.green.shade800, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$wasteType Waste',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (userEmail.isNotEmpty)
                                              Text(
                                                'Email: $userEmail',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            else
                                              Text(
                                                'UID: $userId',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: statusColor, width: 1.5),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // Address & Time
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          address,
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 18, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          pickupDateTime,
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (timestamp != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Requested: ${timestamp.toDate().toString().split('.')[0]}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  // ADMIN ACTION BUTTONS: ACCEPT / REJECT & CALL USER
                                  Row(
                                    children: [
                                      if (isPending) ...[
                                        // Accept Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => updateRequestStatus(docId, 'Accepted'),
                                            icon: const Icon(Icons.check_circle_outline, size: 18),
                                            label: const Text('Accept'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Reject Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => updateRequestStatus(docId, 'Rejected'),
                                            icon: const Icon(Icons.highlight_off, size: 18),
                                            label: const Text('Reject'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade600,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ] else if (isAccepted) ...[
                                        // Call User Button (Shown After Accepting)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => makePhoneCall(context, userId, userPhone),
                                            icon: const Icon(Icons.phone, size: 20),
                                            label: const Text(
                                              'Call User',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green.shade700,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Change Status Options
                                        PopupMenuButton<String>(
                                          onSelected: (newStatus) => updateRequestStatus(docId, newStatus),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Row(
                                              children: [
                                                Text('Options', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                Icon(Icons.arrow_drop_down, size: 18),
                                              ],
                                            ),
                                          ),
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(value: 'Completed', child: Text('Mark as Completed')),
                                            PopupMenuItem(value: 'Pending', child: Text('Reset to Pending')),
                                            PopupMenuItem(value: 'Rejected', child: Text('Reject Request')),
                                          ],
                                        ),
                                      ] else if (isRejected) ...[
                                        // Re-accept option
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => updateRequestStatus(docId, 'Accepted'),
                                            icon: const Icon(Icons.refresh, size: 18),
                                            label: const Text('Re-Accept Request'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              side: const BorderSide(color: Colors.green),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        // Completed or general status options
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => makePhoneCall(context, userId, userPhone),
                                            icon: const Icon(Icons.phone, size: 18),
                                            label: const Text('Call User'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
