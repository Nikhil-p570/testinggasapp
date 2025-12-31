import 'package:flutter/material.dart';

/// AppState manages global state for the CUSTOMER app
/// - Selected product
/// - Cart data
/// - Address
/// - Payment mode
/// - Order status
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

  /* ---------------- PRODUCT / CART ---------------- */
  Map<String, dynamic>? selectedProduct;
  
  void selectProduct(Map<String, dynamic> product) {
    selectedProduct = product;
    addToCart(
      id: product['id'],
      name: product['name'] ?? 'LPG Cylinder',
      price: product['price']?.toInt() ?? 951,
      refill: true,
      qty: 1,
    );
    notifyListeners();
  }

  void clearSelectedProduct() {
    selectedProduct = null;
    notifyListeners();
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

  /* ---------------- PAYMENT ---------------- */
  String paymentMode = "COD";

  void setPaymentMode(String mode) {
    paymentMode = mode;
    notifyListeners();
  }

  /* ---------------- ORDER ---------------- */
  String? currentOrderId;
  String orderStatus = "created";
  List<String> orderHistory = []; // You can use this for local order history

  void setOrder({
    required String orderId,
    required String status,
  }) {
    currentOrderId = orderId;
    orderStatus = status;
    orderHistory.add(orderId); // Add to local history
    notifyListeners();
  }

  void updateOrderStatus(String status) {
    orderStatus = status;
    notifyListeners();
  }

  void clearOrder() {
    currentOrderId = null;
    orderStatus = "created";
    clearCart();
    clearSelectedProduct();
    notifyListeners();
  }

  /* ---------------- CART METHODS ---------------- */
  String? productId;
  String? productName;
  int pricePerUnit = 0;
  bool isRefill = true;
  int quantity = 1;

  void addToCart({
    required String id,
    required String name,
    required int price,
    required bool refill,
    int qty = 1,
  }) {
    productId = id;
    productName = name;
    pricePerUnit = price;
    isRefill = refill;
    quantity = qty;
    notifyListeners();
  }

  void increaseQty() {
    quantity++;
    notifyListeners();
  }

  void decreaseQty() {
    if (quantity > 1) {
      quantity--;
      notifyListeners();
    }
  }

  int get totalAmount => pricePerUnit * quantity;

  void clearCart() {
    productId = null;
    productName = null;
    pricePerUnit = 0;
    isRefill = true;
    quantity = 1;
  }
  
  /* ---------------- HELPER GETTERS ---------------- */
  String? get name => userName;
  
  bool get hasUserData => userId != null && phoneNumber != null;
}