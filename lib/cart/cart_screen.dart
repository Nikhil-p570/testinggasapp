import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/app_state.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const CartScreen({super.key, required this.product});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

enum OrderType { newCylinder, refill }

class _CartScreenState extends State<CartScreen> {
  int _quantity = 1;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isPlacingOrder = false;
  String? _userName;
  String? _userId;
  
  OrderType _selectedOrderType = OrderType.newCylinder;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
  final userState = Provider.of<AppState>(context, listen: false);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser != null) {
    _userId = currentUser.uid;
    try {
      // Query users collection by uid field instead of using it as document ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        final phone = userData['phone'] ?? '';
        final phoneWithoutCountryCode = phone.replaceAll('+91', '');
        
        setState(() {
          _phoneController.text = phoneWithoutCountryCode;
          _addressController.text = userData['address'] ?? '';
          _areaController.text = userData['area'] ?? '';
          _userName = userData['name'] ?? 'Customer';
        });
        
        userState.setUser(
          uid: currentUser.uid,
          phone: phoneWithoutCountryCode,
          name: userData['name'] ?? 'Customer',
        );
        
        print("✅ User data loaded from Firestore");
      } else {
        print("ℹ️ No user document found in Firestore");
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }
}

  double _getCurrentPrice() {
    if (widget.product == null) return 0;
    
    if (_selectedOrderType == OrderType.newCylinder) {
      return (widget.product!['price'] ?? 1800).toDouble();
    } else {
      return (widget.product!['refillPrice'] ?? 900).toDouble();
    }
  }

  String _getOrderTypeString() {
    return _selectedOrderType == OrderType.newCylinder ? 'new_cylinder' : 'refill';
  }

  void _incrementQuantity() {
    if (widget.product != null) {
      final stock = widget.product!['stock'] ?? 100;
      if (_quantity < stock) {
        setState(() {
          _quantity++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot exceed available stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _appendOrderIdToUser(String orderId, String userId) async {
  try {
    // QUERY to find user document by uid field
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("⚠️ No user document found with uid: $userId");
      // Create a new document with uid as the field
      final newDocRef = FirebaseFirestore.instance.collection('users').doc();
      await newDocRef.set({
        'uid': userId,
        'orders_placed': [orderId],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      print("✅ Created new user document with auto-generated ID");
    } else {
      // Found existing user document
      final userDoc = querySnapshot.docs.first;
      await userDoc.reference.update({
        'orders_placed': FieldValue.arrayUnion([orderId]),
        'updatedAt': Timestamp.now(),
      });
      print("✅ Updated existing user document with ID: ${userDoc.id}");
    }
    
  } catch (error) {
    print("❌ Error appending orderId to user: $error");
    rethrow;
  }
}

  Future<void> _placeOrder() async {
    if (widget.product == null) {
      _showError('No product selected');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showError('Please enter your address');
      return;
    }

    if (_areaController.text.trim().isEmpty) {
      _showError('Please enter your area');
      return;
    }

    if (_phoneController.text.trim().isEmpty || _phoneController.text.trim().length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final userState = Provider.of<AppState>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      final product = widget.product!;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      String userName = _userName ?? userState.userName ?? 'Customer';
      final userId = currentUser.uid;
      
      final currentPrice = _getCurrentPrice();
      final totalPrice = currentPrice * _quantity;
      
      // Step 1: Create order record in orders collection
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'productId': product['id'],
        'productName': product['name'] ?? 'LPG Cylinder',
        'weight': product['weight'] ?? '19.5 kg',
        'quantity': _quantity,
        'price': totalPrice,
        'unitPrice': currentPrice,
        'orderType': _getOrderTypeString(),
        'address': _addressController.text.trim(),
        'area': _areaController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userName': userName,
        'uid': userId, // Store uid in order record
        'orderStatus': 'pending',
        'paymentStatus': 'pending',
        'paymentMethod': 'COD',
        'deliverySlot': 'Standard (Tomorrow)',
        'agentId': '',
        'assignedAgentId': '',
        'createdAt': Timestamp.now(),
        'assignedAt': null,
      });

      final orderId = orderRef.id;
      
      // Step 2: Update product stock if needed
      if (_selectedOrderType == OrderType.newCylinder) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product['id'])
            .update({
          'stock': FieldValue.increment(-_quantity),
        });
      }

      // Step 3: Append the order ID to the user's orders_placed field
      await _appendOrderIdToUser(orderId, userId);

      // Update local state
      userState.setOrder(
        orderId: orderId,
        status: 'pending',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (error) {
      print("❌ Error placing order: $error");
      if (mounted) {
        _showError('Error placing order: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currentPrice = _getCurrentPrice();
    final totalPrice = currentPrice * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product != null ? 'Place Order' : 'Cart',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: product == null
          ? const Center(
              child: Text(
                'No product selected',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE5E2),
                                  borderRadius: BorderRadius.circular(8),
                                  image: product['imageUrl'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(product['imageUrl']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: product['imageUrl'] == null
                                    ? const Icon(
                                        Icons.propane_tank,
                                        size: 40,
                                        color: Color(0xFFFF5C4D),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'LPG Cylinder',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product['weight'] ?? '19.5 kg',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${currentPrice.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE50914),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          
                          const Text(
                            'Order Type:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<OrderType>(
                                  title: const Text('New Cylinder'),
                                  value: OrderType.newCylinder,
                                  groupValue: _selectedOrderType,
                                  onChanged: (OrderType? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedOrderType = value;
                                      });
                                    }
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  tileColor: Colors.grey[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RadioListTile<OrderType>(
                                  title: const Text('Refill'),
                                  value: OrderType.refill,
                                  groupValue: _selectedOrderType,
                                  onChanged: (OrderType? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedOrderType = value;
                                      });
                                    }
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  tileColor: Colors.grey[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedOrderType == OrderType.newCylinder 
                                          ? 'New Cylinder Price:' 
                                          : 'Refill Price:',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '₹${currentPrice.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Quantity:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '× $_quantity',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹$totalPrice',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE50914),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _decrementQuantity,
                                    icon: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.remove, size: 20),
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _incrementQuantity,
                                    icon: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE50914),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.add, size: 20, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Price:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹$totalPrice',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE50914),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Delivery Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'Enter your complete address',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _areaController,
                    decoration: InputDecoration(
                      labelText: 'Area/Locality',
                      hintText: 'Enter your area or locality',
                      prefixIcon: const Icon(Icons.map),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isPlacingOrder
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Placing Order...',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            )
                          : const Text(
                              'PLACE ORDER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Important Information:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedOrderType == OrderType.newCylinder
                              ? '• Your new cylinder will be delivered within 24 hours.\n• Payment is cash on delivery.\n• ₹${product['price'] ?? 1800} is for the new cylinder purchase.'
                              : '• Your cylinder refill will be delivered within 24 hours.\n• Payment is cash on delivery.\n• ₹${product['refillPrice'] ?? 900} is for the refill service.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}