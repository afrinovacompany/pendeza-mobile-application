import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service that manages in-app review prompts with smart throttling.
///
/// Trigger conditions (ALL must be true):
/// 1. User has completed at least [_minCompletedAppointments] appointments
/// 2. At least [_minDaysBetweenPrompts] days since last prompt
/// 3. The native in-app review API is available on the device
///
/// Note: The OS controls whether the review dialog actually shows.
/// Google/Apple rate-limit prompts to prevent spamming users.
class InAppReviewService {
  static const String _keyLastPromptDate = 'in_app_review_last_prompt';
  static const String _keyCompletedCount = 'in_app_review_completed_count';
  static const String _keyHasEverPrompted = 'in_app_review_has_prompted';

  /// Minimum completed appointments before first prompt.
  static const int _minCompletedAppointments = 3;

  /// Minimum days between review prompts.
  static const int _minDaysBetweenPrompts = 90;

  final InAppReview _inAppReview;
  final SharedPreferences _prefs;

  InAppReviewService({
    required SharedPreferences prefs,
    InAppReview? inAppReview,
  })  : _prefs = prefs,
        _inAppReview = inAppReview ?? InAppReview.instance;

  /// Call this when completed appointments are loaded.
  /// Pass the total number of completed appointments for the user.
  Future<void> onCompletedAppointmentsLoaded(int completedCount) async {
    try {
      // Store latest count
      await _prefs.setInt(_keyCompletedCount, completedCount);

      if (!_shouldRequestReview(completedCount)) return;

      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        log.d('InAppReviewService: Review API not available on this device');
        return;
      }

      log.i('InAppReviewService: Requesting in-app review');
      await _inAppReview.requestReview();
      await _markPrompted();
    } catch (e, s) {
      // Never crash the app over a review prompt
      log.e('InAppReviewService: Error requesting review',
          error: e, stackTrace: s);
    }
  }

  bool _shouldRequestReview(int completedCount) {
    // Not enough appointments yet
    if (completedCount < _minCompletedAppointments) {
      log.d('InAppReviewService: Only $completedCount completed '
          '(need $_minCompletedAppointments)');
      return false;
    }

    // Check cooldown period
    final lastPromptMs = _prefs.getInt(_keyLastPromptDate);
    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      final daysSince = DateTime.now().difference(lastPrompt).inDays;
      if (daysSince < _minDaysBetweenPrompts) {
        log.d('InAppReviewService: Cooldown active '
            '($daysSince/$_minDaysBetweenPrompts days)');
        return false;
      }
    }

    return true;
  }

  Future<void> _markPrompted() async {
    await _prefs.setInt(
      _keyLastPromptDate,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setBool(_keyHasEverPrompted, true);
    log.i('InAppReviewService: Marked review as prompted');
  }
}
