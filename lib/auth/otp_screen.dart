import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final bool isLogin;
  final String? name;
  final String? address;
  final String? area;
  final String? phone;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.isLogin,
    this.name,
    this.address,
    this.area,
    this.phone,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = "Enter 6-digit OTP");
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        if (widget.isLogin) {
          // LOGIN FLOW
          final userState = Provider.of<AppState>(context, listen: false);
          userState.setUser(
            uid: userCredential.user!.uid,
            phone: widget.phone ?? '',
          );
          Navigator.pushNamedAndRemoveUntil(context, '/products', (route) => false);
        } else {
          // REGISTER FLOW - SAVE TO FIRESTORE
          await _saveUserToFirestore(userCredential.user!);
          
          final userState = Provider.of<AppState>(context, listen: false);
          userState.setUser(
            uid: userCredential.user!.uid,
            phone: widget.phone ?? '',
            name: widget.name,
          );
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Invalid OTP";
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Something went wrong";
        _isVerifying = false;
      });
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'uid': user.uid,
        'name': widget.name ?? '',
        'phone': widget.phone != null ? "+91${widget.phone!}" : '',
        'address': widget.address ?? '',
        'area': widget.area ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving user to Firestore: $e");
      rethrow;
    }
  }

  void _onOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter OTP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLogin
                  ? "Enter the OTP sent to +91${widget.phone}"
                  : "Enter OTP to complete registration",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _onOtpChange(index, value),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 32),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Verify OTP",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Didn't receive OTP? Resend in 30s",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}