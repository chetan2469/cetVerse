// lib/pages/profile_page.dart  (adjust path as needed)
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:cet_verse/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/ui/theme/constants.dart';

// If you have a concrete PricingPage widget file, import it.
// Otherwise this code navigates via route name '/pricing'.

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _statusMessage = "";
  bool _saving = false;

  final _inrFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _populateFromProvider();
  }

  void _populateFromProvider() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = auth.userPhoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final phone = auth.userPhoneNumber;
    if (phone == null) {
      setState(() => _statusMessage = "Session expired. Please log in again.");
      return;
    }

    setState(() {
      _saving = true;
      _statusMessage = "";
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(phone).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      // reflect locally in UserModel the minimal changes
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
      setState(() => _statusMessage = "Failed to update: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await auth.clearSession();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
    } catch (e) {
      setState(() => _statusMessage = "Failed to log out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.indigo, strokeWidth: 3),
              SizedBox(height: 16),
              Text('Loading profile...',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
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
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                auth.errorMessage ?? 'Please log in to view your profile',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final p = auth.userPhoneNumber;
                  if (p != null) {
                    auth.fetchUserData(p);
                  } else {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PhoneAuthScreen()));
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final plan = auth.getPlanType ?? 'Starter';
    final status = auth.subscriptionStatus ?? 'inactive';
    final isPro = auth.isPro;
    final isPlus = auth.isPlus;

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
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: () {
                final p = auth.userPhoneNumber;
                if (p != null) auth.fetchUserData(p);
              },
            ),
          if (!_isEditing)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: () {
                _populateFromProvider();
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderCard(
                  name: user.name,
                  email: user.email,
                  planType: plan,
                  status: status,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                  child: _personalInfoCard(user, _phoneController.text)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _subscriptionCard(auth)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _featuresCard(auth)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _actionRow(onLogout: _logout)),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Use route if registered
                            Navigator.pushNamed(context, '/pricing')
                                .onError((_, __) {
                              // Or show a snackbar if route missing
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Add route /pricing to navigate to PricingPage')),
                              );
                              return null;
                            });
                          },
                          icon: Icon(isPro
                              ? Icons.verified
                              : (isPlus ? Icons.star_half : Icons.lock_open)),
                          label: Text(isPro ? 'Manage Plan' : 'Upgrade Plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_statusMessage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color:
                              _statusMessage.toLowerCase().contains('success')
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          if (_isEditing) _editSheet(),
          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.indigo)),
            ),
        ],
      ),
    );
  }

  // ---------- Cards ----------

  Widget _personalInfoCard(UserModel user, String phone) {
    return _CardWrap(
      title: 'Personal Information',
      child: Column(
        children: [
          _infoRow('Phone', phone),
          _infoRow('Date of Birth', user.dob),
          _infoRow('City', user.city),
          _infoRow('Education Level', user.educationLevel),
          _infoRow('Board', user.board),
          _infoRow('School', user.school),
          _infoRow(
            'Joined',
            user.createdAt != null
                ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _subscriptionCard(AuthProvider auth) {
    final start = auth.startDate;
    final end = auth.endDate;
    final amt =
        (auth.amountPaid is num) ? (auth.amountPaid as num).toDouble() : 0.0;

    return _CardWrap(
      title: 'Subscription',
      child: Column(
        children: [
          _infoRow('Plan', auth.getPlanType ?? 'Starter'),
          _infoRow('Status', auth.subscriptionStatus ?? 'Inactive'),
          _infoRow('Start Date',
              start != null ? DateFormat('MMM dd, yyyy').format(start) : 'N/A'),
          _infoRow('End Date',
              end != null ? DateFormat('MMM dd, yyyy').format(end) : 'N/A'),
          _infoRow('Amount Paid', _inrFmt.format(amt)),
          _infoRow('Payment Method', auth.paymentMethod ?? 'None'),
        ],
      ),
    );
  }

  Widget _featuresCard(AuthProvider auth) {
    // Use provider getters so Pro/full show correctly
    final mockTests = auth.mockTestsPerSubject >= 9999
        ? 'Unlimited'
        : auth.mockTestsPerSubject.toString();

    return _CardWrap(
      title: 'Feature Access',
      child: Column(
        children: [
          _toggleRow('Board PYQs', auth.boardPyqsAccess),
          _toggleRow('Chapter-wise Notes', auth.chapterWiseNotesAccess),
          _toggleRow(
              'Full Mock Test Series', auth.fullMockTestSeries || auth.isPro),
          _infoRow('MHT CET PYQs Access', auth.mhtCetPyqsAccess),
          _infoRow('Mock Tests / Subject', mockTests),
          _toggleRow('Performance Tracking', auth.performanceTracking),
          _toggleRow(
              'Priority Features', auth.priorityFeatureAccess || auth.isPro),
          _toggleRow(
              'Topper Notes Download', auth.topperNotesDownload || auth.isPro),
          _infoRow('Topper Profiles Access', auth.topperProfilesAccess),
        ],
      ),
    );
  }

  Widget _actionRow({required VoidCallback onLogout}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              label: const Text("Settings"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              label: const Text("Log Out", style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Edit Sheet ----------

  Widget _editSheet() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      child: Material(
        color: Colors.black.withOpacity(0.3),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Edit Profile',
                        style: AppTheme.subheadingStyle.copyWith(fontSize: 18)),
                    const Divider(),
                    const SizedBox(height: 8),
                    _textField('Name', _nameController),
                    const SizedBox(height: 12),
                    _textField('Email', _emailController,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _textField('Phone', _phoneController, enabled: false),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Save"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    setState(() => _isEditing = false);
                                    _populateFromProvider();
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _statusMessage.toLowerCase().contains('success')
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Small helpers ----------

  Widget _textField(String label, TextEditingController c,
      {bool enabled = true, TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final v = value.isEmpty ? 'N/A' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: AppTheme.captionStyle
                      .copyWith(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(v,
                style: AppTheme.captionStyle,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: AppTheme.captionStyle
                      .copyWith(fontWeight: FontWeight.w600))),
          Icon(enabled ? Icons.check_circle : Icons.cancel,
              color: enabled ? Colors.green : Colors.red, size: 20),
        ],
      ),
    );
  }
}

// =================== Sub-widgets ===================

class _HeaderCard extends StatelessWidget {
  final String name;
  final String? email;
  final String planType;
  final String status;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.planType,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final planLower = planType.toLowerCase();
    final Color planColor = planLower == 'pro'
        ? Colors.purple
        : (planLower == 'plus' ? Colors.blue : Colors.grey);
    final Color statusColor =
        (status.toLowerCase() == 'active') ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [planColor.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: planColor.withOpacity(0.8),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTheme.subheadingStyle
                        .copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email?.isNotEmpty == true ? email! : 'No email provided',
                    style: AppTheme.captionStyle
                        .copyWith(color: Colors.grey[700])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(planType, planColor),
                    _pill(status, statusColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CardWrap extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardWrap({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ]),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.subheadingStyle.copyWith(fontSize: 18)),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}
