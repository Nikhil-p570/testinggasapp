import 'package:flutter/material.dart';
import '../cart/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String name;
  final int refillPrice;

  const ProductDetailsScreen(this.name, this.refillPrice, {super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int qty = 1;
  bool isRefill = true;

  @override
  Widget build(BuildContext context) {
    int total = widget.refillPrice * qty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [isRefill, !isRefill],
              onPressed: (i) => setState(() => isRefill = i == 0),
              children: const [
                Padding(
                    padding: EdgeInsets.all(8), child: Text("Refill")),
                Padding(
                    padding: EdgeInsets.all(8), child: Text("New")),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => setState(() => qty--),
                    icon: const Icon(Icons.remove)),
                Text("$qty", style: const TextStyle(fontSize: 18)),
                IconButton(
                    onPressed: () => setState(() => qty++),
                    icon: const Icon(Icons.add)),
              ],
            ),
            const Spacer(),
            Text("Total: ₹$total",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: const Text("Add to Cart"),
            )
          ],
        ),
      ),
    );
  }
}
