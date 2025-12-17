import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'confirm_address_screen.dart';

class CylinderDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const CylinderDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            Text("Price: ₹${product.price}"),
            Text("Weight: ${product.weight}"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ConfirmAddressScreen(product: product),
                    ),
                  );
                },
                child: const Text("Add to Cart"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
