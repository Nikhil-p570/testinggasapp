import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../order_history/order_history_screen.dart';

class UserProductsScreen extends StatefulWidget {
  const UserProductsScreen({super.key});

  @override
  State<UserProductsScreen> createState() => _UserProductsScreenState();
}

class _UserProductsScreenState extends State<UserProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
      title: const Text(
        'LPG Products',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: [

         // HISTORY BUTTON HERE
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFFE50914)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
        // PROFILE BUTTON HERE
        IconButton(
          icon: const Icon(Icons.person, color: Color(0xFFE50914)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
      ],
    ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products available',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.68, // ✅ FIXED
              ),
              itemBuilder: (context, index) {
                final doc = products[index];
                final product = doc.data() as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(
                          product: {
                            'id': doc.id,
                            ...product,
                          },
                        ),
                      ),
                    );
                  },
                  child: ProductCard(
                    product: product,
                    docId: doc.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/* ----------------------------------------------------------- */
/* ----------------------- PRODUCT CARD ----------------------- */
/* ----------------------------------------------------------- */

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String docId;

  const ProductCard({
    super.key,
    required this.product,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ✅ IMAGE (RESPONSIVE)
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFFE5E2),
              child: product['imageUrl'] != null
                  ? Image.network(
                      product['imageUrl'],
                      fit: BoxFit.contain,
                    )
                  : const Icon(
                      Icons.propane_tank,
                      size: 60,
                      color: Color(0xFFFF5C4D),
                    ),
            ),
          ),

          // ✅ DETAILS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  product['name'] ?? 'LPG Cylinder',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  product['weight'] ?? '14.2 kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${product['price'] ?? 951}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE50914),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'Stock: ${product['stock'] ?? 0} available',
                  style: TextStyle(
                    fontSize: 12,
                    color: (product['stock'] ?? 0) > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
