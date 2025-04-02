import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../state/AuthProvider.dart';
import '../models/UserModel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String _statusMessage = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _populateUserData();
  }

  void _populateUserData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email ?? "";
      _phoneController.text = auth.userPhoneNumber ?? "";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userPhone = auth.userPhoneNumber;

    if (userPhone == null) {
      setState(
          () => _statusMessage = "User session expired. Please log in again.");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhone)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      if (auth.currentUser != null) {
        auth.currentUser = UserModel(
          name: _nameController.text.trim(),
          dob: auth.currentUser!.dob,
          city: auth.currentUser!.city,
          educationLevel: auth.currentUser!.educationLevel,
          board: auth.currentUser!.board,
          school: auth.currentUser!.school,
          userType: auth.currentUser!.userType,
          createdAt: auth.currentUser!.createdAt,
        );
        auth.currentUser!.email = _emailController.text.trim();
        auth.notifyListeners();
      }

      setState(() => _statusMessage = "Profile updated successfully!");
    } catch (e) {
      setState(() => _statusMessage = "Failed to update profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Please log in to view your profile"),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Profile" : "My Profile"),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Stack(
        children: [
          _isEditing ? _buildEditView() : _buildProfileView(),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileHeader(user),
        const SizedBox(height: 24),
        _buildInfoCard(user),
        const SizedBox(height: 24),
        _buildActionButtons(),
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains("success")
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: const AssetImage("assets/promogirl.png"),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          user.email ?? "No email provided",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Phone", _phoneController.text),
            _buildInfoRow("Date of Birth", user.dob),
            _buildInfoRow("City", user.city),
            _buildInfoRow("Education", user.educationLevel),
            _buildInfoRow("School", user.school),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          child: const Text("Settings"),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).currentUser =
                null;
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text("Log Out"),
        ),
      ],
    );
  }

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField("Name", _nameController),
          const SizedBox(height: 16),
          _buildTextField("Email", _emailController),
          const SizedBox(height: 16),
          _buildTextField("Phone", _phoneController, enabled: false),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveProfile();
                    setState(() => _isEditing = false);
                  },
                  child: const Text("Save"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _populateUserData();
                  }),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage.contains("success")
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
      ),
    );
  }
}
