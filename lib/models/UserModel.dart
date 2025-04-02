import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String name;
  final String dob;
  final String city;
  final String educationLevel;
  final String board;
  final String school;
  final String userType;
  final DateTime createdAt;

  var email;

  UserModel({
    required this.name,
    required this.dob,
    required this.city,
    required this.educationLevel,
    required this.board,
    required this.school,
    required this.userType,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] ?? '',
      dob: data['dob'] ?? '',
      city: data['city'] ?? '',
      educationLevel: data['educationLevel'] ?? '',
      board: data['board'] ?? '',
      school: data['school'] ?? '',
      userType: data['userType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
