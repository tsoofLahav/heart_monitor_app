import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/locale_controller.dart';

/// First-launch language picker. Shown before any localized flow copy.
/// Labels are bilingual so the choice is clear without a prior locale.
class LanguageOnboardingScreen extends StatefulWidget {
  const LanguageOnboardingScreen({super.key});

  @override
  State<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState extends State<LanguageOnboardingScreen> {
  String? _pendingCode;

  Future<void> _confirm() async {
    final code = _pendingCode;
    if (code == null) return;
    await LocaleController.instance.setLocale(Locale(code));
    // MaterialApp home switches to WelcomePage once hasChosenLocale is true.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ProtocolCenteredScrollBody(
          action: ElevatedButton(
            onPressed: _pendingCode == null ? null : _confirm,
            style: primaryActionStyle(),
            child: const Text('Continue  ·  המשך', textAlign: TextAlign.center),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.language, color: AppColors.accent, size: 56),
              const SizedBox(height: 28),
              const Text(
                'Choose language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppType.title,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'בחרו שפה',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppType.title,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You can change this later in Profile.\nאפשר לשנות זאת אחר כך בפרופיל.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppType.secondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _LangOption(
                title: 'English',
                selected: _pendingCode == 'en',
                onTap: () => setState(() => _pendingCode = 'en'),
              ),
              const SizedBox(height: 12),
              _LangOption(
                title: 'עברית',
                selected: _pendingCode == 'he',
                onTap: () => setState(() => _pendingCode = 'he'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppType.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.accent : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
