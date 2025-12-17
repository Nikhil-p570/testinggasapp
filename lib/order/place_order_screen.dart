import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import '../payment/payment_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  final ProductModel product;
  final String address;

  const PlaceOrderScreen({
    super.key,
    required this.product,
    required this.address,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  bool isPlacingOrder = false;
  String deliverySlot = "Standard (Tomorrow)";

  Future<void> placeOrder() async {
    if (isPlacingOrder) return;

    setState(() => isPlacingOrder = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🔥 CREATE ORDER IN FIRESTORE
      final orderRef =
      await FirebaseFirestore.instance.collection("orders").add({
        "userId": user.uid,
        "productId": widget.product.id,
        "productName": widget.product.name,
        "price": widget.product.price,
        "weight": widget.product.weight,
        "address": widget.address,
        "deliverySlot": deliverySlot,

        // 🔹 ORDER + PAYMENT STATUS
        "orderStatus": "placed",
        "paymentStatus": "pending",
        "paymentMethod": null,
        "transactionId": null,

        "createdAt": FieldValue.serverTimestamp(),
      });

      // 🚀 GO TO PAYMENT SCREEN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            orderId: orderRef.id,
            amount: widget.product.price,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to place order")),
      );
    } finally {
      setState(() => isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Place Order")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Order Summary",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 🧾 PRODUCT DETAILS
            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 16),
            ),
            Text("Weight: ${widget.product.weight}"),
            Text(
              "Price: ₹${widget.product.price}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            // 📍 ADDRESS
            Text(
              "Delivery Address",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.address),

            const SizedBox(height: 20),

            // ⏰ DELIVERY SLOT
            const Text(
              "Delivery Slot",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButton<String>(
              value: deliverySlot,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: "Standard (Tomorrow)",
                  child: Text("Standard (Tomorrow)"),
                ),
                DropdownMenuItem(
                  value: "Express (Today)",
                  child: Text("Express (Today)"),
                ),
              ],
              onChanged: (value) {
                setState(() => deliverySlot = value!);
              },
            ),

            const Spacer(),

            // 💳 PLACE ORDER BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPlacingOrder ? null : placeOrder,
                child: isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Proceed to Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
