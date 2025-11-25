# Overdue Penalty Feature Documentation

## Overview
The system now automatically doubles all violation fines when the payment due date has passed. This penalty is applied universally across all pages that display or calculate violation amounts.

## Implementation Date
November 25, 2025

## Key Features

### 1. Automatic Fine Doubling
- When the current date exceeds the violation's due date, all fines are automatically doubled
- The penalty is calculated in real-time whenever violations are displayed or payments are processed
- Original fine amounts are preserved in the database; penalties are calculated dynamically

### 2. Visual Indicators
- **Overdue Warning Banner**: Prominent red warning displayed on payment and violation detail pages
- **Strikethrough Pricing**: Original price shown with strikethrough, doubled price highlighted in red
- **Penalty Labels**: Clear "(2x)" indicators next to doubled amounts
- **Color Coding**: Red highlighting for overdue-related information

### 3. Affected Pages

#### Pay Fines Page (`/lib/pages/pay_fines/index.dart`)
- Shows overdue warning banner at top of violation details
- Displays original and doubled prices for each violation
- Shows penalty message with days overdue
- Calculates total payment including doubled fines

#### Driver Violations Page (`/lib/pages/driver_violations/index.dart`)
- Shows overdue warning in violation detail modal
- Displays original and penalized amounts side-by-side
- Shows total fine amount with penalty applied
- Due date highlighted in red if overdue

## Technical Implementation

### New Utility: Fine Calculator (`/lib/utils/fine_calculator.dart`)

#### Core Functions:

```dart
// Check if violation is overdue
FineCalculator.isOverdue(DateTime? dueDate) -> bool

// Calculate fine with penalty (2x if overdue)
FineCalculator.calculateFineAmount(double originalPrice, DateTime? dueDate) -> double

// Calculate total for all violations with penalty
FineCalculator.calculateTotalFine(List violations, DateTime? dueDate) -> double

// Get penalty multiplier (1x or 2x)
FineCalculator.getPenaltyMultiplier(DateTime? dueDate) -> double

// Get days overdue
FineCalculator.getDaysOverdue(DateTime? dueDate) -> int

// Get user-friendly penalty message
FineCalculator.getPenaltyMessage(DateTime? dueDate) -> String
```

### Updated Services

#### Payment Handler (`/lib/utils/payment_handler.dart`)
- Modified `calculateSubtotal()` to apply penalty when calculating payment amounts
- Now uses `FineCalculator.calculateFineAmount()` for each violation
- Processing fees are calculated on the penalized amount (if overdue)

### Database Structure
No changes to the database structure were required. The system uses existing fields:
- `dueDate`: DateTime field in the `reports` collection
- `violations[].price`: Original fine amounts (unchanged)
- Penalties are calculated dynamically based on current date vs. due date

## User Experience

### When Violation is NOT Overdue:
- Fines display at original amounts
- No warning banners shown
- Due date shown in normal white/gray text
- Total amounts calculated normally

### When Violation IS Overdue:
- **Warning Banner**: Red banner at top with overdue message
- **Doubled Fines**: All violation amounts doubled
- **Visual Indicators**: 
  - Original price: `₱500.00` (strikethrough, faded)
  - New price: `₱1,000.00` (red, bold) (2x)
- **Penalty Message**: "Payment is X days overdue. Fine has been doubled."
- **Color Coding**: Due dates and overdue amounts in red

## Examples

### Example 1: Single Violation, Not Overdue
```
Violation: Speeding
Original Fine: ₱500.00
Due Date: Dec 31, 2025
Current Date: Nov 25, 2025
---
Displayed Fine: ₱500.00
Total to Pay: ₱500.00 + ₱12.50 (fee) = ₱512.50
```

### Example 2: Single Violation, Overdue by 5 Days
```
Violation: Speeding
Original Fine: ₱500.00
Due Date: Nov 20, 2025
Current Date: Nov 25, 2025
---
Warning: "Payment is 5 days overdue. Fine has been doubled."
Displayed Fine: ₱500.00 → ₱1,000.00 (2x)
Total to Pay: ₱1,000.00 + ₱25.00 (fee) = ₱1,025.00
```

### Example 3: Multiple Violations, Overdue
```
Violations:
1. Speeding: ₱500.00 → ₱1,000.00 (2x)
2. No Helmet: ₱1,000.00 → ₱2,000.00 (2x)
3. Illegal Parking: ₱200.00 → ₱400.00 (2x)

Due Date: Nov 15, 2025
Current Date: Nov 25, 2025
---
Warning: "Payment is 10 days overdue. Fine has been doubled."
Subtotal: ₱3,400.00 (doubled from ₱1,700.00)
Processing Fee: ₱85.00 (2.5%)
Total to Pay: ₱3,485.00
```

## Date Comparison Logic
- Compares dates at the day level (ignoring time)
- Uses strict "after" comparison (day after due date = overdue)
- If due date is null, no penalty is applied
- Example:
  - Due: Nov 24, 2025
  - Current: Nov 24, 2025 11:59 PM → Not Overdue
  - Current: Nov 25, 2025 12:01 AM → Overdue

## Testing Checklist

### Test Scenarios:
- [ ] Violation with no due date (should not apply penalty)
- [ ] Violation with future due date (should not apply penalty)
- [ ] Violation with due date = today (should not apply penalty)
- [ ] Violation with due date = yesterday (should apply 2x penalty)
- [ ] Violation overdue by 1 day (should apply 2x penalty)
- [ ] Violation overdue by 30+ days (should apply 2x penalty)
- [ ] Multiple violations, some overdue, some not (individual calculation)
- [ ] Payment processing with overdue violations
- [ ] PayMongo integration with doubled amounts

### Pages to Test:
- [ ] Pay Fines page - search and display
- [ ] Pay Fines page - payment calculation
- [ ] Driver Violations page - list view
- [ ] Driver Violations page - detail modal
- [ ] Payment confirmation and receipt

## Future Enhancements (Potential)
- Graduated penalty system (different multipliers based on days overdue)
- Email/SMS notifications before due date
- Grace period before penalty applies
- Maximum penalty cap
- Admin override for penalty removal
- Penalty payment history tracking

## Notes
- The penalty system is transparent to users with clear visual indicators
- Original fine amounts are never modified in the database
- Penalties are calculated dynamically on each page load/refresh
- The system uses the device's current date for comparison
- Processing fees are calculated on the final amount (including penalties)

## Related Files
- `/lib/utils/fine_calculator.dart` - Core penalty calculation logic
- `/lib/utils/payment_handler.dart` - Payment amount calculations
- `/lib/pages/pay_fines/index.dart` - Payment page with penalty display
- `/lib/pages/driver_violations/index.dart` - Violation list with penalty display
- `/lib/pages/violation/models/report_model.dart` - Report data model (includes dueDate)
- `/lib/pages/violation/models/violation_model.dart` - Violation data model

## Support
For questions or issues related to the overdue penalty feature, please contact the development team.
