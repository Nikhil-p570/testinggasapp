import 'package:flutter/material.dart';
import '../address/address_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int quantity = 1;
  int pricePerUnit = 1100;

  @override
  Widget build(BuildContext context) {
    int total = quantity * pricePerUnit;

    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("19kg Commercial Cylinder"),
                subtitle: Text("₹$pricePerUnit per refill"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove)),
                    Text("$quantity"),
                    IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              "Total: ₹$total",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressScreen()),
                );
              },
              child: const Text("Proceed to Address"),
            )
          ],
        ),
      ),
    );
  }
}
