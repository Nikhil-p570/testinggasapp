import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackOrderScreen extends StatelessWidget {
  final String orderId;

  const TrackOrderScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Order")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId)
            .snapshots(), // 🔥 REAL-TIME
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['orderStatus'];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Order Status: ${status.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _statusTile("Placed", status == "placed" || status != "placed"),
                _statusTile("Assigned", status == "assigned" || status == "out_for_delivery" || status == "delivered"),
                _statusTile("Out for Delivery", status == "out_for_delivery" || status == "delivered"),
                _statusTile("Delivered", status == "delivered"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusTile(String title, bool active) {
    return ListTile(
      leading: Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        color: active ? Colors.green : Colors.grey,
      ),
      title: Text(title),
    );
  }
}
