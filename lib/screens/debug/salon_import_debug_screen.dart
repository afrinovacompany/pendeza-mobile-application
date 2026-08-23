import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/salon_seeder.dart';
// 1. IMPORT THE FIX UTILITY
import 'package:pendeza/app/utils/reviews_fix_all.dart';

class SalonImportDebugScreen extends StatefulWidget {
  const SalonImportDebugScreen({super.key});

  @override
  State<SalonImportDebugScreen> createState() => _SalonImportDebugScreenState();
}

class _SalonImportDebugScreenState extends State<SalonImportDebugScreen> {
  bool _isImporting = false;
  bool _isFixingReviews = false; // New state for reviews fix
  String _statusMessage = 'Ready to import data.';

  Future<void> _importAllData() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Starting import (Salons, Reviews & Services)...';
    });

    try {
      await SalonSeeder.importAllDataToFirestore();

      if (mounted) {
        setState(() {
          _statusMessage = '✅ Import finished successfully!\n\n'
              'Check your Firestore "salons", "reviews", and "services" collections.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data successfully deployed to Firestore!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '❌ Import Error:\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  // 2. ADD THIS METHOD TO FIX REVIEWS
  Future<void> _fixReviews() async {
    setState(() {
      _isFixingReviews = true;
      _statusMessage = '🔧 Fixing reviews... cleaning up and moving data...';
    });

    try {
      await QuickReviewsFix.fix();

      if (mounted) {
        setState(() {
          _statusMessage = '✅ REVIEWS FIXED! \nData moved to salons/{id}/reviews';
          _isFixingReviews = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reviews fixed successfully! Check any salon page.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFixingReviews = false;
          _statusMessage = '❌ Fix Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing reviews: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deploy Data to Firestore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: AppConstants.padL),
            Text(
              'Import Data',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.padS),
            const Text(
              'Use "Start Import" to wipe and seed fresh data.\nUse "Fix Reviews" if reviews are missing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppConstants.padXL),

            // STATUS MESSAGE
            Container(
              padding: const EdgeInsets.all(AppConstants.padM),
              decoration: BoxDecoration(
                color: _statusMessage.contains('❌')
                    ? Colors.red.withValues(alpha: 0.1)
                    : _statusMessage.contains('✅')
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage.contains('❌')
                      ? Colors.red
                      : _statusMessage.contains('✅')
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage.contains('❌') ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // 3. ADD THE FIX REVIEWS BUTTON
            ElevatedButton.icon(
              onPressed: _isFixingReviews || _isImporting ? null : _fixReviews,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange, // Different color to distinguish
                foregroundColor: Colors.white,
              ),
              icon: _isFixingReviews
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Icon(Icons.build_circle),
              label: Text(_isFixingReviews ? 'Fixing Reviews...' : '🔧 FIX REVIEWS (Run This!)'),
            ),

            const SizedBox(height: AppConstants.padM),

            // STANDARD IMPORT BUTTON
            ElevatedButton.icon(
              onPressed: _isImporting || _isFixingReviews ? null : _importAllData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: _isImporting
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Icon(Icons.play_arrow),
              label: Text(_isImporting ? 'Importing...' : 'Reset & Import All Data'),
            ),
            const SizedBox(height: AppConstants.padL),
          ],
        ),
      ),
    );
  }
}