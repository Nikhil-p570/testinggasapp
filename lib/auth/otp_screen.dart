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

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  String? _errorMessage;
  String? _displayPhone;
  Timer? _timer;
  int _countdown = 30;
  bool _canResend = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _displayPhone = widget.phone;
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
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
        if (widget.isLogin) {
          print("✅ Login successful for user: ${userCredential.user!.uid}");

          if (Provider.of<AppState>(context, listen: false) != null) {
            Provider.of<AppState>(context, listen: false).setUser(
              uid: userCredential.user!.uid,
              phone: widget.phone ?? '',
            );
          }

          Navigator.pushNamedAndRemoveUntil(
              context, '/products', (route) => false);
        } else {
          print("✅ OTP verified. Creating user document...");

          try {
            await _saveUserToFirestore(userCredential.user!);

            try {
              if (Provider.of<AppState>(context, listen: false) != null) {
                Provider.of<AppState>(context, listen: false).setUser(
                  uid: userCredential.user!.uid,
                  phone: widget.phone ?? '',
                  name: widget.name,
                );
              }
            } catch (providerError) {
              print(
                  "⚠️ AppState provider error (but user created): $providerError");
            }

            print("✅ Registration complete. Navigating to home screen");

            try {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/products', (route) => false);
            } catch (navError) {
              print("⚠️ Navigation error: $navError");
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/products', (route) => false);
            }
          } catch (e) {
            print("❌ Error during registration process: $e");

            setState(() {
              if (e.toString().contains("already registered")) {
                _errorMessage = "Phone already registered. Please login.";
              } else if (e.toString().contains("Firestore")) {
                _errorMessage = "Registration error. Please contact support.";
              } else {
                _errorMessage = "Registration failed. Please try again.";
              }
              _isVerifying = false;
            });

            try {
              final checkUser = await FirebaseFirestore.instance
                  .collection('users')
                  .where('phone', isEqualTo: "+91${widget.phone ?? ''}")
                  .limit(1)
                  .get();

              if (checkUser.docs.isEmpty) {
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
      print("❌ OTP verification failed: $e");

      setState(() {
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

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');

      final phoneCheck = await users
          .where('phone', isEqualTo: "+91${widget.phone ?? ''}")
          .limit(1)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        throw Exception("Phone number already registered");
      }

      await users.add({
        'uid': user.uid,
        'name': widget.name ?? '',
        'phone': "+91${widget.phone ?? ''}",
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
    _animationController.dispose();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EAF6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      color: const Color(0xFF283593),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF283593), Color(0xFF5C6BC0)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF283593).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        "Verify OTP",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _displayPhone == null || _displayPhone!.isEmpty
                            ? "Sending OTP..."
                            : "Code sent to +91 $_displayPhone",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (i) {
                              return Container(
                                width: 48,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _otpControllers[i].text.isNotEmpty
                                        ? const Color(0xFF283593)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _otpControllers[i],
                                  focusNode: _focusNodes[i],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF283593),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (v) => _onOtpChange(i, v),
                                ),
                              );
                            }),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isVerifying ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF283593),
                                elevation: 8,
                                shadowColor:
                                    const Color(0xFF283593).withOpacity(0.4),
                              ),
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Verify OTP",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: _canResend
                                ? TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _countdown = 30;
                                        _canResend = false;
                                        _startTimer();
                                      });
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text("Resend OTP"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF283593),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 18,
                                          color: Color(0xFF283593),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Resend in $_countdown s",
                                          style: const TextStyle(
                                            color: Color(0xFF283593),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
