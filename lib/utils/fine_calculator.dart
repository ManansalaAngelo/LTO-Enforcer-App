/// Utility for calculating fines with due date penalties
class FineCalculator {
  /// Check if a violation is overdue based on due date
  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    
    final now = DateTime.now();
    // Set time to start of day for fair comparison
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    return today.isAfter(dueDateOnly);
  }
  
  /// Calculate fine amount with penalty if overdue
  /// Doubles the fine if past due date
  static double calculateFineAmount(double originalPrice, DateTime? dueDate) {
    if (isOverdue(dueDate)) {
      return originalPrice * 2;
    }
    return originalPrice;
  }
  
  /// Calculate total fine for all violations with penalty if overdue
  static double calculateTotalFine(
    List<dynamic> violations, 
    DateTime? dueDate,
  ) {
    double total = 0.0;
    
    for (var violation in violations) {
      double price;
      
      // Handle both ViolationModel and Map formats
      if (violation is Map<String, dynamic>) {
        price = (violation['price'] as num?)?.toDouble() ?? 0.0;
      } else {
        // Assuming ViolationModel with .price property
        price = (violation as dynamic).price as double;
      }
      
      total += calculateFineAmount(price, dueDate);
    }
    
    return total;
  }
  
  /// Get penalty multiplier (2x if overdue, 1x if not)
  static double getPenaltyMultiplier(DateTime? dueDate) {
    return isOverdue(dueDate) ? 2.0 : 1.0;
  }
  
  /// Get days overdue (returns 0 if not overdue)
  static int getDaysOverdue(DateTime? dueDate) {
    if (!isOverdue(dueDate)) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate!.year, dueDate.month, dueDate.day);
    
    return today.difference(dueDateOnly).inDays;
  }
  
  /// Get a user-friendly penalty message
  static String getPenaltyMessage(DateTime? dueDate) {
    if (!isOverdue(dueDate)) {
      return '';
    }
    
    final daysOverdue = getDaysOverdue(dueDate);
    return 'Payment is $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue. Fine has been doubled.';
  }
}
