import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.targetRole = '',
    this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String targetRole;
  final DateTime? createdAt;

  factory UserModel.fromJson(String uid, Map<String, dynamic> json) {
    return UserModel(
      uid: uid,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      targetRole: json['targetRole'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'targetRole': targetRole,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : Timestamp.now(),
    };
  }

  UserModel copyWith({String? fullName, String? targetRole}) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      targetRole: targetRole ?? this.targetRole,
      createdAt: createdAt,
    );
  }
}
