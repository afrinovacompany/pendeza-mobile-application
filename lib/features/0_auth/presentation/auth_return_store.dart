/// Holds a one-shot post-auth destination for guest conversion.
///
/// Used so a guest who signs in from booking can return to the confirm
/// screen instead of being sent to Home. Cleared after use, on owner/admin
/// auth, or if the guest leaves the auth screens without converting.
class AuthReturnStore {
  AuthReturnStore._();

  static String? _pendingRoute;

  /// Latch so GoRouter redirect and screen listeners can both call [consume]
  /// without the second caller losing the booking return. Reset by [clear]
  /// or [complete] once we have left the auth screens.
  static bool _consumed = false;
  static String? _consumedRoute;

  static void setPending(String? route) {
    if (route != null && isSafeReturnRoute(route)) {
      _pendingRoute = route;
      _consumed = false;
      _consumedRoute = null;
    }
  }

  static void clear() {
    _pendingRoute = null;
    _consumed = false;
    _consumedRoute = null;
  }

  /// Drops a consumed return after navigation has settled.
  static void complete() {
    _consumed = false;
    _consumedRoute = null;
  }

  static String? peek() => _pendingRoute ?? (_consumed ? _consumedRoute : null);

  static String? consume() {
    if (_consumed) {
      return _consumedRoute;
    }
    _consumedRoute = _pendingRoute;
    _pendingRoute = null;
    _consumed = true;
    return _consumedRoute;
  }

  /// Booking-flow paths only. Avoids open redirects.
  static bool isSafeReturnRoute(String route) {
    if (route.contains('://') || route.contains('..') || route.contains('?')) {
      return false;
    }
    return RegExp(r'^/salon/[^/]+/(services|schedule|confirm)$').hasMatch(route);
  }
}
