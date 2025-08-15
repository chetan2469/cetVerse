import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:cet_verse/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/ui/theme/constants.dart';

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
          email: _emailController.text.trim(),
          dob: auth.currentUser!.dob,
          city: auth.currentUser!.city,
          educationLevel: auth.currentUser!.educationLevel,
          board: auth.currentUser!.board,
          school: auth.currentUser!.school,
          userType: auth.currentUser!.userType,
          createdAt: auth.currentUser!.createdAt,
          subscription: auth.currentUser!.subscription,
          features: auth.currentUser!.features,
        );
        auth.notifyListeners();
      }

      setState(() {
        _statusMessage = "Profile updated successfully!";
        _isEditing = false;
      });
    } catch (e) {
      setState(() => _statusMessage = "Failed to update profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await auth.clearSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PhoneAuthScreen()),
        );
      } catch (e) {
        setState(() => _statusMessage = "Failed to log out: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.indigo,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                auth.errorMessage ?? 'Please log in to view your profile',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (auth.userPhoneNumber != null) {
                    auth.fetchUserData(auth.userPhoneNumber!);
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Profile" : "My Profile",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isEditing ? _buildEditView() : _buildProfileView(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.indigo)),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildPersonalInfoCard(user),
          const SizedBox(height: 16),
          _buildSubscriptionCard(user),
          const SizedBox(height: 16),
          _buildFeaturesCard(user),
          const SizedBox(height: 24),
          _buildActionButtons(),
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: _statusMessage.contains("success")
                      ? Colors.green
                      : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.indigo.shade300,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: AppTheme.subheadingStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email ?? 'No email provided',
            style: AppTheme.captionStyle
                .copyWith(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const Divider(color: Colors.grey, thickness: 1),
            _buildInfoRow('Phone', _phoneController.text),
            _buildInfoRow('Date of Birth', user.dob),
            _buildInfoRow('City', user.city),
            _buildInfoRow('Education Level', user.educationLevel),
            _buildInfoRow('Board', user.board),
            _buildInfoRow('School', user.school),
            _buildInfoRow('User Type', user.userType),
            _buildInfoRow(
              'Joined',
              user.createdAt != null
                  ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const Divider(color: Colors.grey, thickness: 1),
            _buildInfoRow('Plan Type', user.subscription['planType'] ?? 'None'),
            _buildInfoRow('Status', user.subscription['status'] ?? 'Inactive'),
            _buildInfoRow(
              'Start Date',
              user.subscription['startDate'] is Timestamp
                  ? DateFormat('MMM dd, yyyy').format(
                      (user.subscription['startDate'] as Timestamp).toDate())
                  : 'N/A',
            ),
            _buildInfoRow(
              'End Date',
              user.subscription['endDate'] is Timestamp
                  ? DateFormat('MMM dd, yyyy').format(
                      (user.subscription['endDate'] as Timestamp).toDate())
                  : 'N/A',
            ),
            _buildInfoRow(
              'Amount Paid',
              '\$${user.subscription['amountPaid'] ?? 0}',
            ),
            _buildInfoRow(
              'Payment Method',
              user.subscription['paymentMethod'] ?? 'None',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Access',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const Divider(color: Colors.grey, thickness: 1),
            _buildFeatureRow(
              'Board PYQs Access',
              user.features['boardPyqsAccess'] ?? false,
            ),
            _buildFeatureRow(
              'Chapter-wise Notes Access',
              user.features['chapterWiseNotesAccess'] ?? false,
            ),
            _buildFeatureRow(
              'Full Mock Test Series',
              user.features['fullMockTestSeries'] ?? false,
            ),
            _buildInfoRow(
              'MHT CET PYQs Access',
              user.features['mhtCetPyqsAccess'] ?? 'None',
            ),
            _buildInfoRow(
              'Mock Tests per Subject',
              user.features['mockTestsPerSubject']?.toString() ?? '0',
            ),
            _buildFeatureRow(
              'Performance Tracking',
              user.features['performanceTracking'] ?? false,
            ),
            _buildFeatureRow(
              'Priority Feature Access',
              user.features['priorityFeatureAccess'] ?? false,
            ),
            _buildFeatureRow(
              'Topper Notes Download',
              user.features['topperNotesDownload'] ?? false,
            ),
            _buildInfoRow(
              'Topper Profiles Access',
              user.features['topperProfilesAccess'] ?? 'None',
            ),
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
          Text(
            label,
            style: AppTheme.captionStyle
                .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: AppTheme.captionStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.captionStyle
                .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Settings", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Log Out",
                  style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Profile',
                style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 16),
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
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Save", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _isEditing = false;
                        _populateUserData();
                      }),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          const Text("Cancel", style: TextStyle(fontSize: 16)),
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
                      fontSize: 14,
                      color: _statusMessage.contains("success")
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
