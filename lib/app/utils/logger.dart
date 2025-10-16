import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart'; // To check for release mode

/// A globally accessible logger instance for the entire application.
///
/// This setup uses the 'logger' package to provide colorful, formatted
/// logging in the debug console. It is configured to only output logs
/// in debug mode, preventing verbose logs from appearing in production builds.
///
/// Usage:
/// Import this file and use the `log` instance directly.
///
///   log.v("Verbose log");
///   log.d("Debug log");
///   log.i("Info log");
///   log.w("Warning log");
///   log.e("Error log", error: 'Some error object', stackTrace: s);
///   log.wtf("What a terrible failure log");
///
final log = Logger(
  // The printer defines the format of the log output.
  // PrettyPrinter provides a well-structured and colorful output.
  printer: PrettyPrinter(
    methodCount: 1, // number of method calls to be displayed
    errorMethodCount: 8, // number of method calls if stacktrace is provided
    lineLength: 120, // width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    printTime: false, // Should each log print contain a timestamp
  ),
  // The output defines where the log messages are sent.
  // LogOutput sends them to the console. We can create custom outputs
  // to send logs to a file or a remote server (e.g., Crashlytics).
  output: ConsoleOutput(),
  // The filter determines which logs should be shown.
  // DevelopmentFilter only shows logs when not in release mode (kReleaseMode is false).
  filter: DevelopmentFilter(),
);

/// A simple implementation of LogOutput that prints to the console.
class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // Use debugPrint to avoid logs being truncated in the Android console.
      debugPrint(line);
    }
  }
}
