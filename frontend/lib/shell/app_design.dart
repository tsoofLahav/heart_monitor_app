import 'package:flutter/material.dart';
import 'package:heart_feedback/shell/app_colors.dart';

/// Four readable text sizes shared by every participant-facing flow.
abstract final class AppType {
  static const double secondary = 18;
  static const double body = 20;
  static const double title = 24;
  static const double metric = 32;
}

abstract final class AppLayout {
  static const double pageInset = 24;
  static const double contentWidth = 480;
  static const double buttonHeight = 56;
  static const pagePadding = EdgeInsets.fromLTRB(24, 24, 24, 24);
  static const actionPadding = EdgeInsets.fromLTRB(24, 16, 24, 24);
}

ButtonStyle primaryActionStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.black,
      disabledBackgroundColor: const Color(0xFF303030),
      disabledForegroundColor: Colors.white70,
      minimumSize: const Size(220, AppLayout.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
          fontSize: AppType.body, height: 1.3, fontWeight: FontWeight.w600),
    );

/// Same bottom inset and width for actions; height can grow with text scaling.
class AppActionArea extends StatelessWidget {
  final Widget child;
  final bool safeBottom;
  const AppActionArea({super.key, required this.child, this.safeBottom = true});
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: AppLayout.actionPadding,
          child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppLayout.contentWidth),
                child: SizedBox(width: double.infinity, child: child),
              )),
        ),
      );
}

ThemeData appTheme() => ThemeData(
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: AppType.body, height: 1.5),
        bodyMedium: TextStyle(fontSize: AppType.body, height: 1.5),
        bodySmall: TextStyle(fontSize: AppType.secondary, height: 1.4),
        titleLarge:
            TextStyle(fontSize: AppType.title, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(fontSize: AppType.body, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: AppType.secondary),
        labelLarge:
            TextStyle(fontSize: AppType.body, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: AppType.secondary),
        labelSmall: TextStyle(fontSize: AppType.secondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryActionStyle()),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              textStyle: const TextStyle(
                  fontSize: AppType.secondary, fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              textStyle: const TextStyle(fontSize: AppType.secondary))),
      inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
