import 'package:flutter/material.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController addressController = TextEditingController();

  bool isUsingAutoLocation = false;

  // 🔹 Simulated GPS address (replace later with Geolocator)
  void useCurrentLocation() async {
    setState(() {
      isUsingAutoLocation = true;
      addressController.text =
      "221B, Baker Street, Bengaluru, Karnataka"; // demo
    });
  }

  void saveAddress() {
    final address = addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter address")),
      );
      return;
    }

    // 🔥 TODO: Save address to Firestore
    print("Saved address: $address");

    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Address"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Where should we deliver?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // ✅ EDITABLE ADDRESS FIELD
            TextField(
              controller: addressController,
              maxLines: 3,
              enabled: true,
              readOnly: false,
              decoration: const InputDecoration(
                labelText: "Address",
                hintText: "House no, Street, Area, City",
              ),
              onChanged: (_) {
                // 🔑 Stop GPS overwrite when user types
                isUsingAutoLocation = false;
              },
            ),

            const SizedBox(height: 12),

            // 📍 USE CURRENT LOCATION
            TextButton.icon(
              onPressed: useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Use current location"),
            ),

            const Spacer(),

            // 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveAddress,
                child: const Text("Save Address"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
