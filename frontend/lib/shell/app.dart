import 'package:heart_feedback/shell/app_design.dart';
import 'package:heart_feedback/shell/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:heart_feedback/l10n/app_localizations.dart';
import 'package:heart_feedback/recording/backend_connection.dart';
import 'package:heart_feedback/shell/language_onboarding_screen.dart';
import 'package:heart_feedback/shell/locale_controller.dart';
import 'package:heart_feedback/shell/sound_ready_gate.dart';
import 'package:heart_feedback/shell/welcome_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackendConnection.establishConnectionInBackground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BackendConnection.establishConnectionInBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorObservers: [appRouteObserver],
          locale: LocaleController.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: appTheme(),
          builder: (context, child) {
            // Always paint a black base so a missing/zero-size child cannot
            // reveal the native FlutterViewController white background on iOS.
            return ColoredBox(
              color: Colors.black,
              child: SoundGuard(
                child: child ?? const SizedBox.expand(),
              ),
            );
          },
          // Stable home identity so locale-only rebuilds don't reset the stack.
          home: const _LaunchHome(),
        );
      },
    );
  }
}

class _LaunchHome extends StatelessWidget {
  const _LaunchHome();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        if (!LocaleController.instance.hasChosenLocale) {
          return const LanguageOnboardingScreen();
        }
        return WelcomePage();
      },
    );
  }
}
