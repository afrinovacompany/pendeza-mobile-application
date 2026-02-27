// =============================================================================
// Payment Receipt Screen
// =============================================================================
// Shows a professional digital receipt after successful payment.
// Fetches all data from Firestore (appointment, salon, services, user).
// Allows the user to download as PDF or share.
// =============================================================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pendeza/app/utils/logger.dart';

/// Data class holding all receipt information fetched from Firestore
class ReceiptData {
  final String receiptNumber;
  final String appointmentId;
  final double amount;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String salonName;
  final String? salonAddress;
  final String? salonPhone;
  final String paymentMethod;
  final DateTime paidAt;
  final DateTime? appointmentDate;
  final int? durationMinutes;
  final String? transactionId;
  final List<String> services;
  final String status;

  const ReceiptData({
    required this.receiptNumber,
    required this.appointmentId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.salonName,
    this.salonAddress,
    this.salonPhone,
    required this.paymentMethod,
    required this.paidAt,
    this.appointmentDate,
    this.durationMinutes,
    this.transactionId,
    this.services = const [],
    this.status = 'Confirmed',
  });
}

/// Payment Receipt Screen
class PaymentReceiptScreen extends StatefulWidget {
  final String appointmentId;
  final double amount;
  final String customerName;
  final String customerEmail;

  const PaymentReceiptScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  ReceiptData? _receiptData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _loadReceiptData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // DATA FETCHING - All data loaded from Firestore
  // ===========================================================================

  Future<void> _loadReceiptData() async {
    try {
      final db = FirebaseFirestore.instance;

      // 1. Load appointment document
      final appointmentDoc =
          await db.collection('appointments').doc(widget.appointmentId).get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final appointmentData = appointmentDoc.data()!;

      // Extract appointment fields
      final salonId = appointmentData['salonId'] as String? ?? '';
      final clientId = appointmentData['clientId'] as String? ?? '';
      final serviceIds =
          List<String>.from(appointmentData['serviceIds'] ?? []);
      final paymentMethod =
          appointmentData['paymentMethod'] as String? ?? 'Mobile Payment';
      final transactionId =
          appointmentData['paymentTransactionId'] as String?;
      final status = appointmentData['status'] as String? ?? 'Confirmed';
      final durationMinutes = appointmentData['durationMinutes'] as int?;

      final paidAt = appointmentData['paidAt'] != null
          ? (appointmentData['paidAt'] as Timestamp).toDate()
          : DateTime.now();

      final appointmentDate = appointmentData['startTime'] != null
          ? (appointmentData['startTime'] as Timestamp).toDate()
          : null;

      // Use totalPrice from Firestore (source of truth), fallback to widget.amount
      final amount =
          (appointmentData['totalPrice'] as num?)?.toDouble() ?? widget.amount;

      // 2. Fetch salon details, client details, and service names in parallel
      final futures = await Future.wait([
        // Salon document
        salonId.isNotEmpty
            ? db.collection('salons').doc(salonId).get()
            : Future.value(null),
        // Client/user document
        clientId.isNotEmpty
            ? db.collection('users').doc(clientId).get()
            : Future.value(null),
        // Service documents (whereIn supports max 30 items)
        (serviceIds.isNotEmpty && salonId.isNotEmpty)
            ? db
                .collection('salons')
                .doc(salonId)
                .collection('services')
                .where(FieldPath.documentId,
                    whereIn: serviceIds.take(30).toList())
                .get()
            : Future.value(null),
      ]);

      // 3. Extract salon data
      String salonName = '';
      String? salonAddress;
      String? salonPhone;

      final salonSnapshot =
          futures[0] as DocumentSnapshot<Map<String, dynamic>>?;
      if (salonSnapshot != null && salonSnapshot.exists) {
        final salonData = salonSnapshot.data()!;
        salonName = salonData['salonName'] as String? ?? '';
        salonAddress = salonData['address'] as String?;
        salonPhone = salonData['phoneNumber'] as String?;

        // Build richer address if region/district available
        final region = salonData['region'] as String?;
        final district = salonData['district'] as String?;
        if (salonAddress == null || salonAddress.isEmpty) {
          final parts = <String>[];
          if (district != null && district.isNotEmpty) parts.add(district);
          if (region != null && region.isNotEmpty) parts.add(region);
          if (parts.isNotEmpty) salonAddress = parts.join(', ');
        }
      }

      // 4. Extract client data
      String customerName = widget.customerName;
      String customerEmail = widget.customerEmail;
      String? customerPhone;

      final userSnapshot =
          futures[1] as DocumentSnapshot<Map<String, dynamic>>?;
      if (userSnapshot != null && userSnapshot.exists) {
        final userData = userSnapshot.data()!;
        // Use Firestore data as source of truth, fallback to widget params
        final firestoreName = userData['fullName'] as String?;
        final firestoreEmail = userData['email'] as String?;
        if (firestoreName != null && firestoreName.isNotEmpty) {
          customerName = firestoreName;
        }
        if (firestoreEmail != null && firestoreEmail.isNotEmpty) {
          customerEmail = firestoreEmail;
        }
        customerPhone = userData['phoneNumber'] as String?;
      }

      // 5. Extract service names
      List<String> serviceNames = [];
      final servicesSnapshot =
          futures[2] as QuerySnapshot<Map<String, dynamic>>?;
      if (servicesSnapshot != null) {
        serviceNames = servicesSnapshot.docs.map((doc) {
          final data = doc.data();
          return data['name'] as String? ?? 'Service';
        }).toList();
      }

      // 6. Generate receipt number from appointment ID
      final receiptNumber =
          'PND-${widget.appointmentId.substring(0, 8).toUpperCase()}';

      if (!mounted) return;

      setState(() {
        _receiptData = ReceiptData(
          receiptNumber: receiptNumber,
          appointmentId: widget.appointmentId,
          amount: amount,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          salonName: salonName,
          salonAddress: salonAddress,
          salonPhone: salonPhone,
          paymentMethod: paymentMethod,
          paidAt: paidAt,
          appointmentDate: appointmentDate,
          durationMinutes: durationMinutes,
          transactionId: transactionId,
          services: serviceNames,
          status: status,
        );
        _isLoading = false;
      });

      _animController.forward();
    } catch (e, s) {
      log.e('Failed to load receipt data', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load receipt details. Please check your bookings.';
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en');
    return formatter.format(amount);
  }

  String _formatPhone(String phone) {
    // Format +255XXXXXXXXX -> +255 XXX XXX XXX
    if (phone.startsWith('+255') && phone.length >= 13) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7, 10)} ${phone.substring(10)}';
    }
    if (phone.startsWith('255') && phone.length >= 12) {
      return '+${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6, 9)} ${phone.substring(9)}';
    }
    return phone;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/client/bookings');
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            onPressed: () => context.go('/client/bookings'),
          ),
          title: Text(
            'Payment Receipt',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          centerTitle: true,
          actions: [
            if (_receiptData != null)
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _shareReceipt(),
                tooltip: 'Share Receipt',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState(theme)
                : _buildContent(theme),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadReceiptData();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/client/bookings'),
              child: const Text('Go to Bookings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final receipt = _receiptData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Success animation
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),

          const SizedBox(height: 16),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  'Payment Successful!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your booking has been confirmed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Receipt card
          FadeTransition(
            opacity: _fadeAnim,
            child: _buildReceiptCard(theme, receipt),
          ),

          const SizedBox(height: 20),

          // Action buttons
          FadeTransition(
            opacity: _fadeAnim,
            child: _buildActionButtons(theme),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(ThemeData theme, ReceiptData receipt) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final appointmentDateFormat = DateFormat('EEE, MMM dd yyyy');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with brand
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'PENDEZA',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PAYMENT RECEIPT',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Amount section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  'Amount Paid',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'TZS ${_formatAmount(receipt.amount)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Dashed divider
          _buildDashedDivider(),

          // Salon & booking details section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailRow(
                  theme,
                  'Receipt No.',
                  receipt.receiptNumber,
                  isBold: true,
                ),

                const SizedBox(height: 14),
                _buildDetailRow(theme, 'Salon', receipt.salonName),

                if (receipt.salonAddress != null &&
                    receipt.salonAddress!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(theme, 'Location', receipt.salonAddress!),
                ],

                if (receipt.salonPhone != null &&
                    receipt.salonPhone!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    theme,
                    'Salon Phone',
                    _formatPhone(receipt.salonPhone!),
                  ),
                ],

                if (receipt.services.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    theme,
                    receipt.services.length == 1 ? 'Service' : 'Services',
                    receipt.services.join(', '),
                  ),
                ],

                if (receipt.appointmentDate != null) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    theme,
                    'Appointment',
                    '${appointmentDateFormat.format(receipt.appointmentDate!)} at ${timeFormat.format(receipt.appointmentDate!)}',
                  ),
                ],

                if (receipt.durationMinutes != null &&
                    receipt.durationMinutes! > 0) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    theme,
                    'Duration',
                    receipt.durationMinutes! >= 60
                        ? '${receipt.durationMinutes! ~/ 60}h ${receipt.durationMinutes! % 60}min'
                        : '${receipt.durationMinutes}min',
                  ),
                ],
              ],
            ),
          ),

          // Dashed divider
          _buildDashedDivider(),

          // Customer & payment details section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailRow(theme, 'Customer', receipt.customerName),

                if (receipt.customerPhone != null &&
                    receipt.customerPhone!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    theme,
                    'Phone',
                    _formatPhone(receipt.customerPhone!),
                  ),
                ],

                const SizedBox(height: 14),
                _buildDetailRow(theme, 'Email', receipt.customerEmail),

                const SizedBox(height: 14),
                _buildDetailRow(
                  theme,
                  'Payment Method',
                  receipt.paymentMethod,
                ),

                const SizedBox(height: 14),
                _buildDetailRow(
                  theme,
                  'Paid On',
                  '${dateFormat.format(receipt.paidAt)} at ${timeFormat.format(receipt.paidAt)}',
                ),

                if (receipt.transactionId != null &&
                    receipt.transactionId!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    theme,
                    'Transaction ID',
                    receipt.transactionId!,
                    isSmall: true,
                  ),
                ],
              ],
            ),
          ),

          // Dashed divider
          _buildDashedDivider(),

          // Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PAID',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thank you for choosing Pendeza!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: theme.colorScheme.onSurface,
              fontSize: isSmall ? 12 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(dashCount, (_) {
              return Container(
                width: dashWidth,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                color: Colors.grey.shade300,
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Download PDF button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              'Download Receipt',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Go to bookings button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/client/bookings'),
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            label: const Text(
              'View My Bookings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PDF Generation
  // ===========================================================================

  Future<pw.Document> _generatePdf() async {
    final receipt = _receiptData!;
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final appointmentDateFormat = DateFormat('EEE, MMM dd yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6366F1'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PENDEZA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#C7D2FE'),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Amount
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Amount Paid',
                      style: pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'TZS ${_formatAmount(receipt.amount)}',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Salon & Booking Details
              pw.Text(
                'Booking Details',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 12),

              _pdfDetailRow('Receipt No.', receipt.receiptNumber),
              _pdfDetailRow('Salon', receipt.salonName),
              if (receipt.salonAddress != null &&
                  receipt.salonAddress!.isNotEmpty)
                _pdfDetailRow('Location', receipt.salonAddress!),
              if (receipt.salonPhone != null && receipt.salonPhone!.isNotEmpty)
                _pdfDetailRow('Salon Phone', _formatPhone(receipt.salonPhone!)),
              if (receipt.services.isNotEmpty)
                _pdfDetailRow('Services', receipt.services.join(', ')),
              if (receipt.appointmentDate != null)
                _pdfDetailRow(
                  'Appointment',
                  '${appointmentDateFormat.format(receipt.appointmentDate!)} at ${timeFormat.format(receipt.appointmentDate!)}',
                ),
              if (receipt.durationMinutes != null &&
                  receipt.durationMinutes! > 0)
                _pdfDetailRow(
                  'Duration',
                  receipt.durationMinutes! >= 60
                      ? '${receipt.durationMinutes! ~/ 60}h ${receipt.durationMinutes! % 60}min'
                      : '${receipt.durationMinutes}min',
                ),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Customer & Payment Details
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 12),

              _pdfDetailRow('Customer', receipt.customerName),
              if (receipt.customerPhone != null &&
                  receipt.customerPhone!.isNotEmpty)
                _pdfDetailRow(
                    'Phone', _formatPhone(receipt.customerPhone!)),
              _pdfDetailRow('Email', receipt.customerEmail),
              _pdfDetailRow('Payment Method', receipt.paymentMethod),
              _pdfDetailRow(
                'Paid On',
                '${dateFormat.format(receipt.paidAt)} at ${timeFormat.format(receipt.paidAt)}',
              ),
              if (receipt.transactionId != null &&
                  receipt.transactionId!.isNotEmpty)
                _pdfDetailRow('Transaction ID', receipt.transactionId!),

              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 24),

              // Footer
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#D1FAE5'),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    'PAID',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#059669'),
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Center(
                child: pw.Text(
                  'Thank you for choosing Pendeza!',
                  style: pw.TextStyle(
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 11,
                  ),
                ),
              ),

              pw.Spacer(),

              // Bottom info
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated receipt. No signature required.',
                  style: pw.TextStyle(
                    color: PdfColors.grey400,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 11,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final pdf = await _generatePdf();
      final bytes = await pdf.save();

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/pendeza_receipt_${_receiptData!.receiptNumber}.pdf',
      );
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      // Use printing package to show print/share dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Pendeza_Receipt_${_receiptData!.receiptNumber}.pdf',
      );
    } catch (e, s) {
      log.e('Failed to generate PDF', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate receipt PDF')),
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    try {
      final receipt = _receiptData!;
      final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
      final appointmentDateFormat = DateFormat('EEE, MMM dd yyyy hh:mm a');

      final lines = <String>[
        'Pendeza - Payment Receipt',
        '',
        'Receipt: ${receipt.receiptNumber}',
        'Amount: TZS ${_formatAmount(receipt.amount)}',
        '',
        'Salon: ${receipt.salonName}',
        if (receipt.salonAddress != null && receipt.salonAddress!.isNotEmpty)
          'Location: ${receipt.salonAddress}',
        if (receipt.services.isNotEmpty)
          'Services: ${receipt.services.join(", ")}',
        if (receipt.appointmentDate != null)
          'Appointment: ${appointmentDateFormat.format(receipt.appointmentDate!)}',
        '',
        'Customer: ${receipt.customerName}',
        if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty)
          'Phone: ${_formatPhone(receipt.customerPhone!)}',
        'Payment: ${receipt.paymentMethod}',
        'Paid: ${dateFormat.format(receipt.paidAt)}',
        if (receipt.transactionId != null && receipt.transactionId!.isNotEmpty)
          'Transaction: ${receipt.transactionId}',
        '',
        'Status: PAID',
        'Thank you for choosing Pendeza!',
      ];

      await Share.share(lines.join('\n'));
    } catch (e) {
      log.e('Failed to share receipt', error: e);
    }
  }
}
