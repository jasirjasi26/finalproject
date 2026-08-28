import 'package:flutter/material.dart';

class SchedulePickupPage extends StatefulWidget {
  const SchedulePickupPage({super.key});

  @override
  State<SchedulePickupPage> createState() => _SchedulePickupPageState();
}

class _SchedulePickupPageState extends State<SchedulePickupPage> {
  String selectedWaste = "Organic";

  final TextEditingController addressController =
  TextEditingController(
    text: "123 Green Avenue, Kochi",
  );

  final TextEditingController dateTimeController =
  TextEditingController(
    text: "May 22, 2026 | 09:00 AM - 11:00 AM",
  );

  Widget wasteTypeCard({
    required String title,
    required IconData icon,
  }) {
    bool isSelected = selectedWaste == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWaste = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade50
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? Colors.green
                : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
              isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.green
                    : Colors.black87,
                fontWeight: FontWeight.w500,
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
          "Schedule New Pickup",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              "Waste Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                wasteTypeCard(
                  title: "Organic",
                  icon: Icons.eco,
                ),
                wasteTypeCard(
                  title: "Recyclable",
                  icon: Icons.recycling,
                ),
                wasteTypeCard(
                  title: "E-Waste",
                  icon: Icons.delete_outline,
                ),
                wasteTypeCard(
                  title: "Hazardous",
                  icon: Icons.science_outlined,
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Address",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                prefixIcon:
                const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Date & Time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: dateTimeController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon:
                const Icon(Icons.calendar_month),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Upload Photo (Optional)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    size: 35,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap to upload",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        "$selectedWaste Pickup Confirmed",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Confirm Pickup",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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