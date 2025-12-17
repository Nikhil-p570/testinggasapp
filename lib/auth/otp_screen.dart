import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final bool isLogin;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.isLogin,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOtpAndProceed() async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter 6-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔐 VERIFY OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) return;

      // 🔥 SAVE USER ONLY IF REGISTER FLOW
      if (!widget.isLogin) {
        final userDoc =
        FirebaseFirestore.instance.collection("users").doc(user.uid);

        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            "uid": user.uid,
            "phone": user.phoneNumber,
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }

      // ✅ NAVIGATE TO HOME
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        
        const SnackBar(content: Text("Invalid OTP")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Verify OTP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOtpAndProceed,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify & Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
