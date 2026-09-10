import 'package:heart_feedback/shell/app_design.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/control_beep_sequence.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

/// Plays a pre-generated variable beep sequence; pops [ControlBeepSequence] when done.
class ControlListenScreen extends StatefulWidget {
  final ControlBeepSequence sequence;
  final int roundIndex;
  final String? sessionTitle;

  const ControlListenScreen({
    super.key,
    required this.sequence,
    required this.roundIndex,
    this.sessionTitle,
  });

  @override
  State<ControlListenScreen> createState() => _ControlListenScreenState();
}

class _ControlListenScreenState extends State<ControlListenScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  Ticker? _ticker;
  Timer? _heartTimer;
  DateTime? _startedAt;
  int _nextBeatIndex = 0;
  int _heartFrame = 0;
  bool _finished = false;
  bool _playing = false;

  void _startPlayback() {
    if (_playing || _finished) return;
    setState(() {
      _playing = true;
      _heartFrame = 0;
    });
    _startedAt = DateTime.now();
    _ticker = createTicker(_onTick)..start();
    _heartTimer?.cancel();
    // Same color-cycle heart as recording (`assets/heart0.png`…`heart5.png`).
    _heartTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted || !_playing) return;
      setState(() => _heartFrame = (_heartFrame + 1) % 6);
    });
  }

  void _onTick(Duration _) {
    if (_finished || !mounted || _startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!).inMicroseconds / 1e6;
    final beats = widget.sequence.beatTimesSec;
    while (_nextBeatIndex < beats.length && elapsed >= beats[_nextBeatIndex]) {
      unawaited(_player.play(AssetSource('beep.mp3'), volume: 0.85));
      _nextBeatIndex++;
    }
    if (elapsed >= widget.sequence.durationSec) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _ticker?.stop();
    _heartTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(widget.sequence);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _heartTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.sessionTitle ?? ''),
        automaticallyImplyLeading: false,
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem(
                  'Skip listening',
                  () {
                    _finished = true;
                    _ticker?.stop();
                    _heartTimer?.cancel();
                    Navigator.of(context).pop(widget.sequence);
                  },
                ),
              ],
            ),
        ],
      ),
      body: ProtocolRoundShell(
        roundNumber: widget.roundIndex + 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Image.asset(
                'assets/heart$_heartFrame.png',
                key: ValueKey<int>(_heartFrame),
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.controlListeningBody,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppType.secondary,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_playing) ...[
              const SizedBox(height: 20),
              Text(
                l10n.controlStartSoundWhenReady,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppType.secondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              IconButton.filled(
                onPressed: _startPlayback,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(18),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 40),
                tooltip: l10n.controlStartSoundWhenReady,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
