import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data();
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _areaController.text = userData['area'] ?? '';
          });
        }
      } catch (e) {
        print("Error loading profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _addressController.text.isEmpty || 
        _areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            querySnapshot.docs.first.reference.update({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'address': _addressController.text.trim(),
              'area': _areaController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        print("Error saving profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              final userState = Provider.of<AppState>(context, listen: false);
              userState.clearUser();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area/Locality',
                      prefixIcon: Icon(Icons.map),
                    ),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 30),
                  
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE50914),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('SAVE PROFILE'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _loadUserProfile();
                              });
                            },
                            child: const Text('CANCEL'),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 10),
                          Text('LOGOUT'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}