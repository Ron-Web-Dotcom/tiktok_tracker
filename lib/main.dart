import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

/// Main entry point of the TikTok Tracker app
/// This function runs when the app starts
void main() async {
  // Initialize Flutter framework before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Flag to track if we've already shown an error to prevent duplicates
  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  // This catches any errors that happen in the app and shows a friendly error screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset the flag after 5 seconds so new errors can be shown
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    // Return empty widget if error already shown
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  // Lock the app to portrait mode only (no landscape)
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

/// Root widget of the application
/// Sets up theme, routes, and responsive sizing
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sizer package makes the app responsive across different screen sizes
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'tiktok_tracker',
          theme: AppTheme.lightTheme, // Light mode theme
          darkTheme: AppTheme.darkTheme, // Dark mode theme
          themeMode: ThemeMode.light, // Currently using light mode
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          // This builder ensures text doesn't scale with system settings
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false, // Hide debug banner
          routes: AppRoutes.routes, // All app screens/routes
          initialRoute: AppRoutes.initial, // Start with splash screen
        );
      },
    );
  }
}
