import 'package:cet_verse/features/courses/study_type.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class LevelSubjects extends StatefulWidget {
  final String title;
  final String lessons;
  final String rating;
  final String image;

  const LevelSubjects({
    super.key,
    required this.title,
    required this.lessons,
    required this.rating,
    required this.image,
  });

  @override
  _LevelSubjectsState createState() => _LevelSubjectsState();
}

class _LevelSubjectsState extends State<LevelSubjects> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<QuerySnapshot> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = FirebaseFirestore.instance
        .collection('levels')
        .doc(widget.title)
        .collection('subjects')
        .get();
  }

  Future<void> _refreshSubjects() async {
    setState(() {
      _subjectsFuture = FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.title)
          .collection('subjects')
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.title == '12th Standard'
        ? 'Class 12'
        : widget.title == '11th Standard'
            ? 'Class 11'
            : widget.title;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const MyDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48, // Reduced height
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          displayTitle,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18, // Updated to 18
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16), // Reduced padding
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayTitle),
                  const SizedBox(height: 16), // Reduced spacing
                  Text(
                    "Choose Subject",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16, // Updated to 16
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16), // Reduced spacing
                  _buildSubjectsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String displayTitle) {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 24, // Reduced size
              ),
            ),
            const SizedBox(width: 16), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16, // Updated to 16
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  Row(
                    children: [
                      _buildInfoChip(Icons.book_outlined, widget.lessons),
                      const SizedBox(width: 8), // Reduced spacing
                      _buildInfoChip(Icons.star, widget.rating),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.indigoAccent), // Reduced size
          const SizedBox(width: 3), // Reduced spacing
          Text(
            text,
            style: const TextStyle(
              fontSize: 12, // Updated to 12
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection() {
    const List<String> desiredOrder = [
      "Physics",
      "Chemistry",
      "Mathematics",
      "Mathematics Part I",
      "Mathematics Part II",
      "Biology"
    ];

    return FutureBuilder<QuerySnapshot>(
      future: _subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard();
        }

        List<String> availableSubjects =
            snapshot.data!.docs.map((doc) => doc.id).toList();

        List<String> subjects = desiredOrder
            .where((subject) => availableSubjects.contains(subject))
            .toList();

        if (subjects.isEmpty) {
          return _buildEmptyCard();
        }

        return Column(
          children: subjects.map((subject) {
            final index = subjects.indexOf(subject);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
              child: _buildSubjectCard(subject, index),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(6, (index) => _buildShimmerSubjectCard()),
    );
  }

  Widget _buildShimmerSubjectCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
      child: Card(
        elevation: 2, // Reduced elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 40, // Reduced size
                  height: 40, // Reduced size
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 120, // Reduced width
                        height: 16, // Reduced height
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 160, // Reduced width
                        height: 12, // Reduced height
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 20, // Reduced size
                  height: 20, // Reduced size
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String subject, int index) {
    final Map<String, Map<String, dynamic>> subjectInfo = {
      "Physics": {
        'icon': Icons.science_outlined,
        'description': 'Mechanics, Thermodynamics & more'
      },
      "Chemistry": {
        'icon': Icons.biotech_outlined,
        'description': 'Organic, Inorganic & Physical'
      },
      "Mathematics": {
        'icon': Icons.calculate_outlined,
        'description': 'Algebra, Calculus & Geometry'
      },
      "Mathematics Part I": {
        'icon': Icons.calculate_outlined,
        'description': 'Part I - Core Mathematics'
      },
      "Mathematics Part II": {
        'icon': Icons.poll_rounded,
        'description': 'Part II - Advanced Topics'
      },
      "Biology": {
        'icon': Icons.local_florist_outlined,
        'description': 'Botany & Zoology concepts'
      },
    };

    final info = subjectInfo[subject] ??
        {'icon': Icons.subject_outlined, 'description': 'Subject content'};

    final isFirstItem = index == 0;

    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudyType(
                level: widget.title,
                subject: subject,
              ),
            ),
          );
        },
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Row(
            children: [
              Container(
                width: 40, // Reduced size
                height: 40, // Reduced size
                decoration: BoxDecoration(
                  color:
                      isFirstItem ? Colors.indigoAccent : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  info['icon'] as IconData,
                  size: 20, // Reduced size
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: AppTheme.subheadingStyle.copyWith(
                              fontSize: 14, // Updated to 14
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFirstItem) ...[
                          const SizedBox(width: 6), // Reduced spacing
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                fontSize: 10, // Updated to 10
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    Text(
                      info['description'] as String,
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 12, // Updated to 12
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.indigoAccent,
                size: 16, // Reduced size
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20), // Reduced padding
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40, // Reduced size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'Error loading subjects',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16, // Updated to 16
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              'Please check your connection and try again',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14, // Updated to 14
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12), // Reduced spacing
            ElevatedButton(
              onPressed: _refreshSubjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8), // Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2, // Reduced elevation
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 14, // Updated to 14
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20), // Reduced padding
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 40, // Reduced size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'No subjects available',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16, // Updated to 16
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              'Subjects will be available soon for this level',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14, // Updated to 14
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
