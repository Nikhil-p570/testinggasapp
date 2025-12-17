import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'place_order_screen.dart';

class ConfirmAddressScreen extends StatefulWidget {
  final ProductModel product;

  const ConfirmAddressScreen({
    super.key,
    required this.product,
  });

  @override
  State<ConfirmAddressScreen> createState() =>
      _ConfirmAddressScreenState();
}

class _ConfirmAddressScreenState extends State<ConfirmAddressScreen> {
  final TextEditingController addressController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    // Later: Load from Firestore user profile
    addressController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Address")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Delivery Address",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "House no, Street, Area, City",
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter address"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceOrderScreen(
                        product: widget.product,
                        address: addressController.text.trim(),
                      ),
                    ),
                  );
                },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
