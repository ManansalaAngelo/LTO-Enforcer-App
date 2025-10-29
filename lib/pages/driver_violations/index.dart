import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:enforcer_auto_fine/utils/date_formatter.dart'; // Using intl
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../../pages/appeal/models/appeal_model.dart';
import '../../shared/app_theme/colors.dart';
import '../../shared/app_theme/fonts.dart';
import '../../shared/decorations/app_bg.dart';
import '../../pages/violation/models/report_model.dart';

// New StatefulWidget for the modal content to manage its own state
class _ViolationDetailsSheet extends StatefulWidget {
  final ReportModel violation;

  const _ViolationDetailsSheet({required this.violation});

  @override
  _ViolationDetailsSheetState createState() => _ViolationDetailsSheetState();
}

class _ViolationDetailsSheetState extends State<_ViolationDetailsSheet> {
  AppealModel? _appeal;
  bool _isFetchingAppeal = true;

  @override
  void initState() {
    super.initState();
    _fetchAppealDetails();
  }

  Future<void> _fetchAppealDetails() async {
    if (widget.violation.trackingNumber == null) {
      setState(() => _isFetchingAppeal = false);
      return;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appeals')
          .where('violationTrackingNumber',
              isEqualTo: widget.violation.trackingNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _appeal = AppealModel.fromJson(
              querySnapshot.docs.first.data());
          _isFetchingAppeal = false;
        });
      } else {
        setState(() => _isFetchingAppeal = false);
      }
    } catch (e) {
      print('Error fetching appeal details: $e');
      setState(() => _isFetchingAppeal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: MainColor().secondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Violation Details Section
                  _buildViolationDetails(widget.violation),

                  // Appeal Details Section
                  _buildAppealSection(),
                ],
              ),
            ),
          ),
          _buildActionButtons(context, widget.violation),
        ],
      ),
    );
  }

  Widget _buildViolationDetails(ReportModel violation) {
    // Date formatters for consistent and readable dates
    final DateFormat readableDateFormat = DateFormat('MMMM d, yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getViolationColor(
                  violation.violations.first.violationName,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getViolationIcon(violation.violations.first.violationName),
                color: _getViolationColor(
                  violation.violations.first.violationName,
                ),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traffic Violation Report',
                    style: TextStyle(
                      fontSize: FontSizes().h3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          violation.trackingNumber ?? 'No tracking number',
                          style: TextStyle(
                            fontSize: FontSizes().body,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      if (violation.trackingNumber != null)
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: violation.trackingNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Tracking number copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.copy,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildDetailRow('Driver Name', violation.fullname),
        if (violation.status == 'Paid' &&
            violation.paymentReferenceId != null)
          _buildDetailRow('Payment Reference', violation.paymentReferenceId!),
        _buildDetailRow('Address', violation.address),
        _buildDetailRow('Phone Number', violation.phoneNumber),
        _buildDetailRow('License Number', violation.licenseNumber),
        _buildDetailRow('Plate Number', violation.plateNumber),
        _buildDetailRow(
          'Date & Time',
          violation.createdAt != null
             ? '${readableDateFormat.format(violation.createdAt!)} at ${timeFormat.format(violation.createdAt!)}'
             : '--',
        ),
        
        // Display Due Date if it exists
        if (violation.dueDate != null)
          _buildDetailRow(
            'Payment Due Date',
            readableDateFormat.format(violation.dueDate!),
            valueColor: Colors.red, // Highlight in red
            isBold: true,           // Make it bold
          ),

        const SizedBox(height: 16),
        Text(
          'Violations',
          style: TextStyle(
            fontSize: FontSizes().body,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: violation.violations
                .map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.violationName,
                                style: TextStyle(
                                  fontSize: FontSizes().body,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Fine: ₱${v.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: FontSizes().caption,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getOffenseColor(v.repetition)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _getOffenseColor(v.repetition)
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      _getOrdinalNumber(v.repetition),
                                      style: TextStyle(
                                        fontSize: FontSizes().caption,
                                        color: _getOffenseColor(v.repetition)
                                            .withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppealSection() {
    if (_isFetchingAppeal) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_appeal == null) {
      return const SizedBox.shrink(); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        Text(
          'Appeal Information',
          style: TextStyle(
            fontSize: FontSizes().h4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Appeal Status', _appeal!.status),
        if (_appeal!.status.toLowerCase() != 'pending')
          _buildDetailRow(
            'Admin Feedback',
            (_appeal!.statusReason != null &&
                    _appeal!.statusReason!.isNotEmpty)
                ? _appeal!.statusReason!
                : 'No reason was provided.',
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ReportModel violation) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_appeal == null && !_isFetchingAppeal) // Only show if no appeal exists
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/appeal',
                    arguments: violation.trackingNumber,
                  );
                },
                icon: const Icon(Icons.gavel),
                label: const Text('File an Appeal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to accept optional styling
  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: FontSizes().body,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: FontSizes().body,
                color: valueColor ?? Colors.white, // Use provided color or default
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500, // Apply bold
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Using the new comprehensive helper functions
  Color _getViolationColor(String violationType) {
    switch (violationType.toLowerCase()) {
      case 'speeding':
        return Colors.red;
      case 'parking violation':
        return Colors.orange;
      case 'traffic light violation':
        return Colors.amber;
      case 'no helmet':
        return Colors.purple;
      case 'reckless driving':
        return Colors.deepOrange;
      // More specific cases based on violation names in violation_config.dart
      case 'driving without valid license':
      case 'driving under influence':
         return Colors.red.shade700;
      case 'driving without carrying license':
      case 'unregistered vehicle':
      case 'number coding violation (mmda)':
        return Colors.orange.shade700;
      case 'disregarding traffic signs/ red light':
      case 'illegal parking':
      case 'obstruction (crossing/driveway)':
        return Colors.amber.shade700;
      case 'no seatbelt':
      case 'using phone while driving':
        return Colors.blue.shade700;
      case 'overloading (puvs)':
      case 'operating without franchise (puvs)':
      case 'smoke belching / emission':
         return Colors.grey.shade600;
      case 'other':
        return Colors.teal;
      default:
        return Colors.blueGrey; // Fallback color
    }
  }

  IconData _getViolationIcon(String violationType) {
    switch (violationType.toLowerCase()) {
      case 'speeding':
        return Icons.speed;
      case 'parking violation':
      case 'illegal parking':
        return Icons.local_parking;
      case 'traffic light violation':
      case 'disregarding traffic signs/ red light':
        return Icons.traffic;
      case 'no helmet':
        return Icons.motorcycle; 
      case 'reckless driving':
        return Icons.warning_amber_rounded; 
      // More specific cases
      case 'driving without valid license':
      case 'driving without carrying license':
        return Icons.no_accounts;
      case 'unregistered vehicle':
         return Icons.car_crash_outlined; 
      case 'number coding violation (mmda)':
         return Icons.event_busy;
      case 'no seatbelt':
         return Icons.airline_seat_recline_normal;
      case 'driving under influence':
         return Icons.no_drinks;
      case 'overloading (puvs)':
         return Icons.groups;
      case 'operating without franchise (puvs)':
         return Icons.gavel; 
      case 'using phone while driving':
         return Icons.phone_android;
      case 'obstruction (crossing/driveway)':
         return Icons.block;
      case 'smoke belching / emission':
         return Icons.smoke_free; 
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.report_problem; 
    }
  }
  
  Color _getOffenseColor(int repetition) {
    switch (repetition) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _getOrdinalNumber(int number) {
    if (number <= 0) return '${number}th Offense';
    int lastDigit = number % 10;
    int lastTwoDigits = number % 100;
    if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
      return '${number}th Offense';
    }
    switch (lastDigit) {
      case 1:
        return '${number}st Offense';
      case 2:
        return '${number}nd Offense';
      case 3:
        return '${number}rd Offense';
      default:
        return '${number}th Offense';
    }
  }
} // End of _ViolationDetailsSheetState


// =======================================================================
// ✅ DRIVER VIOLATIONS PAGE STATE
// =======================================================================

class DriverViolationsPage extends StatefulWidget {
  final String plateNumber;

  const DriverViolationsPage({super.key, required this.plateNumber});

  @override
  State<DriverViolationsPage> createState() => _DriverViolationsPageState();
}

class _DriverViolationsPageState extends State<DriverViolationsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<ReportModel> _violations = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoad = true;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadViolations();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreViolations();
    }
  }

  Future<void> _loadViolations() async {
    if (_isLoading && !_isInitialLoad) return; 

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('reports')
          .where('plateNumber', isEqualTo: widget.plateNumber)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final List<ReportModel> newViolations = snapshot.docs
            .map(
              (doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();

        setState(() {
          _violations.clear();
          _violations.addAll(newViolations);
          _lastDocument = snapshot.docs.last;
          _hasMoreData = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(() {
          _violations.clear(); 
          _hasMoreData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading violations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _loadMoreViolations() async {
    if (_isLoading || !_hasMoreData || _lastDocument == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('reports')
          .where('plateNumber', isEqualTo: widget.plateNumber)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final List<ReportModel> newViolations = snapshot.docs
            .map(
              (doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();

        setState(() {
          _violations.addAll(newViolations);
          _lastDocument = snapshot.docs.last;
          _hasMoreData = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more violations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshViolations() async {
    setState(() {
      _lastDocument = null;
      _hasMoreData = true;
      _isInitialLoad = true; 
    });
    await _loadViolations(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MainColor().primary,
        foregroundColor: Colors.white,
        title: Text(
          'My Violations',
          style: TextStyle(
            fontSize: FontSizes().h3,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: appBg,
        child: Column(
          children: [
            // Header Info Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Vehicle: ${widget.plateNumber}',
                        style: TextStyle(
                          fontSize: FontSizes().h4,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Violations: ${_violations.length}${_hasMoreData ? '+' : ''}',
                    style: TextStyle(
                      fontSize: FontSizes().body,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Violations List
            Expanded(
              child: _isInitialLoad
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Loading violations...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: FontSizes().body,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _violations.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshViolations,
                          color: Colors.white,
                          backgroundColor: MainColor().primary,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount:
                                _violations.length + (_isLoading && _hasMoreData ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _violations.length) {
                                return _buildLoadingIndicator();
                              }
                              return _buildViolationCard(_violations[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'No Violations Found',
              style: TextStyle(
                fontSize: FontSizes().h3,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Great news! You have no traffic violations on record for vehicle ${widget.plateNumber}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FontSizes().body,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshViolations,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MainColor().primary.withOpacity(0.5),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildViolationCard(ReportModel violation) {
    String primaryViolation = violation.violations.isNotEmpty
        ? violation.violations.first.violationName
        : 'Traffic Violation';
        
    String? formattedDueDate;
    if (violation.dueDate != null) {
      final DateFormat cardDateFormat = DateFormat('MMM d, yyyy'); // Simple format
      formattedDueDate = 'Due: ${cardDateFormat.format(violation.dueDate!)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showViolationDetails(violation),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getViolationColor(
                            primaryViolation,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getViolationIcon(primaryViolation),
                          color: _getViolationColor(primaryViolation),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryViolation,
                              style: TextStyle(
                                fontSize: FontSizes().h4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              violation.address,
                              style: TextStyle(
                                fontSize: FontSizes().body,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // ✅ FIXED: Replaced Row with Wrap
                            Wrap(
                              spacing: 12.0, // Horizontal space
                              runSpacing: 4.0,  // Vertical space if it wraps
                              children: [
                                // --- Date Created ---
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateSimple(violation.createdAt), // Use simple format
                                      style: TextStyle(
                                        fontSize: FontSizes().caption,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // --- Due Date (if exists) ---
                                if (formattedDueDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                       Icon(
                                          Icons.timer_off_outlined,
                                          size: 14,
                                          color: Colors.red.withOpacity(0.8),
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         formattedDueDate,
                                         style: TextStyle(
                                           fontSize: FontSizes().caption,
                                           color: Colors.red.withOpacity(0.9),
                                           fontWeight: FontWeight.w600,
                                         ),
                                       ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ✅ FIXED: This Column now contains a constrained Text widget
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(violation.status)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(violation.status)
                                    .withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              violation.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: FontSizes().caption,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(violation.status),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ✅ FIXED: Wrapped Text in a Container with constraints
                          Container(
                            // This constraint prevents the Text from expanding
                            // and causing the overflow.
                            constraints: BoxConstraints(maxWidth: 90), 
                            child: Text(
                              violation.trackingNumber ?? 'N/A',
                              style: TextStyle(
                                fontSize: FontSizes().caption,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis, // Truncate with ...
                              maxLines: 1,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (violation.violations.length > 1) ...[
                    const SizedBox(height: 12),
                    Text(
                      '+${violation.violations.length - 1} more violation${violation.violations.length > 2 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: FontSizes().caption,
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
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

  void _showViolationDetails(ReportModel violation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ViolationDetailsSheet(violation: violation),
    );
  }

  String _formatDateSimple(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    // Use a simple format for the card
    return DateFormat('MMM d, yyyy').format(dateTime); 
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Overturned':
        return Colors.blue;
      case 'Submitted':
        return Colors.purple;
      case 'Cancelled':
        return Colors.grey;
      default: // Includes 'Pending' or any other status
        return Colors.orange;
    }
  }

  // ✅ FIXED: These functions are now inside _DriverViolationsPageState
  // and match the comprehensive versions from the details sheet.
  Color _getViolationColor(String violationType) {
    switch (violationType.toLowerCase()) {
      case 'speeding':
        return Colors.red;
      case 'parking violation':
        return Colors.orange;
      case 'traffic light violation':
        return Colors.amber;
      case 'no helmet':
        return Colors.purple;
      case 'reckless driving':
        return Colors.deepOrange;
      // More specific cases based on violation names in violation_config.dart
      case 'driving without valid license':
      case 'driving under influence':
         return Colors.red.shade700;
      case 'driving without carrying license':
      case 'unregistered vehicle':
      case 'number coding violation (mmda)':
        return Colors.orange.shade700;
      case 'disregarding traffic signs/ red light':
      case 'illegal parking':
      case 'obstruction (crossing/driveway)':
        return Colors.amber.shade700;
      case 'no seatbelt':
      case 'using phone while driving':
        return Colors.blue.shade700;
      case 'overloading (puvs)':
      case 'operating without franchise (puvs)':
      case 'smoke belching / emission':
         return Colors.grey.shade600;
      case 'other':
        return Colors.teal;
      default:
        return Colors.blueGrey; // Fallback color
    }
  }

  IconData _getViolationIcon(String violationType) {
    switch (violationType.toLowerCase()) {
      case 'speeding':
        return Icons.speed;
      case 'parking violation':
      case 'illegal parking':
        return Icons.local_parking;
      case 'traffic light violation':
      case 'disregarding traffic signs/ red light':
        return Icons.traffic;
      case 'no helmet':
        return Icons.motorcycle; 
      case 'reckless driving':
        return Icons.warning_amber_rounded; 
      // More specific cases
      case 'driving without valid license':
      case 'driving without carrying license':
        return Icons.no_accounts;
      case 'unregistered vehicle':
         return Icons.car_crash_outlined; 
      case 'number coding violation (mmda)':
         return Icons.event_busy;
      case 'no seatbelt':
         return Icons.airline_seat_recline_normal;
      case 'driving under influence':
         return Icons.no_drinks;
      case 'overloading (puvs)':
         return Icons.groups;
      case 'operating without franchise (puvs)':
         return Icons.gavel; 
      case 'using phone while driving':
         return Icons.phone_android;
      case 'obstruction (crossing/driveway)':
         return Icons.block;
      case 'smoke belching / emission':
         return Icons.smoke_free; 
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.report_problem; 
    }
  }

} // End of _DriverViolationsPageState