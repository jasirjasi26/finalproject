import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulePickupPage extends StatefulWidget {
  const SchedulePickupPage({super.key});

  @override
  State<SchedulePickupPage> createState() => _SchedulePickupPageState();
}

class _SchedulePickupPageState extends State<SchedulePickupPage> {
  String selectedWaste = 'Organic';
  bool isSubmitting = false;

  final TextEditingController addressController =
      TextEditingController(text: '123 Green Avenue, Kochi');

  final TextEditingController dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set a default date & time text
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    dateTimeController.text =
        "${monthNames[tomorrow.month - 1]} ${tomorrow.day}, ${tomorrow.year} | 09:00 AM";
  }

  Future<void> pickDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final int hour = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
    final String period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final String minute = pickedTime.minute.toString().padLeft(2, '0');
    final String formattedHour = hour.toString().padLeft(2, '0');

    final String formattedString =
        "${monthNames[pickedDate.month - 1]} ${pickedDate.day}, ${pickedDate.year} | $formattedHour:$minute $period";

    setState(() {
      dateTimeController.text = formattedString;
    });
  }

  Future<void> submitPickupRequest() async {
    final String address = addressController.text.trim();
    final String dateTime = dateTimeController.text.trim();

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (address.isEmpty || dateTime.isEmpty) {
      showMessage('Please select address and date & time.');
      return;
    }

    if (currentUser == null) {
      showMessage('You must be logged in to schedule a pickup.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      String userPhone = currentUser.phoneNumber ?? '';
      if (userPhone.isEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            userPhone = userDoc.data()?['number'] ??
                userDoc.data()?['phone'] ??
                '';
          }
        } catch (_) {}
      }

      await FirebaseFirestore.instance.collection('pickups').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email ?? '',
        'userPhone': userPhone,
        'wasteType': selectedWaste,
        'address': address,
        'pickupDateTime': dateTime,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$selectedWaste pickup scheduled successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Firebase error occurred.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget wasteTypeCard({
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = selectedWaste == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWaste = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.lightGreen,
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    dateTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Schedule Pickup',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.green,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isSubmitting
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Waste Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.3,
                    children: [
                      wasteTypeCard(
                        title: 'Organic',
                        icon: Icons.eco,
                      ),
                      wasteTypeCard(
                        title: 'Recyclable',
                        icon: Icons.recycling,
                      ),
                      wasteTypeCard(
                        title: 'E-Waste',
                        icon: Icons.smartphone,
                      ),
                      wasteTypeCard(
                        title: 'Hazardous',
                        icon: Icons.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Pickup Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter pickup address',
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Preferred Date & Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: dateTimeController,
                    readOnly: true,
                    onTap: () => pickDateTime(context),
                    decoration: InputDecoration(
                      hintText: 'Tap to select date and time',
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.green,
                      ),
                      suffixIcon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.green,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitPickupRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Pickup Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}