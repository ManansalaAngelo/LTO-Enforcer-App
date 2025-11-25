import 'package:enforcer_auto_fine/utils/tracking_no_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'violation_model.dart';

class ReportModel {
  String fullname;
  String address;
  String phoneNumber;
  String licenseNumber;
  String licensePhoto;
  String plateNumber;
  String platePhoto;
  String evidencePhoto;
  String? trackingNumber;
  String? createdById;
  String? enforcerName; // ✅ NEW: Add enforcer name field
  List<ViolationModel> violations;
  DateTime? createdAt;
  DateTime? dueDate; // ✅ ADDED: New field for due date
  String? draftId;
  String? paymentReferenceId;
  String status; // "Overturned" | "Submitted" | "Cancelled" | "Paid"
  String paymentStatus; // "Pending" | "Completed" | "Refunded" | "Cancelled"
  // New fields
  String? age;
  DateTime? birthdate;
  String? placeOfViolation;
  bool isConfiscated; // Radio button: confiscated or non-confiscated

  ReportModel({
    required this.fullname,
    required this.address,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.licensePhoto,
    required this.plateNumber,
    required this.platePhoto,
    this.trackingNumber,
    this.createdById,
    this.enforcerName, // ✅ NEW: Add to constructor
    required this.violations,
    required this.evidencePhoto,
    this.createdAt,
    this.dueDate, // ✅ ADDED: To constructor
    this.draftId,
    this.paymentReferenceId,
    this.status = "Submitted",
    this.paymentStatus = "Pending",
    this.age,
    this.birthdate,
    this.placeOfViolation,
    this.isConfiscated = false,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      fullname: json['fullname']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      licensePhoto: json['licensePhoto']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      platePhoto: json['platePhoto']?.toString() ?? '',
      evidencePhoto: json['evidencePhoto']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString(),
      createdById: json['createdById']?.toString(),
      enforcerName: json['enforcerName']?.toString(), // ✅ NEW: Add to fromJson
      paymentReferenceId: json['paymentReferenceId']?.toString(),
      violations: (json['violations'] as List)
          .map((v) => ViolationModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      draftId: json['draftId']?.toString(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime(0),
      // ✅ ADDED: Read dueDate from Firestore
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] is Timestamp 
              ? (json['dueDate'] as Timestamp).toDate()
              : null)
          : null,
      status: json['status']?.toString() ?? "Submitted",
      paymentStatus: json['paymentStatus']?.toString() ?? "Pending",
      age: json['age']?.toString(),
      birthdate: json['birthdate'] != null
          ? (json['birthdate'] is Timestamp
              ? (json['birthdate'] as Timestamp).toDate()
              : (json['birthdate'] is String 
                  ? DateTime.tryParse(json['birthdate'] as String)
                  : null))
          : null,
      placeOfViolation: json['placeOfViolation']?.toString(),
      isConfiscated: json['isConfiscated'] is bool 
          ? json['isConfiscated'] as bool 
          : (json['isConfiscated']?.toString().toLowerCase() == 'true' || json['isConfiscated'] == 1),
    );
  }

  Map<String, dynamic> toJson() {
    final user = FirebaseAuth.instance.currentUser;
    createdById = user?.uid;

    return {
      'fullname': fullname,
      'address': address,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'licensePhoto': licensePhoto,
      'plateNumber': plateNumber,
      'platePhoto': platePhoto,
      'violations': violations.map((v) => v.toJson()).toList(),
      'createdById': createdById,
      'enforcerName': enforcerName, // ✅ NEW: Add to toJson
      'evidencePhoto': evidencePhoto,
      'draftId': draftId,
      'trackingNumber': trackingNumber ?? createAlphanumericTrackingNumber(), // ✅ fixed
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : Timestamp.fromDate(DateTime.now()),
      // ✅ ADDED: Save dueDate to Firestore
      'dueDate':
          dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'paymentStatus': paymentStatus,
      'age': age,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'placeOfViolation': placeOfViolation,
      'isConfiscated': isConfiscated,
    };
  }

  Map<String, dynamic> toDraftJson() {
    final user = FirebaseAuth.instance.currentUser;
    createdById = user?.uid;

    return {
      'fullname': fullname,
      'address': address,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'licensePhoto': licensePhoto,
      'plateNumber': plateNumber,
      'platePhoto': platePhoto,
      'violations': violations.map((v) => v.toJson()).toList(),
      'createdById': createdById,
      'enforcerName': enforcerName, // ✅ NEW: Add to toDraftJson
      'evidencePhoto': evidencePhoto,
      'draftId': draftId,
      'trackingNumber': trackingNumber ?? createAlphanumericTrackingNumber(), // ✅ fixed
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      // ✅ ADDED: Save dueDate to draft
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'paymentStatus': paymentStatus,
      'age': age,
      'birthdate': birthdate?.toIso8601String(),
      'placeOfViolation': placeOfViolation,
      'isConfiscated': isConfiscated,
    };
  }
}