import 'guest_session_tracker.dart';
import '../utils/logger.dart';

/// Service to intelligently manage when and how to show auth prompts to guests.
///
/// This service uses behavioral triggers and timing logic to:
/// - Show prompts at optimal moments (not annoying)
/// - Respect user dismissals
/// - Vary prompt types based on context
/// - Track conversion opportunities
///
/// Strategy: Progressive engagement
/// - Start gentle (banners, cards)
/// - Increase urgency as engagement grows
/// - Respect "Not Now" decisions
class GuestPromptService {
  final GuestSessionTracker _sessionTracker;

  // Configuration constants
  static const int _minMinutesBetweenPrompts = 2;
  static const int _maxPromptsPerSession = 4;
  static const int _salonsBeforePrompt = 3;
  static const int _minutesBeforeTimePrompt = 2;
  static const int _dismissBeforeBackoff = 2;

  GuestPromptService(this._sessionTracker);

  // ============================================================================
  // PROMPT ELIGIBILITY CHECKS
  // ============================================================================

  /// Master check: Should we show ANY prompt right now?
  bool shouldShowPrompt() {
    // 1. Don't show if user dismissed too many times
    if (_sessionTracker.getPromptDismissCount() >= _dismissBeforeBackoff) {
      log.d('Prompt blocked: User dismissed too many times');
      return false;
    }

    // 2. Don't show if we've hit max prompts for this session
    final promptCount = _getEstimatedPromptsShown();
    if (promptCount >= _maxPromptsPerSession) {
      log.d('Prompt blocked: Max prompts reached for session');
      return false;
    }

    // 3. Don't show if not enough time since last prompt
    final minutesSinceLast = _sessionTracker.getMinutesSinceLastPrompt();
    if (minutesSinceLast != null && minutesSinceLast < _minMinutesBetweenPrompts) {
      log.d('Prompt blocked: Too soon since last prompt');
      return false;
    }

    return true;
  }

  /// Estimate prompts shown (since we don't track each type separately)
  int _getEstimatedPromptsShown() {
    // Rough estimate based on dismissals + time
    final dismissals = _sessionTracker.getPromptDismissCount();
    final lastPrompt = _sessionTracker.getLastPromptTimestamp();

    if (lastPrompt != null) {
      return dismissals + 1; // At least one was shown
    }
    return dismissals;
  }

  // ============================================================================
  // TRIGGER-BASED PROMPT CHECKS
  // ============================================================================

  /// Check if we should show prompt after browsing X salons
  PromptTrigger? checkBrowsingTrigger() {
    if (!shouldShowPrompt()) return null;

    final salonsViewed = _sessionTracker.salonsViewedCount;

    if (salonsViewed >= _salonsBeforePrompt) {
      log.i('Browsing trigger activated: $salonsViewed salons viewed');
      return PromptTrigger(
        type: PromptType.banner,
        reason: 'browsing_engagement',
        priority: PromptPriority.low,
        message: 'Save your favorite salons! Create an account to access them anywhere.',
      );
    }

    return null;
  }

  /// Check if we should show prompt after time spent
  PromptTrigger? checkTimeTrigger() {
    if (!shouldShowPrompt()) return null;

    final minutes = _sessionTracker.getSessionDurationMinutes();

    if (minutes >= _minutesBeforeTimePrompt) {
      log.i('Time trigger activated: $minutes minutes spent');
      return PromptTrigger(
        type: PromptType.bottomSheet,
        reason: 'time_engagement',
        priority: PromptPriority.medium,
        message: 'Enjoying Pendeza? Create an account for personalized recommendations!',
      );
    }

    return null;
  }

  /// Check if we should show prompt after favorite attempt
  PromptTrigger? checkFavoriteTrigger() {
    if (!shouldShowPrompt()) return null;

    final attempts = _sessionTracker.favoriteAttemptsCount;

    if (attempts > 0) {
      log.i('Favorite trigger activated: $attempts favorite attempts');
      return PromptTrigger(
        type: PromptType.bottomSheet,
        reason: 'favorite_attempt',
        priority: PromptPriority.high,
        message: 'Sign in to save your favorites and sync across all your devices!',
      );
    }

    return null;
  }

  /// Check if we should show prompt after service views
  PromptTrigger? checkServiceViewTrigger() {
    if (!shouldShowPrompt()) return null;

    final servicesViewed = _sessionTracker.servicesViewedCount;

    if (servicesViewed >= 2) {
      log.i('Service view trigger activated: $servicesViewed services viewed');
      return PromptTrigger(
        type: PromptType.bottomSheet,
        reason: 'service_interest',
        priority: PromptPriority.medium,
        message: 'Ready to book? Create an account to manage your appointments!',
      );
    }

    return null;
  }

  /// Check if we should show prompt after searches
  PromptTrigger? checkSearchTrigger() {
    if (!shouldShowPrompt()) return null;

    final searches = _sessionTracker.searchesMadeCount;

    if (searches >= 2) {
      log.i('Search trigger activated: $searches searches made');
      return PromptTrigger(
        type: PromptType.banner,
        reason: 'search_engagement',
        priority: PromptPriority.low,
        message: 'Get personalized recommendations based on your searches!',
      );
    }

    return null;
  }

  /// Check for high engagement (combination of factors)
  PromptTrigger? checkHighEngagementTrigger() {
    if (!shouldShowPrompt()) return null;

    if (_sessionTracker.isHighlyEngaged) {
      log.i('High engagement trigger activated: Score ${_sessionTracker.calculateEngagementScore()}');
      return PromptTrigger(
        type: PromptType.bottomSheet,
        reason: 'high_engagement',
        priority: PromptPriority.high,
        message: 'You\'re exploring a lot! Create an account to unlock all features.',
      );
    }

    return null;
  }

  // ============================================================================
  // SMART TRIGGER SELECTION
  // ============================================================================

  /// Get the best trigger to show right now
  /// Returns null if no trigger should be shown
  PromptTrigger? getBestTriggerNow() {
    if (!shouldShowPrompt()) return null;

    // Collect all active triggers
    final triggers = <PromptTrigger>[
      if (checkFavoriteTrigger() != null) checkFavoriteTrigger()!,
      if (checkHighEngagementTrigger() != null) checkHighEngagementTrigger()!,
      if (checkServiceViewTrigger() != null) checkServiceViewTrigger()!,
      if (checkTimeTrigger() != null) checkTimeTrigger()!,
      if (checkBrowsingTrigger() != null) checkBrowsingTrigger()!,
      if (checkSearchTrigger() != null) checkSearchTrigger()!,
    ];

    if (triggers.isEmpty) return null;

    // Sort by priority (high to low)
    triggers.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Return highest priority trigger
    final bestTrigger = triggers.first;
    log.i('Best trigger selected: ${bestTrigger.reason} (${bestTrigger.priority})');

    return bestTrigger;
  }

  /// Check for specific context-based triggers
  PromptTrigger? checkContextTrigger(String context, {String? customMessage}) {
    if (!shouldShowPrompt()) return null;

    switch (context) {
      case 'salon_detail':
        return PromptTrigger(
          type: PromptType.banner,
          reason: 'salon_detail_view',
          priority: PromptPriority.low,
          message: customMessage ?? 'Like this salon? Save it to your favorites!',
        );

      case 'booking_flow':
      // This is handled by the existing BookingBloc logic
        return null;

      case 'discovery_scroll':
        if (_sessionTracker.salonsViewedCount >= 5) {
          return PromptTrigger(
            type: PromptType.banner,
            reason: 'discovery_engagement',
            priority: PromptPriority.low,
            message: customMessage ?? 'Found some favorites? Save them by creating an account!',
          );
        }
        return null;

      default:
        return null;
    }
  }

  // ============================================================================
  // PROMPT TRACKING
  // ============================================================================

  /// Record that a prompt was shown
  Future<void> recordPromptShown(PromptType type, String reason) async {
    await _sessionTracker.recordPromptShown();
    log.i('Prompt shown: $type for $reason');
  }

  /// Record that a prompt was dismissed
  Future<void> recordPromptDismissed(PromptType type, String reason) async {
    await _sessionTracker.recordPromptDismissed();
    log.i('Prompt dismissed: $type for $reason');
  }

  /// Record that user clicked on prompt (converted)
  void recordPromptClicked(PromptType type, String reason) {
    log.i('Prompt clicked: $type for $reason - User converting!');
    // You can add analytics tracking here
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Reset prompt cooldowns (for testing or special cases)
  Future<void> resetPromptCooldowns() async {
    await _sessionTracker.resetPromptData();
    log.i('Prompt cooldowns reset');
  }

  /// Get debug info about current prompt eligibility
  Map<String, dynamic> getDebugInfo() {
    return {
      'canShowPrompt': shouldShowPrompt(),
      'promptDismissCount': _sessionTracker.getPromptDismissCount(),
      'estimatedPromptsShown': _getEstimatedPromptsShown(),
      'minutesSinceLastPrompt': _sessionTracker.getMinutesSinceLastPrompt(),
      'sessionSummary': _sessionTracker.getSessionSummary(),
      'activeTriggers': {
        'browsing': checkBrowsingTrigger() != null,
        'time': checkTimeTrigger() != null,
        'favorite': checkFavoriteTrigger() != null,
        'serviceView': checkServiceViewTrigger() != null,
        'search': checkSearchTrigger() != null,
        'highEngagement': checkHighEngagementTrigger() != null,
      },
    };
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Types of prompts we can show
enum PromptType {
  banner,       // Dismissible banner at top/bottom
  bottomSheet,  // Modal bottom sheet
  card,         // In-feed card
  dialog,       // Full modal dialog (used for critical actions only)
}

/// Priority levels for prompts
enum PromptPriority {
  low,     // Show if nothing else is happening
  medium,  // Show when moderately appropriate
  high,    // Show as soon as possible
}

/// A prompt trigger with context
class PromptTrigger {
  final PromptType type;
  final String reason;
  final PromptPriority priority;
  final String message;

  const PromptTrigger({
    required this.type,
    required this.reason,
    required this.priority,
    required this.message,
  });

  @override
  String toString() {
    return 'PromptTrigger(type: $type, reason: $reason, priority: $priority)';
  }
}