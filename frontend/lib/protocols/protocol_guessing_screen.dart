import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

class ProtocolGuessingScreen extends StatefulWidget {
  final int roundIndex;
  final int totalRounds;
  final String? title;
  final String? footerLabel;

  const ProtocolGuessingScreen({
    super.key,
    required this.roundIndex,
    this.totalRounds = 2,
    this.title,
    this.footerLabel,
  });

  @override
  State<ProtocolGuessingScreen> createState() => _ProtocolGuessingScreenState();
}

class _ProtocolGuessingScreenState extends State<ProtocolGuessingScreen> {
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _guessFocus = FocusNode();
  double _confidence = 50.0;
  bool _keyboardDismissed = false;

  void _dismissKeyboard() {
    final parsed = int.tryParse(_guessController.text.trim());
    if (parsed == null) return;
    _guessFocus.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() => _keyboardDismissed = true);
  }

  void _submit() {
    final parsed = int.tryParse(_guessController.text.trim());
    if (parsed == null) return;
    Navigator.of(context).pop((parsed, _confidence));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _guessFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _guessController.dispose();
    _guessFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roundNumber = widget.roundIndex + 1;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.title ?? l10n.roundCountBeatsTitle(roundNumber),
        ),
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem(
                  'Skip guess (28 @ 50%)',
                  () => Navigator.of(context).pop((28, 50.0)),
                ),
              ],
            ),
        ],
      ),
      body: ProtocolRoundShell(
        action: ProtocolPrimaryButton(
          label: l10n.continueAction,
          onPressed: _submit,
        ),
        roundNumber: roundNumber,
        totalRounds: widget.totalRounds,
        footerLabel: widget.footerLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.howManyBeatsCounted,
              style:
                  const TextStyle(color: Colors.white, fontSize: AppType.body),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _guessController,
              focusNode: _guessFocus,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style:
                  const TextStyle(color: Colors.white, fontSize: AppType.title),
              textAlign: TextAlign.center,
              onTap: () => setState(() => _keyboardDismissed = false),
              onSubmitted: (_) => _dismissKeyboard(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                hintText: l10n.enterNumber,
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  tooltip: l10n.okAction,
                  onPressed: _dismissKeyboard,
                  icon: const Icon(Icons.check_circle, color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.howConfident,
              style: const TextStyle(
                  color: Colors.white, fontSize: AppType.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Slider(
              value: _confidence,
              min: 0,
              max: 100,
              divisions: 20,
              label: l10n.percentValue('${_confidence.round()}'),
              activeColor: AppColors.accent,
              inactiveColor: Colors.grey[700],
              onChanged: (value) {
                if (!_keyboardDismissed) _dismissKeyboard();
                setState(() => _confidence = value);
              },
            ),
            Text(
              l10n.percentValue('${_confidence.round()}'),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: AppType.title,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
