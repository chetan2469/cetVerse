// lib/pages/profile_page.dart
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:cet_verse/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _statusMessage = "";
  bool _saving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _inrFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  // Blue Light Theme Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF87CEEB);
  static const Color paleBlue = Color(0xFFF0F8FF);
  static const Color accentBlue = Color(0xFF5DADE2);
  static const Color darkBlue = Color(0xFF2E86AB);
  static const Color backgroundBlue = Color(0xFFF8FCFF);

  @override
  void initState() {
    super.initState();
    _populateFromProvider();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
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
    _animationController.dispose();
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
      builder: (_) => _buildLogoutDialog(),
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
      return _buildLoadingScreen();
    }

    if (user == null) {
      return _buildErrorScreen(auth);
    }

    return Scaffold(
      backgroundColor: backgroundBlue,
      body: Stack(
        children: [
          _buildBackground(),
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildProfileHeader(user, auth),
                      const SizedBox(height: 20),
                      _buildQuickStats(auth),
                      const SizedBox(height: 20),
                      _buildPersonalInfoCard(user, _phoneController.text),
                      const SizedBox(height: 16),
                      _buildSubscriptionCard(auth),
                      const SizedBox(height: 16),
                      _buildFeaturesCard(auth),
                      const SizedBox(height: 20),
                      _buildActionButtons(auth),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isEditing) _buildEditOverlay(),
          if (_saving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFF8FCFF),
            Color(0xFFE1F5FE),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 50,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryBlue.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing) ...[
          _buildActionButton(
            icon: Icons.refresh_rounded,
            onPressed: () {
              final p = context.read<AuthProvider>().userPhoneNumber;
              if (p != null) context.read<AuthProvider>().fetchUserData(p);
            },
          ),
          _buildActionButton(
            icon: Icons.edit_rounded,
            onPressed: () {
              _populateFromProvider();
              setState(() => _isEditing = true);
            },
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: primaryBlue),
        iconSize: 20,
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, AuthProvider auth) {
    final plan = auth.getPlanType ?? 'Starter';
    final status = auth.subscriptionStatus ?? 'inactive';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  paleBlue.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryBlue, lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? 'Welcome User' : user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email?.isNotEmpty == true
                            ? user.email!
                            : 'No email provided',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusChip(plan, _getPlanColor(plan)),
                          const SizedBox(width: 8),
                          _buildStatusChip(status, _getStatusColor(status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getPlanIcon(plan),
                color: primaryBlue,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.quiz_rounded,
              title: 'Mock Tests',
              value: auth.mockTestsPerSubject >= 9999
                  ? 'Unlimited'
                  : '${auth.mockTestsPerSubject}/subject',
              color: accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              title: 'Features',
              value: '${_getActiveFeatureCount(auth)}/9',
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today_rounded,
              title: 'Member Since',
              value: auth.currentUser?.createdAt != null
                  ? DateFormat('MMM yyyy').format(auth.currentUser!.createdAt!)
                  : 'N/A',
              color: lightBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserModel user, String phone) {
    return _buildModernCard(
      title: '📋 Personal Information',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _buildInfoTile(Icons.phone_rounded, 'Phone', phone, primaryBlue),
          _buildInfoTile(
              Icons.cake_rounded, 'Date of Birth', user.dob, accentBlue),
          _buildInfoTile(
              Icons.location_city_rounded, 'City', user.city, lightBlue),
          _buildInfoTile(Icons.school_rounded, 'Education Level',
              user.educationLevel, primaryBlue),
          _buildInfoTile(
              Icons.account_balance_rounded, 'Board', user.board, accentBlue),
          _buildInfoTile(
              Icons.business_rounded, 'School', user.school, lightBlue),
          _buildInfoTile(
            Icons.schedule_rounded,
            'Joined',
            user.createdAt != null
                ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
                : 'N/A',
            primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(AuthProvider auth) {
    final start = auth.startDate;
    final end = auth.endDate;
    final amt =
        (auth.amountPaid is num) ? (auth.amountPaid as num).toDouble() : 0.0;

    return _buildModernCard(
      title: '💎 Subscription Details',
      icon: Icons.card_membership_rounded,
      child: Column(
        children: [
          _buildInfoTile(
              Icons.workspace_premium_rounded,
              'Plan',
              auth.getPlanType ?? 'Starter',
              _getPlanColor(auth.getPlanType ?? 'Starter')),
          _buildInfoTile(
              Icons.toggle_on_rounded,
              'Status',
              auth.subscriptionStatus ?? 'Inactive',
              _getStatusColor(auth.subscriptionStatus ?? 'inactive')),
          _buildInfoTile(
              Icons.play_arrow_rounded,
              'Start Date',
              start != null ? DateFormat('MMM dd, yyyy').format(start) : 'N/A',
              primaryBlue),
          _buildInfoTile(
              Icons.stop_rounded,
              'End Date',
              end != null ? DateFormat('MMM dd, yyyy').format(end) : 'N/A',
              accentBlue),
          _buildInfoTile(Icons.currency_rupee_rounded, 'Amount Paid',
              _inrFmt.format(amt), Colors.green),
          _buildInfoTile(Icons.payment_rounded, 'Payment Method',
              auth.paymentMethod ?? 'None', lightBlue),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(AuthProvider auth) {
    return _buildModernCard(
      title: '🚀 Feature Access',
      icon: Icons.featured_play_list_rounded,
      child: Column(
        children: [
          _buildFeatureTile('Board PYQs', auth.boardPyqsAccess, Icons.quiz),
          _buildFeatureTile(
              'Chapter-wise Notes', auth.chapterWiseNotesAccess, Icons.note),
          _buildFeatureTile('Full Mock Test Series',
              auth.fullMockTestSeries || auth.isPro, Icons.assignment),
          _buildFeatureTile('Performance Tracking', auth.performanceTracking,
              Icons.analytics),
          _buildFeatureTile('Priority Features',
              auth.priorityFeatureAccess || auth.isPro, Icons.priority_high),
          _buildFeatureTile('Topper Notes Download',
              auth.topperNotesDownload || auth.isPro, Icons.download),
          _buildInfoTile(Icons.people_rounded, 'MHT CET PYQs Access',
              auth.mhtCetPyqsAccess, primaryBlue),
          _buildInfoTile(Icons.groups_rounded, 'Topper Profiles Access',
              auth.topperProfilesAccess, accentBlue),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider auth) {
    final isPro = auth.isPro;
    final isPlus = auth.isPlus;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGradientButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  gradient: LinearGradient(
                    colors: [primaryBlue, accentBlue],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientButton(
                  onPressed: _logout,
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlue.withOpacity(0.05),
                  paleBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: darkBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String label, bool enabled, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: enabled ? Colors.green : Colors.red, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: darkBlue,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: enabled ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  enabled ? 'Active' : 'Locked',
                  style: TextStyle(
                    color: enabled ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.edit_rounded, color: primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildModernTextField(
                      'Name', _nameController, Icons.person_rounded),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                      'Email', _emailController, Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                      'Phone', _phoneController, Icons.phone_rounded,
                      enabled: false),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGradientButton(
                          onPressed: _saving ? () {} : _saveProfile,
                          icon: Icons.save_rounded,
                          label: 'Save',
                          gradient: LinearGradient(colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saving
                                  ? null
                                  : () {
                                      setState(() => _isEditing = false);
                                      _populateFromProvider();
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close_rounded,
                                        color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusMessage.toLowerCase().contains('success')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _statusMessage.toLowerCase().contains('success')
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? primaryBlue.withOpacity(0.2) : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                color: primaryBlue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading your profile...',
              style: TextStyle(
                fontSize: 16,
                color: darkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(AuthProvider auth) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                auth.errorMessage ?? 'Please log in to view your profile',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildGradientButton(
                onPressed: () {
                  final p = auth.userPhoneNumber;
                  if (p != null) {
                    auth.fetchUserData(p);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PhoneAuthScreen()),
                    );
                  }
                },
                icon: Icons.refresh_rounded,
                label: 'Retry',
                gradient: LinearGradient(colors: [primaryBlue, accentBlue]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
              const SizedBox(height: 16),
              const Text(
                'Saving changes...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.red),
          ),
          const SizedBox(width: 12),
          const Text('Confirm Logout'),
        ],
      ),
      content: const Text('Are you sure you want to log out of your account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'pro':
        return Colors.purple;
      case 'plus':
        return primaryBlue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    return status.toLowerCase() == 'active' ? Colors.green : Colors.red;
  }

  IconData _getPlanIcon(String plan) {
    switch (plan.toLowerCase()) {
      case 'pro':
        return Icons.diamond_rounded;
      case 'plus':
        return Icons.star_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  int _getActiveFeatureCount(AuthProvider auth) {
    int count = 0;
    if (auth.boardPyqsAccess) count++;
    if (auth.chapterWiseNotesAccess) count++;
    if (auth.fullMockTestSeries || auth.isPro) count++;
    if (auth.performanceTracking) count++;
    if (auth.priorityFeatureAccess || auth.isPro) count++;
    if (auth.topperNotesDownload || auth.isPro) count++;
    if (auth.mhtCetPyqsAccess.isNotEmpty) count++;
    if (auth.topperProfilesAccess.isNotEmpty) count++;
    return count;
  }
}
