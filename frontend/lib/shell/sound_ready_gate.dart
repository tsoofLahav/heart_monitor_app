import 'package:heart_feedback/shell/app_design.dart';
import 'package:heart_feedback/shell/silent_status_filter.dart';
import 'package:heart_feedback/recording/recording_voice.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/locale_controller.dart';
import 'package:heart_feedback/shell/sound_status.dart';

/// Required media volume for voice instructions and counting sounds.
const double kMinAudibleVolume = 0.55;

class SoundGuard extends StatefulWidget {
  final Widget child;
  final SoundStatusSource? source;
  const SoundGuard({super.key, required this.child, this.source});

  @override
  State<SoundGuard> createState() => _SoundGuardState();
}

class _SoundGuardState extends State<SoundGuard> with WidgetsBindingObserver {
  final AudioPlayer _cuePlayer = AudioPlayer();
  late final SoundStatusSource _source;
  double? _volume;
  bool? _silent;
  final _silentFilter = SilentStatusFilter();
  bool _checking = true;
  bool _modalVisible = false;
  bool _active = true;
  bool _initialized = false;
  bool _refreshing = false;
  int _epoch = 0;
  int _volumeRevision = 0;
  Timer? _pollTimer;
  StreamSubscription<double>? _volumeSubscription;

  bool get _volumeOk => _volume != null && _volume! >= kMinAudibleVolume;
  bool get _ringerBlocking => _silent != false;
  bool get _ready => !_checking && _volumeOk && !_ringerBlocking;
  bool get _enabled => LocaleController.instance.hasChosenLocale;

  @override
  void initState() {
    super.initState();
    _source = widget.source ?? DeviceSoundStatus();
    WidgetsBinding.instance.addObserver(this);
    LocaleController.instance.addListener(_onLocaleChanged);
    _volumeSubscription = _source.volumeChanges.listen((volume) {
      if (!mounted || !_active) return;
      _volumeRevision++;
      setState(() => _volume = _validVolume(volume));
      _syncModalVisibility();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  double? _validVolume(double? value) =>
      value != null && value.isFinite && value >= 0 && value <= 1
          ? value
          : null;

  Future<void> _bootstrap() async {
    try {
      await _source.initialize();
    } catch (e) {
      debugPrint('Sound monitoring setup: $e');
    }
    if (!mounted) return;
    _initialized = true;
    if (_active) {
      await _refreshAll(force: true);
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!mounted || !_active) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshAll());
    });
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    if (_enabled && _active && _initialized) {
      unawaited(_refreshAll(force: true));
    } else if (!_enabled) {
      setState(() => _modalVisible = false);
    }
  }

  Future<void> _refreshAll({bool force = false}) async {
    if (!_active || !_enabled || !mounted || (_refreshing && !force)) return;
    final epoch = ++_epoch;
    final volumeRevision = _volumeRevision;
    _refreshing = true;
    double? volume;
    bool? silent;
    try {
      volume = _validVolume(
          await _source.readVolume().timeout(const Duration(seconds: 3)));
    } catch (e) {
      debugPrint('Sound guard volume: $e');
    }
    try {
      silent = await _source.readSilent().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Sound guard silent mode: $e');
    }
    if (!mounted || !_active || epoch != _epoch) return;
    _refreshing = false;
    setState(() {
      if (volumeRevision == _volumeRevision) _volume = volume;
      _silent = _silentFilter.update(silent);
      _checking = _silentFilter.pending;
    });
    _syncModalVisibility();
  }

  void _syncModalVisibility() {
    if (!_active || !_enabled || _checking || !mounted) return;
    // One threshold for launch, foreground changes, and every resume.
    // Unknown/failed checks never count as a successful sound configuration.
    if (!_ready && !_modalVisible) setState(() => _modalVisible = true);
  }

  void _dismissIfReady() {
    if (!_ready) return;
    setState(() => _modalVisible = false);
  }

  Future<void> _playTestVoice() async {
    try {
      await _cuePlayer.stop();
      await _cuePlayer.play(
          AssetSource(recordingVoiceAsset(
              LocaleController.instance.locale.languageCode, 'ready')),
          volume: 1.0);
    } catch (e) {
      debugPrint('Test voice failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _silentFilter.reset();
    _epoch++; // Ignore reads started before this lifecycle transition.
    _refreshing = false;
    _pollTimer?.cancel();
    if (mounted) setState(() => _checking = true);
    if (_active && _initialized) {
      unawaited(_refreshAll(force: true));
      _startPolling();
    } else {
      unawaited(_cuePlayer.stop());
    }
  }

  @override
  void dispose() {
    _epoch++;
    _pollTimer?.cancel();
    _volumeSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    LocaleController.instance.removeListener(_onLocaleChanged);
    _source.dispose();
    _cuePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Positioned.fill is required: a bare Stack child can collapse and leave
    // the native FlutterViewController white background visible on iOS.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
            child: AbsorbPointer(
                absorbing: _enabled && _checking, child: widget.child)),
        if (_enabled && _modalVisible) ...[
          const ModalBarrier(dismissible: false, color: Color(0x99000000)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                  child: _SoundModalCard(
                volume: _volume ?? 0,
                checking: _checking,
                volumeOk: _volumeOk,
                ringerBlocking: _ringerBlocking,
                showRingerStatus: _source.supportsSilentMode,
                statusKnown: _volume != null && _silent != null,
                ready: _ready,
                onPlayTestBeep: _playTestVoice,
                onContinue: _dismissIfReady,
              )),
            ),
          ),
        ],
      ],
    );
  }
}

class _SoundModalCard extends StatelessWidget {
  final double volume;
  final bool checking;
  final bool volumeOk;
  final bool ringerBlocking;
  final bool showRingerStatus;
  final bool ready;
  final bool statusKnown;
  final VoidCallback onPlayTestBeep;
  final VoidCallback onContinue;

  const _SoundModalCard({
    required this.volume,
    required this.checking,
    required this.volumeOk,
    required this.ringerBlocking,
    required this.showRingerStatus,
    required this.ready,
    required this.statusKnown,
    required this.onPlayTestBeep,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    final volumePercent = (volume * 100).round().clamp(0, 100);
    final needPercent = (kMinAudibleVolume * 100).round();

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.volume_up, color: AppColors.accent, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.turnSoundOn,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.title,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.soundGateBody,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppType.secondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (checking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              )
            else if (!statusKnown) ...[
              Text(l10n.soundStatusUnavailable,
                  style: const TextStyle(color: Colors.orangeAccent)),
            ] else ...[
              if (showRingerStatus) ...[
                _StatusRow(
                  ok: !ringerBlocking,
                  label: ringerBlocking
                      ? l10n.phoneSilentVibrate
                      : l10n.ringerSwitchOk,
                  fixHint: ringerBlocking ? l10n.flipSilentSwitchHint : null,
                ),
                const SizedBox(height: 10),
              ],
              _StatusRow(
                ok: volumeOk,
                label: volumeOk
                    ? l10n.volumeLoudEnough(volumePercent)
                    : l10n.volumeTooLow(volumePercent, needPercent),
                fixHint: volumeOk ? null : l10n.volumeUpHint,
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onPlayTestBeep,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.playTestBeep),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: ready ? onContinue : null,
              style: primaryActionStyle(),
              child: Text(
                ready ? l10n.continueAction : l10n.waitingForSound,
                style: const TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool ok;
  final String label;
  final String? fixHint;

  const _StatusRow({
    required this.ok,
    required this.label,
    this.fixHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok ? AppColors.accent.withValues(alpha: 0.7) : Colors.white12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error_outline,
            color: ok ? AppColors.accent : Colors.orangeAccent,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppType.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (fixHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    fixHint!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: AppType.secondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
