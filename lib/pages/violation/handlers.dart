import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enforcer_auto_fine/enums/collections.dart';
import 'package:enforcer_auto_fine/pages/violation/models/report_model.dart';
import 'package:enforcer_auto_fine/pages/violation/models/violation_model.dart';
import 'package:enforcer_auto_fine/pages/violation/models/violations_config.dart';

/// Check for duplicate violations before saving a new report.
Future<bool> _checkDuplicateViolation(ReportModel data) async {
  final db = FirebaseFirestore.instance;
  final plateNumber = data.plateNumber;
  final newViolations = data.violations;

  // Get today's date range for client-side comparison
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  // 1. Fetch ALL reports for the plate number, regardless of date.
  // This avoids the need for a composite index.
  final querySnapshot = await db
      .collection(Collections.reports.name)
      .where('plateNumber', isEqualTo: plateNumber)
      .get();

  // 2. Filter the results here in the app to find reports from today.
  final todaysDocs = querySnapshot.docs.where((doc) {
    final timestamp = doc.data()['createdAt'] as Timestamp?;
    if (timestamp == null) return false;
    final docDate = timestamp.toDate();
    // Check if the document's date is within today's range
    return docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay);
  }).toList();


  if (todaysDocs.isNotEmpty) {
    // 3. If there are reports from today, check for matching violation names.
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


/// Calculate repetition counts for violations based on previous reports for the same plate number
Future<List<ViolationModel>> _calculateViolationRepetitions(
    String plateNumber, List<ViolationModel> newViolations) async {
  try {
    final db = FirebaseFirestore.instance;

    // Get all previous reports for this plate number
    final previousReportsSnapshot = await db
        .collection(Collections.reports.name)
        .where('plateNumber', isEqualTo: plateNumber)
        .get();

    // Count existing violations for this plate number
    final Map<String, int> violationCounts = {};

    for (var doc in previousReportsSnapshot.docs) {
      final data = doc.data();
      final List<dynamic>? violationsData =
          data['violations'] as List<dynamic>?;

      // Skip documents that don't have violations or have null violations
      if (violationsData == null) continue;

      for (var violationData in violationsData) {
        if (violationData is Map<String, dynamic>) {
          // New format with ViolationModel
          final violationName = violationData['violationName'] as String?;
          if (violationName != null) {
            violationCounts.update(
              violationName,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }
        } else if (violationData is String) {
          // Legacy format - just strings
          violationCounts.update(
            violationData,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    // Update repetition counts for new violations
    final List<ViolationModel> updatedViolations =
        newViolations.map((violation) {
      final existingCount = violationCounts[violation.violationName] ?? 0;
      return violation.copyWith(repetition: existingCount + 1);
    }).toList();

    // Update prices based on repetition for violations that have repetition-based pricing
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

      // Only update price for fixed-price violations if the current price matches default
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
    // Return original violations if calculation fails
    return newViolations;
  }
}

Future<String?> handleSave(ReportModel data) async {
  try {
    // First, check for duplicates
    final isDuplicate = await _checkDuplicateViolation(data);
    if (isDuplicate) {
      // If a duplicate is found, throw an exception to be caught by the UI
      throw Exception('This violation already recorded this day.');
    }

    // Get an instance of Firestore
    final db = FirebaseFirestore.instance;

    // Calculate repetition counts for violations
    final updatedViolations = await _calculateViolationRepetitions(
      data.plateNumber,
      data.violations,
    );

    // Create updated report with correct repetition counts
    final updatedData = ReportModel(
      fullname: data.fullname,
      address: data.address,
      phoneNumber: data.phoneNumber,
      licenseNumber: data.licenseNumber,
      licensePhoto: data.licensePhoto,
      plateNumber: data.plateNumber,
      platePhoto: data.platePhoto,
      evidencePhoto: data.evidencePhoto,
      trackingNumber: data.trackingNumber,
      createdById: data.createdById,
      violations: updatedViolations,
      createdAt: data.createdAt,
      draftId: data.draftId,
    );

    // Convert your ReportModel to a Map
    final reportData = updatedData.toJson();

    // Add a new document with a generated ID to the 'reports' collection
    await db.collection(Collections.reports.name).add(reportData);

    print('Report successfully saved to Firestore!');
    var tNumber = ReportModel.fromJson(reportData).trackingNumber;

    return tNumber;
  } catch (e) {
    print('Error saving report to Firestore: $e');
    // Rethrow the exception so the UI can display the specific error message
    rethrow;
  }
}