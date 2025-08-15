import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String name;
  final String? email;
  final String dob;
  final String city;
  final String educationLevel;
  final String board;
  final String school;
  final String userType;
  final DateTime? createdAt;
  final Map<String, dynamic> subscription;
  final Map<String, dynamic> features;

  UserModel({
    required this.name,
    this.email,
    required this.dob,
    required this.city,
    required this.educationLevel,
    required this.board,
    required this.school,
    required this.userType,
    this.createdAt,
    required this.subscription,
    required this.features,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] ?? '',
      email: data['email'],
      dob: data['dob'] ?? '',
      city: data['city'] ?? '',
      educationLevel: data['educationLevel'] ?? '',
      board: data['board'] ?? '',
      school: data['school'] ?? '',
      userType: data['userType'] ?? 'User',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      subscription: Map<String, dynamic>.from(data['subscription'] ?? {}),
      features:
          Map<String, dynamic>.from(data['subscription']?['features'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'dob': dob,
      'city': city,
      'educationLevel': educationLevel,
      'board': board,
      'school': school,
      'userType': userType,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'subscription': subscription,
    };
  }
}
