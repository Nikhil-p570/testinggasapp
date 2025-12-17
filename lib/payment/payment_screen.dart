import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔴 IMPORTANT: import Razorpay screen
import 'razorpay_upi_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final int amount;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = "COD";
  bool isProcessing = false;

  Future<void> confirmCOD() async {
    setState(() => isProcessing = true);

    await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .update({
      "paymentMethod": "COD",
      "paymentStatus": "pending",
    });

    // Go back to home / order tracking
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(24), // ✅ FIXED
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            RadioListTile<String>(
              title: const Text("Cash on Delivery"),
              value: "COD",
              groupValue: paymentMethod,
              onChanged: (value) {
                setState(() => paymentMethod = value!);
              },
            ),

            RadioListTile<String>(
              title: const Text("UPI (Google Pay / PhonePe)"),
              value: "UPI",
              groupValue: paymentMethod,
              onChanged: (value) {
                setState(() => paymentMethod = value!);
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () {
                  if (paymentMethod == "COD") {
                    confirmCOD();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RazorpayUPIScreen(
                          orderId: widget.orderId,
                          amount: widget.amount,
                        ),
                      ),
                    );
                  }
                },
                child: isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
