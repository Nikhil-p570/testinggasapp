import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String weight;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.weight,
    this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'weight': weight,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        weight: json['weight'],
        imageUrl: json['imageUrl'],
        quantity: json['quantity'],
      );
}

class AppState extends ChangeNotifier {
  /* ---------------- USER ---------------- */
  String? userId;
  String? phoneNumber;
  String? userName;

  void setUser({
    required String uid,
    required String phone,
    String? name,
  }) {
    userId = uid;
    phoneNumber = phone;
    userName = name;
    notifyListeners();
  }

  void clearUser() {
    userId = null;
    phoneNumber = null;
    userName = null;
    clearCart();
    notifyListeners();
  }

  /* ---------------- NEW PRODUCT / CART LOGIC ---------------- */
  bool isRefillMode = true; // Default to Refill
  
  void toggleOrderType(bool isRefill) {
    isRefillMode = isRefill;
    // When switching modes, maybe update prices in cart? 
    // For simplicity, let's clear cart to avoid confusion or just update prices if logical.
    // user likely wants to start fresh if switching major modes.
    clearCart(); 
    notifyListeners();
  }

  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  int get totalCartItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalCartValue => _cartItems.fold(0, (sum, item) => sum + item.total);

  void addToCart(Map<String, dynamic> product) {
    // Check if item already exists
    final index = _cartItems.indexWhere((item) => item.id == product['id']);
    
    if (index >= 0) {
      _cartItems[index].quantity++;
    } else {
      _cartItems.add(CartItem(
        id: product['id'],
        name: product['name'] ?? 'LPG Cylinder',
        price: (product['price'] as num).toDouble(), // Ensure double
        weight: product['weight'] ?? '14.2 kg',
        imageUrl: product['imageUrl'],
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int getItemQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    return index >= 0 ? _cartItems[index].quantity : 0;
  }

  /* ---------------- ADDRESS ---------------- */
  String? addressLabel;
  String? fullAddress;
  double? lat;
  double? lng;

  void setAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    addressLabel = label;
    fullAddress = address;
    lat = latitude;
    lng = longitude;
    notifyListeners();
  }

  void setSimpleAddress(String address, String area) {
    fullAddress = address;
    addressLabel = area;
    notifyListeners();
  }

  String get formattedAddress => fullAddress ?? 'No address set';

  /* ---------------- ORDER ---------------- */
  String? currentOrderId;
  String orderStatus = "created";

  void setOrder({required String orderId, required String status}) {
    currentOrderId = orderId;
    orderStatus = status;
    notifyListeners();
  }
}
