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

  void setUser({
    required String uid,
    required String phone,
  }) {
    userId = uid;
    phoneNumber = phone;
    notifyListeners();
  }

  void clearUser() {
    userId = null;
    phoneNumber = null;
    clearCart();
    notifyListeners();
  }

  /* ---------------- PRODUCT / CART ---------------- */
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

  /* ---------------- PAYMENT ---------------- */
  String paymentMode = "COD";

  void setPaymentMode(String mode) {
    paymentMode = mode;
    notifyListeners();
  }

  /* ---------------- ORDER ---------------- */
  String? currentOrderId;
  String orderStatus = "created";

  void setOrder({
    required String orderId,
    required String status,
  }) {
    currentOrderId = orderId;
    orderStatus = status;
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
    notifyListeners();
  }
}
