import 'package:finalproject/admin_requests_page.dart';
import 'package:finalproject/pickuppage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalproject/loginpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EcoCollectHomePage extends StatefulWidget {
  const EcoCollectHomePage({super.key});

  @override
  State<EcoCollectHomePage> createState() => _EcoCollectHomePageState();
}

class _EcoCollectHomePageState extends State<EcoCollectHomePage> {
  String userName = "Guest";
  String userEmail = "";

  bool get isAdmin {
    final authEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    return userEmail.trim().toLowerCase() == "admin@gmail.com" ||
        authEmail.trim().toLowerCase() == "admin@gmail.com";
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final authUser = FirebaseAuth.instance.currentUser;

    setState(() {
      userEmail = prefs.getString("email") ?? authUser?.email ?? "";
      userName = userEmail.isNotEmpty ? userEmail : (authUser?.email ?? "Guest");
    });
  }

  Future<void> logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

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
              : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('Calling $phone...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            const Text(
              "EcoCollect",
              style: TextStyle(
                color: Colors.green,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAdmin
                          ? [Colors.deepOrange.shade600, Colors.red.shade700]
                          : [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isAdmin ? Colors.red : Colors.green).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            size: 40,
                            color: isAdmin ? Colors.red.shade700 : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAdmin ? "👑 Administrator" : "Eco Citizen",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAdmin ? "System Administrator" : "📍 Kochi, Kerala",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // IF ADMIN: Show Admin Dashboard Access Banner & All User Requests
                if (isAdmin) ...[

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "All Pickup Requests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminRequestsPage(),
                            ),
                          );
                        },
                        child: const Text("View All >"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('pickups').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Error: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.green),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.inbox, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text(
                                "No pickup requests found in Firebase database.",
                                style: TextStyle(color: Colors.grey),
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

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = sortedDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;

                          final userId = data['userId'] ?? '';
                          final wasteType = data['wasteType'] ?? 'General';
                          final userEmailStr = data['userEmail'] ?? data['userId'] ?? 'Unknown User';
                          final userPhone = data['userPhone'] ?? '';
                          final address = data['address'] ?? '';
                          final status = (data['status'] ?? 'Pending').toString();
                          final dateTime = data['pickupDateTime'] ?? '';

                          final isAccepted = status.toLowerCase() == 'accepted' || status.toLowerCase() == 'approved';
                          final isPending = status.toLowerCase() == 'pending';

                          Color statusColor = Colors.orange;
                          if (isAccepted) {
                            statusColor = Colors.green;
                          } else if (status.toLowerCase() == 'completed') {
                            statusColor = Colors.teal;
                          } else if (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'cancelled') {
                            statusColor = Colors.red;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        child: Icon(
                                          wasteType == 'Organic'
                                              ? Icons.eco
                                              : wasteType == 'Recyclable'
                                                  ? Icons.recycling
                                                  : wasteType == 'E-Waste'
                                                      ? Icons.smartphone
                                                      : Icons.delete,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$wasteType Waste",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              "User: $userEmailStr",
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  Text("📍 Address: $address", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  if (dateTime.isNotEmpty)
                                    Text("🕒 Preferred Time: $dateTime", style: const TextStyle(fontSize: 12, color: Colors.grey)),

                                  const SizedBox(height: 12),

                                  // ADMIN BUTTONS: ACCEPT / REJECT OR CALL USER
                                  Row(
                                    children: [
                                      if (isPending) ...[
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
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
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
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ] else if (isAccepted) ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => makePhoneCall(context, userId, userPhone),
                                            icon: const Icon(Icons.phone, size: 18),
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
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => makePhoneCall(context, userId, userPhone),
                                            icon: const Icon(Icons.phone, size: 18),
                                            label: const Text('Call User'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              side: const BorderSide(color: Colors.green),
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
                      );
                    },
                  ),
                ] else ...[
                  // NORMAL USERS SECTION: Quick Actions Grid

                  const SizedBox(height: 8),

                  // LIST OF ALL PICKUP REQUESTS FOR NORMAL USER FROM FIREBASE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Pickup Requests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SchedulePickupPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("New Pickup"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('pickups').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Error loading your requests: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.green),
                          ),
                        );
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      final authUid = currentAuthUser?.uid ?? '';
                      final authEmail = (currentAuthUser?.email ?? userEmail).toLowerCase().trim();

                      // Filter user's own docs
                      final userDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final docUid = (data['userId'] ?? '').toString().trim();
                        final docEmail = (data['userEmail'] ?? '').toString().toLowerCase().trim();
                        return (authUid.isNotEmpty && docUid == authUid) ||
                            (authEmail.isNotEmpty && docEmail == authEmail);
                      }).toList();

                      if (userDocs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: Colors.green.shade400, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                "No pickup requests yet!",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Schedule a waste pickup now and eco-collect will pick it up.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SchedulePickupPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text("Schedule First Pickup"),
                              ),
                            ],
                          ),
                        );
                      }

                      // Sort user's docs by timestamp descending
                      userDocs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['timestamp'] as Timestamp?;
                        final bTime = bData['timestamp'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userDocs.length,
                        itemBuilder: (context, index) {
                          final doc = userDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final wasteType = data['wasteType'] ?? 'General';
                          final address = data['address'] ?? '';
                          final status = (data['status'] ?? 'Pending').toString();
                          final dateTime = data['pickupDateTime'] ?? '';
                          final timestamp = data['timestamp'] as Timestamp?;

                          final isAccepted = status.toLowerCase() == 'accepted' || status.toLowerCase() == 'approved';
                          final isRejected = status.toLowerCase() == 'rejected' || status.toLowerCase() == 'cancelled';
                          final isCompleted = status.toLowerCase() == 'completed';

                          Color statusColor = Colors.orange;
                          if (isAccepted) {
                            statusColor = Colors.green;
                          } else if (isCompleted) {
                            statusColor = Colors.teal;
                          } else if (isRejected) {
                            statusColor = Colors.red;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        radius: 20,
                                        child: Icon(
                                          wasteType == 'Organic'
                                              ? Icons.eco
                                              : wasteType == 'Recyclable'
                                                  ? Icons.recycling
                                                  : wasteType == 'E-Waste'
                                                      ? Icons.smartphone
                                                      : Icons.warning,
                                          color: Colors.green.shade800,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$wasteType Waste Pickup",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (timestamp != null)
                                              Text(
                                                "Requested on ${timestamp.toDate().toString().split(' ')[0]}",
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                      const SizedBox(width: 6),
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
                                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dateTime,
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Status Banner Message for User
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isAccepted
                                          ? Colors.green.shade50
                                          : isRejected
                                              ? Colors.red.shade50
                                              : isCompleted
                                                  ? Colors.teal.shade50
                                                  : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAccepted
                                            ? Colors.green.shade300
                                            : isRejected
                                                ? Colors.red.shade300
                                                : isCompleted
                                                    ? Colors.teal.shade300
                                                    : Colors.orange.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isAccepted
                                              ? Icons.check_circle
                                              : isRejected
                                                  ? Icons.cancel
                                                  : isCompleted
                                                      ? Icons.task_alt
                                                      : Icons.hourglass_top,
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isAccepted
                                                ? "Pickup accepted! A driver will collect your waste."
                                                : isRejected
                                                    ? "Pickup request was declined by admin."
                                                    : isCompleted
                                                        ? "Waste pickup has been completed successfully."
                                                        : "Awaiting admin confirmation.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Gradient gradient;

  const HomeCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.gradient = const LinearGradient(
      colors: [Colors.green, Colors.teal],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  });

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: Transform.scale(
        scale: isPressed ? 0.95 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}