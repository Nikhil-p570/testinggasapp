import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createOrder({
    required String productId,
    required String productName,
    required int quantity,
    required bool isRefill,
    required int totalAmount,
    required String paymentMode,
    required Map<String, dynamic> address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final docRef = await _db.collection('orders').add({
      'userId': user.uid,
      'agentId': null,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'orderType': isRefill ? 'refill' : 'new',
      'price': totalAmount,
      'paymentMode': paymentMode,
      'paymentStatus': 'pending',
      'orderStatus': 'created',
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
      'liveTracking': false,
    });

    return docRef.id;
  }
}
