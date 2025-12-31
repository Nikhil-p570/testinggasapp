import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderSuccessScreen({
    super.key,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Order Successful"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 90,
              ),
              const SizedBox(height: 20),

              const Text(
                "Order Placed Successfully!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                "Order ID: ${orderData['orderId']}",
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                ),
                child: const Text("Go to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
