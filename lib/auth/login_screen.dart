import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledPhone;

  const LoginScreen({super.key, this.prefilledPhone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _isChecking = false;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPhone != null) {
      phoneController.text = widget.prefilledPhone!;
    }
  }

  Future<bool> _checkPhoneNumberExists(String phone) async {
    try {
      setState(() {
        _isChecking = true;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: "+91$phone")
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking phone number: $e");
      return false;
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void sendOtp(BuildContext context) async {
    final phone = phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit number")),
      );
      return;
    }

    setState(() {
      _isChecking = true;
    });

    final phoneExists = await _checkPhoneNumberExists(phone);

    if (!phoneExists) {
      setState(() {
        _isChecking = false;
      });
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text("Not Registered"),
            ],
          ),
          content: Text(
            "The phone number +91$phone is not registered. "
            "Please register first to create an account.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(prefilledPhone: phone),
                  ),
                );
              },
              child: const Text("Go to Register"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91$phone",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isSendingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Verification failed")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isSendingOtp = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              isLogin: true,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isSendingOtp = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back 👋",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            Stack(
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    prefixText: "+91 ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                if (_isChecking)
                  Positioned(
                    right: 10,
                    top: 15,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isChecking || _isSendingOtp) ? null : () => sendOtp(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSendingOtp
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
                          Text("Sending OTP..."),
                        ],
                      )
                    : const Text(
                        "Login",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Checking phone number...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}