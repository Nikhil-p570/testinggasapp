import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isPlacingOrder = false;
  String _deliveryType = 'Normal';

  List<String> _availableSlots = [];
  String? _selectedSlot;

  final String _companyGst = "36AAAAA0000A1Z5";
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _calculateDetailSlots();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  void _calculateDetailSlots() {
    final now = TimeOfDay.now();

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

    if (_availableSlots.isNotEmpty) {
      _selectedSlot = _availableSlots.first;
    }
  }

  void _loadUserData() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.userId != null) {
      String phone = appState.phoneNumber ?? '';
      // Remove +91 prefix if present
      if (phone.startsWith('+91')) {
        phone = phone.substring(3).trim();
      }
      _phoneController.text = phone;
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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (doc.docs.isNotEmpty) {
          final data = doc.docs.first.data();
          String phone = data['phone'] ?? '';
          // Remove +91 prefix if present
          if (phone.startsWith('+91')) {
            phone = phone.substring(3).trim();
          }
          setState(() {
            _phoneController.text = phone;
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
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final cartItems = appState.cartItems;

    double itemTotal = appState.totalCartValue;
    double deliveryCharge = _deliveryType == 'Fast'
        ? (cartItems.fold(0, (sum, item) => sum + item.quantity) * 10).toDouble()
        : 0;
    double grandTotal = itemTotal + deliveryCharge;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Your Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF283593).withOpacity(0.1),
                          const Color(0xFFFF6F00).withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Color(0xFF283593),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* ---------------- CART ITEMS ---------------- */
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shopping_bag_rounded, color: Color(0xFF283593), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Cart Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartItems.length,
                            separatorBuilder: (context, index) => const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF283593).withOpacity(0.1),
                                          const Color(0xFFFF6F00).withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: item.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              item.imageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.propane_tank_rounded,
                                            color: Color(0xFF283593),
                                            size: 32,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.weight,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFF6F00), Color(0xFFF57C00)],
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '₹${item.price}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1A237E),  // Deep Blue
                                          Color(0xFF3949AB),  // Medium Blue
                                          Color(0xFFC62828),  // Deep Red
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_rounded,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => appState.removeFromCart(item.id),
                                          iconSize: 20,
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => appState.addToCart({
                                            'id': item.id,
                                            'name': item.name,
                                            'price': item.price,
                                            'weight': item.weight,
                                            'imageUrl': item.imageUrl
                                          }),
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /* ---------------- DELIVERY OPTIONS ---------------- */
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_shipping_rounded, color: Color(0xFF283593), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Delivery Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Normal Delivery
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _deliveryType = 'Normal';
                                if (_availableSlots.isNotEmpty && _selectedSlot == null) {
                                  _selectedSlot = _availableSlots.first;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _deliveryType == 'Normal'
                                    ? const Color(0xFF283593).withOpacity(0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _deliveryType == 'Normal'
                                      ? const Color(0xFF283593)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _deliveryType == 'Normal'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: _deliveryType == 'Normal'
                                            ? const Color(0xFF283593)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Normal Delivery',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Free',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_deliveryType == 'Normal') ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Select Time Slot',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF283593),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ..._availableSlots.map((slot) => GestureDetector(
                                          onTap: () => setState(() => _selectedSlot = slot),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: _selectedSlot == slot
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF1A237E),  // Deep Blue
                                                        Color(0xFF3949AB),  // Medium Blue
                                                        Color(0xFFC62828),  // Deep Red
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null,
                                              color: _selectedSlot == slot
                                                  ? null
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _selectedSlot == slot
                                                    ? const Color(0xFF283593)
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _selectedSlot == slot
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  size: 20,
                                                  color: _selectedSlot == slot
                                                      ? Colors.white
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  slot,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: _selectedSlot == slot
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontWeight: _selectedSlot == slot
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fast Delivery
                          GestureDetector(
                            onTap: () => setState(() => _deliveryType = 'Fast'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _deliveryType == 'Fast'
                                    ? const Color(0xFFFF6F00).withOpacity(0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _deliveryType == 'Fast'
                                      ? const Color(0xFFFF6F00)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _deliveryType == 'Fast'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: _deliveryType == 'Fast'
                                        ? const Color(0xFFFF6F00)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fast Delivery',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Delivery by today (+₹10/cylinder)',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /* ---------------- BILL DETAILS ---------------- */
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Color(0xFF283593), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Bill Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBillRow('Item Total', '₹$itemTotal'),
                          _buildBillRow('Delivery Charges', '₹$deliveryCharge', isBlue: true),
                          const Divider(height: 24),
                          _buildBillRow('Grand Total', '₹$grandTotal', isBold: true),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Company GSTIN: $_companyGst",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /* ---------------- ADDRESS INPUTS ---------------- */
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: Color(0xFF283593), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Full Address',
                              prefixIcon: Icon(Icons.home_rounded, color: Color(0xFF283593)),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Area / Locality',
                              prefixIcon: Icon(Icons.map_rounded, color: Color(0xFF283593)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              prefixIcon: Icon(Icons.phone_rounded, color: Color(0xFF283593)),
                              prefixText: '+91 ',
                              prefixStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    /* ---------------- PLACE ORDER BTN ---------------- */
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder
                            ? null
                            : () => _placeOrder(appState, grandTotal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F00),
                          elevation: 12,
                          shadowColor: const Color(0xFFFF6F00).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Place Order • ₹$grandTotal',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBillRow(String label, String value,
      {bool isBold = false, bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? const Color(0xFF1A237E) : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 18 : 14,
              color: isBlue
                  ? Colors.blue
                  : isBold
                      ? const Color(0xFFFF6F00)
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(AppState appState, double totalAmount) async {
    if (_addressController.text.isEmpty ||
        _areaController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all address details"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_deliveryType == 'Normal' && _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select a delivery slot"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        'productName': appState.cartItems.length == 1
            ? appState.cartItems.first.name
            : 'Multiple Items',
        'quantity': appState.totalCartItems,
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      for (var item in appState.cartItems) {
        try {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(item.id)
              .update({
            'stock': FieldValue.increment(-item.quantity)
          });
        } catch (e) {
          print("Error updating stock for ${item.name}: $e");
        }
      }

      appState.clearCart();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Order Placed Successfully!"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to place order: $e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}
