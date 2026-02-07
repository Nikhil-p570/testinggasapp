import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:flutter/services.dart';

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
  String? _displayPhone;
  Timer? _timer;
  int _countdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _displayPhone = widget.phone;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _onOtpChange(int index, String value) {
    if (value.length > 1) {
      final otp = value.substring(0, 6);
      for (int i = 0; i < otp.length; i++) {
        _otpControllers[i].text = otp[i];
      }
      _focusNodes[5].requestFocus();
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ========== OTP VERIFICATION METHOD ==========
  Future<void> _verifyOtp() async {
  final otp = _otpControllers.map((e) => e.text).join();
    print("🔄 _verifyOtp called. isLogin: ${widget.isLogin}, OTP: $otp");
print("📱 Phone: ${widget.phone}, Name: ${widget.name}");

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
      // ========== LOGIN FLOW ==========
      if (widget.isLogin) {
        print("✅ Login successful for user: ${userCredential.user!.uid}");
        
        // Check if AppState provider exists
        if (Provider.of<AppState>(context, listen: false) != null) {
          Provider.of<AppState>(context, listen: false).setUser(
            uid: userCredential.user!.uid,
            phone: widget.phone ?? '',
          );
        }
        
        // Navigate safely
        Navigator.pushNamedAndRemoveUntil(
            context, '/products', (route) => false);
      } 
      // ========== REGISTER FLOW ==========
      else {
        print("✅ OTP verified. Creating user document...");
        
        try {
          // CREATE USER IN FIRESTORE
          await _saveUserToFirestore(userCredential.user!);
          
          // Update app state safely
          try {
            if (Provider.of<AppState>(context, listen: false) != null) {
              Provider.of<AppState>(context, listen: false).setUser(
                uid: userCredential.user!.uid,
                phone: widget.phone ?? '',
                name: widget.name,
              );
            }
          } catch (providerError) {
            print("⚠️ AppState provider error (but user created): $providerError");
            // Continue anyway since user is created
          }
          
          print("✅ Registration complete. Navigating to home screen");
          
          // Navigate safely - wrap in try-catch
          try {
            Navigator.pushNamedAndRemoveUntil(
                context, '/products', (route) => false);
          } catch (navError) {
            print("⚠️ Navigation error: $navError");
            // Fallback navigation
            Navigator.of(context).pushNamedAndRemoveUntil('/products', (route) => false);
          }
          
        } catch (e) {
          print("❌ Error during registration process: $e");
          
          // DON'T sign out immediately - check if user was created
          
          setState(() {
            // Show specific error message
            if (e.toString().contains("already registered")) {
              _errorMessage = "Phone already registered. Please login.";
            } else if (e.toString().contains("Firestore")) {
              _errorMessage = "Registration error. Please contact support.";
            } else {
              _errorMessage = "Registration failed. Please try again.";
            }
            _isVerifying = false;
          });
          
          // Only sign out if we didn't create the user
          // Let's check Firestore first
          try {
            final checkUser = await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: "+91${widget.phone ?? ''}")
                .limit(1)
                .get();
                
            if (checkUser.docs.isEmpty) {
              // User not created, safe to sign out
              await FirebaseAuth.instance.signOut();
              print("⚠️ Signed out - user not created in Firestore");
            } else {
              print("⚠️ User exists in Firestore - keeping auth session");
            }
          } catch (checkError) {
            print("⚠️ Error checking user existence: $checkError");
            await FirebaseAuth.instance.signOut();
          }
        }
      }
    }
  } catch (e) {
    // THIS CATCHES OTP VERIFICATION ERRORS
    print("❌ OTP verification failed: $e");
    
    setState(() {
      // Check error type
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          _errorMessage = "Invalid OTP. Please try again.";
        } else if (e.code == 'session-expired') {
          _errorMessage = "OTP expired. Please resend.";
        } else {
          _errorMessage = "OTP error: ${e.message}";
        }
      } else {
        _errorMessage = "OTP verification failed. Try again.";
      }
      _isVerifying = false;
    });
  }
}
  // ========== SAVE USER TO FIRESTORE (FOR REGISTRATION ONLY) ==========
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');
      
      // Safety check: Ensure phone doesn't already exist
      final phoneCheck = await users
          .where('phone', isEqualTo: "+91${widget.phone ?? ''}")
          .limit(1)
          .get();
      
      if (phoneCheck.docs.isNotEmpty) {
        throw Exception("Phone number already registered");
      }
      
      // Create new user document
      await users.add({
        'uid': user.uid,
        'name': widget.name ?? '',
        'phone': "+91${widget.phone ?? ''}", // Add +91 prefix
        'address': widget.address ?? '',
        'area': widget.area ?? '',
        'orders_placed': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print("✅ User document created successfully for: +91${widget.phone}");
    } catch (e) {
      print("❌ Error in _saveUserToFirestore: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
            const Text("Enter OTP",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              _displayPhone == null || _displayPhone!.isEmpty
                  ? "Sending OTP..."
                  : "OTP sent to +91$_displayPhone",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) => _onOtpChange(i, v),
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify OTP"),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: () {
                        setState(() {
                          _countdown = 30;
                          _canResend = false;
                          _startTimer();
                        });
                      },
                      child: const Text("Resend OTP"),
                    )
                  : Text("Resend in $_countdown s"),
            ),
          ],
        ),
      ),
    );
  }
}