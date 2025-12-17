import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RazorpayUPIScreen extends StatefulWidget {
  final String orderId;
  final int amount;

  const RazorpayUPIScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<RazorpayUPIScreen> createState() => _RazorpayUPIScreenState();
}

class _RazorpayUPIScreenState extends State<RazorpayUPIScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handleFailure);

    openCheckout();
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_XXXXXXXX', // 🔴 replace with real key
      'amount': widget.amount * 100,
      'name': 'Vyoma Gas',
      'description': 'Gas Cylinder Order',
      'method': {'upi': true},
    };

    _razorpay.open(options);
  }

  void handleSuccess(PaymentSuccessResponse response) async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .update({
      "paymentMethod": "UPI",
      "paymentStatus": "paid",
      "transactionId": response.paymentId,
    });

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void handleFailure(PaymentFailureResponse response) async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .update({
      "paymentMethod": "UPI",
      "paymentStatus": "failed",
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
