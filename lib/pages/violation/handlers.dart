import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enforcer_auto_fine/enums/collections.dart';
import 'package:enforcer_auto_fine/pages/violation/models/report_model.dart';
import 'package:enforcer_auto_fine/pages/violation/models/violation_model.dart';
import 'package:enforcer_auto_fine/pages/violation/models/violations_config.dart';
import 'package:enforcer_auto_fine/services/textbee_service.dart';
import 'package:enforcer_auto_fine/utils/tracking_no_generator.dart';

/// ✅ Check for duplicate violations before saving a new report.
Future<bool> _checkDuplicateViolation(ReportModel data) async {
  final db = FirebaseFirestore.instance;
  final plateNumber = data.plateNumber;
  final newViolations = data.violations;

  // Get today's date range for comparison
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  // Fetch all reports for the same plate number
  final querySnapshot = await db
      .collection(Collections.reports.name)
      .where('plateNumber', isEqualTo: plateNumber)
      .get();

  // Filter reports created today
  final todaysDocs = querySnapshot.docs.where((doc) {
    final timestamp = doc.data()['createdAt'] as Timestamp?;
    if (timestamp == null) return false;
    final docDate = timestamp.toDate();
    return docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay);
  }).toList();

  if (todaysDocs.isNotEmpty) {
    for (final doc in todaysDocs) {
      final existingReport = ReportModel.fromJson(doc.data());
      for (final existingViolation in existingReport.violations) {
        for (final newViolation in newViolations) {
          if (existingViolation.violationName == newViolation.violationName) {
            return true; // Duplicate found
          }
        }
      }
    }
  }

  return false; // No duplicate found
}

/// ✅ Calculate violation repetition counts and update prices accordingly.
Future<List<ViolationModel>> _calculateViolationRepetitions(
    String plateNumber, List<ViolationModel> newViolations) async {
  try {
    final db = FirebaseFirestore.instance;
    final previousReportsSnapshot = await db
        .collection(Collections.reports.name)
        .where('plateNumber', isEqualTo: plateNumber)
        .get();

    final Map<String, int> violationCounts = {};

    for (var doc in previousReportsSnapshot.docs) {
      final data = doc.data();
      final List<dynamic>? violationsData =
          data['violations'] as List<dynamic>?;

      if (violationsData == null) continue;

      for (var violationData in violationsData) {
        if (violationData is Map<String, dynamic>) {
          final violationName = violationData['violationName'] as String?;
          if (violationName != null) {
            violationCounts.update(
              violationName,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }
        } else if (violationData is String) {
          violationCounts.update(
            violationData,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    final List<ViolationModel> updatedViolations =
        newViolations.map((violation) {
      final existingCount = violationCounts[violation.violationName] ?? 0;
      return violation.copyWith(repetition: existingCount + 1);
    }).toList();

    final List<ViolationModel> finalViolations =
        updatedViolations.map((violation) {
      final violationDef = ViolationsConfig.definitions.values.firstWhere(
        (def) => def.displayName == violation.violationName,
        orElse: () => const ViolationDefinition(
          name: 'other',
          displayName: 'Other',
          type: ViolationType.range,
          minPrice: 500.0,
          maxPrice: 100000.0,
        ),
      );

      if (violationDef.type == ViolationType.fixed &&
          violationDef.prices != null) {
        final newPrice = violationDef.getPriceForOffense(violation.repetition);
        return violation.copyWith(price: newPrice);
      }

      return violation;
    }).toList();

    return finalViolations;
  } catch (e) {
    print('Error calculating violation repetitions: $e');
    return newViolations;
  }
}

/// ✅ Handles report submission, Firestore saving, and SMS notification.
// ✅ CHANGED: Return type is now a Map to include trackingNumber and dueDate
Future<Map<String, dynamic>?> handleSave(ReportModel data) async {
  try {
    // Check for duplicates
    final isDuplicate = await _checkDuplicateViolation(data);
    if (isDuplicate) {
      throw Exception('This violation is already recorded today.');
    }

    // Generate a unique tracking number
    final trackingNumber = createAlphanumericTrackingNumber();

    final db = FirebaseFirestore.instance;

    // ✅ ADDED: Calculate creation time and due date
    final creationTime = data.createdAt ?? DateTime.now();
    final dueDate = creationTime.add(const Duration(days: 15));

    // Calculate repetition counts for violations
    final updatedViolations = await _calculateViolationRepetitions(
      data.plateNumber,
      data.violations,
    );

    // Create updated report data
    final updatedData = ReportModel(
      fullname: data.fullname,
      address: data.address,
      phoneNumber: data.phoneNumber,
      licenseNumber: data.licenseNumber,
      licensePhoto: data.licensePhoto,
      plateNumber: data.plateNumber,
      platePhoto: data.platePhoto,
      evidencePhoto: data.evidencePhoto,
      trackingNumber: trackingNumber,
      createdById: data.createdById,
      violations: updatedViolations,
      createdAt: creationTime, // ✅ CHANGED: Use creationTime variable
      dueDate: dueDate, // ✅ ADDED: Pass the calculated due date
      draftId: data.draftId,
    );

    // Save the report to Firestore
    final docRef =
        await db.collection(Collections.reports.name).add(updatedData.toJson());

    // Make sure the tracking number exists in Firestore (if not, add it)
    await docRef.update({'trackingNumber': trackingNumber});

    print('✅ Report successfully saved to Firestore with tracking number: $trackingNumber');

    // Fetch saved document to confirm
    final savedDoc = await docRef.get();
    final savedTrackingNumber =
        savedDoc.data()?['trackingNumber'] ?? trackingNumber;

    // ✅ Include fullname in SMS message
    final fullNameText = (updatedData.fullname.isNotEmpty)
        ? 'Hi ${updatedData.fullname}. '
        : '';

    final smsMessage =
        '${fullNameText}\nAutoFine: You have a violation with tracking number $savedTrackingNumber. '
        'Please check the AutoFine app for details.';

    // Optional small delay before sending SMS
    await Future.delayed(const Duration(seconds: 2));

    // Send SMS
    await TextBeeService.sendSms(updatedData.phoneNumber, smsMessage);

    print('📱 SMS sent successfully with tracking number: $savedTrackingNumber');

    // ✅ CHANGED: Return Map with tracking number and due date
    return {
      'trackingNumber': savedTrackingNumber,
      'dueDate': dueDate,
    };
  } catch (e) {
    print('❌ Error saving report to Firestore or sending SMS: $e');
    rethrow;
  }
}