import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/experiment/experiment_store.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/prep/prep_progress_store.dart';
import 'package:heart_feedback/prep/profile_store.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/locale_controller.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

/// Prep step 1: first/last name, phone, then language.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _focusNodes = List.generate(3, (_) => FocusNode());
  final _scroll = ScrollController();
  String _trainingMode = 'ppg';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final draft = await ProfileStore.instance.load();
    if (ExperimentStore.instance.progress == null) {
      await ExperimentStore.instance.loadCached();
    }
    if (!mounted) return;
    setState(() {
      _firstCtrl.text = draft.firstName;
      _lastCtrl.text = draft.lastName;
      _phoneCtrl.text = draft.phone;
      _trainingMode = ExperimentStore.instance.progress?.trainingMode ?? 'ppg';
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _scroll.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final draft = ProfileDraft(
      firstName: _firstCtrl.text,
      lastName: _lastCtrl.text,
      phone: _phoneCtrl.text,
    );
    if (!draft.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileIncomplete)),
      );
      return;
    }

    setState(() => _saving = true);
    await ProfileStore.instance.save(draft);
    final synced = await ExperimentStore.instance.updateParticipantProfile(
      firstName: draft.firstName.trim(),
      lastName: draft.lastName.trim(),
      phone: draft.phone.trim(),
      trainingMode: _trainingMode,
    );
    if (synced) await PrepProgressStore.instance.markProfileCompleted();
    if (!mounted) return;
    setState(() => _saving = false);

    if (!synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaveFailed)),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _nextField(int current) async {
    final values = [_firstCtrl.text, _lastCtrl.text, _phoneCtrl.text];
    for (var offset = 1; offset < values.length; offset++) {
      final index = (current + offset) % values.length;
      if (values[index].trim().isEmpty) {
        _focusNodes[index].requestFocus();
        return;
      }
    }
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted && _scroll.hasClients) {
      await _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _qaSkip() async {
    _firstCtrl.text = 'QA';
    _lastCtrl.text = 'Tester';
    _phoneCtrl.text = '0500000000';
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = LocaleController.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem('Fill & save fake profile', _qaSkip),
              ],
            ),
        ],
      ),
      bottomSheet: MediaQuery.viewInsetsOf(context).bottom > 0
          ? Material(
              color: const Color(0xFF202020),
              child: SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: TextButton(
                      onPressed: () {
                        final current =
                            _focusNodes.indexWhere((node) => node.hasFocus);
                        if (current >= 0) _nextField(current);
                      },
                      child: Text(l10n.formNext)),
                ),
              ))
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final code = controller.locale.languageCode;
                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    _field(
                      label: l10n.firstName,
                      controller: _firstCtrl,
                      index: 0,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: l10n.lastName,
                      controller: _lastCtrl,
                      index: 1,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: l10n.phoneNumber,
                      controller: _phoneCtrl,
                      index: 2,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.language,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.languageSectionSubtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: AppType.secondary),
                    ),
                    const SizedBox(height: 16),
                    _ChoiceTile(
                      title: l10n.languageEnglish,
                      selected: code == 'en',
                      onTap: () => controller.setLocale(const Locale('en')),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceTile(
                      title: l10n.languageHebrew,
                      selected: code == 'he',
                      onTap: () => controller.setLocale(const Locale('he')),
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.profileGroup,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppType.body,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _ChoiceTile(
                      key: const ValueKey('profile-group-regular'),
                      title: l10n.profileGroupRegular,
                      selected: _trainingMode == 'ppg',
                      onTap: _saving
                          ? null
                          : () => setState(() => _trainingMode = 'ppg'),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceTile(
                      key: const ValueKey('profile-group-control'),
                      title: l10n.profileGroupControl,
                      selected: _trainingMode == 'audio',
                      onTap: _saving
                          ? null
                          : () => setState(() => _trainingMode = 'audio'),
                    ),
                    const SizedBox(height: 32),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                          minHeight: AppLayout.buttonHeight),
                      child: ElevatedButton(
                        style: primaryActionStyle(),
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? l10n.saving : l10n.profileSave,
                          style: const TextStyle(
                            fontSize: AppType.body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _field({
    required int index,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: AppType.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: _focusNodes[index],
          scrollPadding: const EdgeInsets.only(bottom: 80),
          onEditingComplete: () {},
          onSubmitted: (_) => _nextField(index),
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  const _ChoiceTile({
    super.key,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
