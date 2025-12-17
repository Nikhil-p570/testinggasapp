import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String verificationId = "";

  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String) codeSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Phone number error");
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          codeSent(verId);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<User?> verifyOTP(String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      if (kDebugMode) print("OTP error: $e");
      return null;
    }
  }
}
