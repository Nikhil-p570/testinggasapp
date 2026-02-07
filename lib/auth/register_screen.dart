import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? prefilledPhone;
  
  const RegisterScreen({super.key, this.prefilledPhone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  bool isLoading = false;
  bool _isPhoneChecking = false;

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
        _isPhoneChecking = true;
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
        _isPhoneChecking = false;
      });
    }
  }

  void sendOtpForRegister() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final area = areaController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit phone number")),
      );
      return;
    }

    setState(() => isLoading = true);

    final phoneExists = await _checkPhoneNumberExists(phone);

    if (phoneExists) {
      setState(() => isLoading = false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Already Registered"),
          content: Text(
            "The phone number +91$phone is already registered. "
            "Please login instead.",
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
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("Go to Login"),
            ),
          ],
        ),
      );
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91$phone", 
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "OTP verification failed")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              isLogin: false,
               name: name,
                address: address,
                area: area,
                phone: phone,
              // Only include parameters that exist in OtpScreen constructor
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() => isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            Stack(
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixText: "+91 ",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_isPhoneChecking)
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
            const SizedBox(height: 16),
            
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Delivery Address",
                hintText: "House no, Street, City",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: areaController,
              decoration: const InputDecoration(
                labelText: "Area/Locality",
                hintText: "Enter your area or locality name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading || _isPhoneChecking ? null : sendOtpForRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Register & Verify",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            if (_isPhoneChecking)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Checking phone number...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}