import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/order_service.dart';
import 'order_tracking_screen.dart';

class OrderConfirmScreen extends StatelessWidget {
  const OrderConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Order")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text(appState.productName ?? ""),
                subtitle: Text(
                  "Quantity: ${appState.quantity}\n"
                      "Type: ${appState.isRefill ? "Refill" : "New"}",
                ),
                trailing: Text(
                  "₹${appState.totalAmount}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text("Delivery Address"),
                subtitle: Text(appState.fullAddress ?? ""),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text("Payment Mode"),
                subtitle: Text(appState.paymentMode),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final orderService = OrderService();

                try {
                  final orderId = await orderService.createOrder(
                    productId: appState.productId!,
                    productName: appState.productName!,
                    quantity: appState.quantity,
                    isRefill: appState.isRefill,
                    totalAmount: appState.totalAmount,
                    paymentMode: appState.paymentMode,
                    address: {
                      'label': appState.addressLabel,
                      'fullAddress': appState.fullAddress,
                      'lat': appState.lat,
                      'lng': appState.lng,
                    },
                  );

                  appState.setOrder(
                    orderId: orderId,
                    status: "created",
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderTrackingScreen(orderId: orderId),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to place order"),
                    ),
                  );
                }
              },
              child: const Text("Place Order"),
            ),
          ],
        ),
      ),
    );
  }
}
