import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

class UserProductsScreen extends StatefulWidget {
  const UserProductsScreen({super.key});

  @override
  State<UserProductsScreen> createState() => _UserProductsScreenState();
}

class _UserProductsScreenState extends State<UserProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Calculate dynamic pricing or filtering based on refill vs new
    // For now, we'll just show all products and assume price logic might be adjusted in future
    // Or we can simulate price change on the UI side.

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
      body: Column(
        children: [
          /* ---------------- TOGGLE: REFILL / NEW ---------------- */
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggleButton(
                    context,
                    title: "Cylinder Refill",
                    isSelected: appState.isRefillMode,
                    onTap: () => appState.toggleOrderType(true),
                  ),
                  _buildToggleButton(
                    context,
                    title: "New Connection",
                    isSelected: !appState.isRefillMode,
                    onTap: () => appState.toggleOrderType(false),
                  ),
                ],
              ),
            ),
          ),
          
          /* ---------------- PRODUCT GRID ---------------- */
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final productData = doc.data() as Map<String, dynamic>;
                    
                    // Adjust price if New Cylinder mode (Logic: Base Price + 2500 Deposit)
                    // This is CLIENT SIDE simulation. In real app, might want specific prices in DB.
                    double basePrice = (productData['price'] ?? 951).toDouble();
                    double finalPrice = appState.isRefillMode ? basePrice : basePrice + 1400; // Example deposit

                    final product = {
                      ...productData,
                      'id': doc.id,
                      'price': finalPrice, // Override price for display/cart
                    };

                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
      /* ---------------- FLOATING CART BAR ---------------- */
      bottomNavigationBar: appState.totalCartItems > 0 
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                 child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${appState.totalCartItems} Items | ₹${appState.totalCartValue.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Row(
                        children: [
                          Text(
                            "View Cart",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildToggleButton(BuildContext context, {required String title, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE50914) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String productId = product['id'];
    final int qty = appState.getItemQuantity(productId);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFFE5E2),
              child: product['imageUrl'] != null
                  ? Image.network(product['imageUrl'], fit: BoxFit.contain)
                  : const Icon(Icons.propane_tank, size: 60, color: Color(0xFFFF5C4D)),
            ),
          ),
          
          // DETAILS
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'LPG Cylinder',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product['weight'] ?? '14.2 kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${product['price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE50914),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // ADD / REMOVE BUTTONS
                qty == 0
                    ? SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => appState.addToCart(product),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE50914)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Add', style: TextStyle(color: Color(0xFFE50914))),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQtyBtn(Icons.remove, () => appState.removeFromCart(productId)),
                          Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          _buildQtyBtn(Icons.add, () => appState.addToCart(product)),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFE50914),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
