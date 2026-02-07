import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';

class CartScreen extends StatefulWidget {
  // Removed product parameter as we now use global cart state
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isPlacingOrder = false;
  String _deliveryType = 'Normal'; // Normal or Fast
  
  // Delivery Slots
  List<String> _availableSlots = [];
  String? _selectedSlot;

  // GST Constant
  final String _companyGst = "36AAAAA0000A1Z5";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _calculateDetailSlots();
  }

  void _calculateDetailSlots() {
    final now = TimeOfDay.now();
    // Logic: 
    // Before 12 PM -> "Today 2pm-8pm", "Tomorrow 9am-1pm", "Tomorrow 2pm-8pm"
    // After 12 PM -> "Tomorrow 9am-1pm", "Tomorrow 2pm-8pm"
    
    // For testing/demo purposes, you can comment this out and hardcode 'now'
    // final now = TimeOfDay(hour: 10, minute: 0); // Test Morning
    
    if (now.hour < 12) {
      _availableSlots = [
        "Today, 2 PM - 8 PM",
        "Tomorrow, 9 AM - 1 PM",
        "Tomorrow, 2 PM - 8 PM",
      ];
    } else {
      _availableSlots = [
        "Tomorrow, 9 AM - 1 PM",
        "Tomorrow, 2 PM - 8 PM",
      ];
    }
    
    // Select first slot by default
    if (_availableSlots.isNotEmpty) {
      _selectedSlot = _availableSlots.first;
    }
  }

  void _loadUserData() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.userId != null) {
      _phoneController.text = appState.phoneNumber ?? '';
      if (appState.fullAddress != null) {
        _addressController.text = appState.fullAddress!;
      }
       if (appState.addressLabel != null) {
        _areaController.text = appState.addressLabel!;
      }
    } else {
        _fetchUserFromFirestore();
    }
  }

  Future<void> _fetchUserFromFirestore() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         try {
            final doc = await FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: user.uid).limit(1).get();
            if (doc.docs.isNotEmpty) {
                final data = doc.docs.first.data();
                setState(() {
                    _phoneController.text = data['phone'] ?? '';
                    _addressController.text = data['address'] ?? '';
                    _areaController.text = data['area'] ?? '';
                });
            }
         } catch (e) {
             print("Error fetching user: $e");
         }
      }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final cartItems = appState.cartItems;

    double itemTotal = appState.totalCartValue;
    double deliveryCharge = _deliveryType == 'Fast' ? (cartItems.fold(0, (sum, item) => sum + item.quantity) * 10).toDouble() : 0;
    double grandTotal = itemTotal + deliveryCharge;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* ---------------- CART ITEMS ---------------- */
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                               Container(
                                width: 60,
                                height: 60,
                                color: Colors.indigo[50],
                                child: item.imageUrl != null 
                                    ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.propane_tank, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(item.weight, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => appState.removeFromCart(item.id),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => appState.addToCart({
                                      'id': item.id, 
                                      'name': item.name, 
                                      'price': item.price, 
                                      'weight': item.weight,
                                      'imageUrl': item.imageUrl
                                    }),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  /* ---------------- DELIVERY OPTIONS ---------------- */
                  const Text('Delivery Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  
                  // Normal (Previously Standard)
                  RadioListTile<String>(
                    title: const Text('Normal Delivery (Free)'),
                    subtitle: _deliveryType == 'Normal' 
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _availableSlots.map((slot) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedSlot = slot),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedSlot == slot ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: _selectedSlot == slot ? const Color(0xFFE50914) : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(slot, style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedSlot == slot ? Colors.black : Colors.grey[700],
                                        fontWeight: _selectedSlot == slot ? FontWeight.bold : FontWeight.normal
                                      )),
                                    ],
                                  ),
                                ),
                              )).toList(),
                            ),
                          )
                        : const Text("Select to view slots"),
                    value: 'Normal',
                    groupValue: _deliveryType,
                    activeColor: const Color(0xFFE50914),
                    onChanged: (value) {
                      setState(() {
                        _deliveryType = value!;
                        // Reset slot when switching back to Normal if needed, or keep previous selection
                         if (_availableSlots.isNotEmpty && _selectedSlot == null) {
                            _selectedSlot = _availableSlots.first;
                         }
                      });
                    },
                  ),
                  
                  // Fast
                  RadioListTile<String>(
                    title: const Text('Fast Delivery (+₹10/cyl)'),
                    subtitle: const Text('Delivery expected by today'),
                    value: 'Fast',
                    groupValue: _deliveryType,
                    activeColor: const Color(0xFFE50914),
                    onChanged: (value) {
                      setState(() {
                        _deliveryType = value!;
                      });
                    },
                  ),

                  const Divider(height: 32),

                  /* ---------------- BILL DETAILS ---------------- */
                  const Text('Bill Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _buildBillRow('Item Total', '₹$itemTotal'),
                  _buildBillRow('Delivery Charges', '₹$deliveryCharge', isBlue: true),
                  _buildBillRow('Grand Total', '₹$grandTotal', isBold: true),
                  const SizedBox(height: 8),
                  Text("Company GSTIN: $_companyGst", style: const TextStyle(color: Colors.grey, fontSize: 12)),

                  const Divider(height: 32),

                   /* ---------------- ADDRESS INPUTS ---------------- */
                   const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _addressController,
                     decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                     maxLines: 2,
                   ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _areaController,
                     decoration: const InputDecoration(labelText: 'Area / Locality', border: OutlineInputBorder()),
                   ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _phoneController,
                     decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                     keyboardType: TextInputType.phone,
                   ),

                   const SizedBox(height: 24),

                   /* ---------------- PLACE ORDER BTN ---------------- */
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                       onPressed: _isPlacingOrder ? null : () => _placeOrder(appState, grandTotal),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFFE50914),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       child: _isPlacingOrder 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Place Order • ₹$grandTotal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   )
                ],
              ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false, bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
            fontSize: isBold ? 16 : 14,
            color: isBlue ? Colors.blue : Colors.black
          )),
        ],
      ),
    );
  }

  Future<void> _placeOrder(AppState appState, double totalAmount) async {
    if (_addressController.text.isEmpty || _areaController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all address details")));
        return;
    }
    
    // Validate slot selection only if Normal Delivery
    if (_deliveryType == 'Normal' && _selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a delivery slot")));
        return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final orderData = {
        'items': appState.cartItems.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'deliveryType': _deliveryType,
        'deliverySlot': _deliveryType == 'Fast' ? 'By Today' : _selectedSlot,
        'gstNumber': _companyGst,
        'address': _addressController.text.trim(),
        'area': _areaController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userId': user?.uid,
        'userName': appState.userName ?? 'User',
        'status': 'Pending',
        'paymentMethod': 'COD',
        'createdAt': FieldValue.serverTimestamp(),
        // Keep legacy fields for backward compatibility if needed, or remove
        'productName': appState.cartItems.length == 1 ? appState.cartItems.first.name : 'Multiple Items',
        'quantity': appState.totalCartItems,
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Decrement stock for each item
      for (var item in appState.cartItems) {
         try {
           await FirebaseFirestore.instance.collection('products').doc(item.id).update({
             'stock': FieldValue.increment(-item.quantity)
           });
         } catch (e) {
           print("Error updating stock for ${item.name}: $e");
         }
      }

      appState.clearCart();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!")));
      Navigator.pop(context); // Go back to products

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to place order: $e")));
    } finally {
       if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}