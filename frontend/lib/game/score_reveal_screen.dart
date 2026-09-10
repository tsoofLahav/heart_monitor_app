import 'package:heart_feedback/shell/app_design.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/l10n.dart';

const _imageAsset = 'assets/score_image.png';
const _maxBlurSigma = 12.0;
const _fillMs = 3000;
const _overshootMs = 450;
const _bounceMs = 550;
const _pauseBeforeExitMs = 2000;
const _totalMs = _fillMs + _overshootMs + _bounceMs;
const _overshootAmount = 0.08;

/// Full-screen score reveal: radial unblur + bold score count-up.
class ScoreRevealScreen extends StatefulWidget {
  final int roundScore;
  final void Function(int roundScore)? onSessionComplete;

  /// When true, show a back arrow after the reveal instead of auto-navigating.
  final bool showBackToMenu;
  final VoidCallback? onBackToMenu;

  const ScoreRevealScreen({
    super.key,
    required this.roundScore,
    this.onSessionComplete,
    this.showBackToMenu = false,
    this.onBackToMenu,
  });

  @override
  State<ScoreRevealScreen> createState() => _ScoreRevealScreenState();
}

class _ScoreRevealScreenState extends State<ScoreRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _visualProgress = 0;
  int _displayScore = 0;
  bool _imageMissing = false;
  bool _revealComplete = false;

  double get _targetProgress => widget.roundScore / 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..addListener(_onTick);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _revealComplete = true);
        }
        if (widget.showBackToMenu) return;
        Future.delayed(
          const Duration(milliseconds: _pauseBeforeExitMs),
          () {
            if (mounted) _finish();
          },
        );
      }
    });

    _controller.forward();
  }

  void _onTick() {
    final t = _controller.value;
    final fillEnd = _fillMs / _totalMs;
    final overshootEnd = (_fillMs + _overshootMs) / _totalMs;
    final target = _targetProgress;
    final overshootTarget = (target + _overshootAmount).clamp(0.0, 1.0);

    double visual;
    int display;

    if (t <= fillEnd) {
      final local = Curves.easeOutCubic.transform(t / fillEnd);
      visual = local * target;
      display = (local * widget.roundScore).round();
    } else if (t <= overshootEnd) {
      final local = (t - fillEnd) / (overshootEnd - fillEnd);
      visual = lerpDouble(target, overshootTarget, local)!;
      display = widget.roundScore;
    } else {
      final local =
          Curves.elasticOut.transform((t - overshootEnd) / (1 - overshootEnd));
      visual = lerpDouble(overshootTarget, target, local)!;
      display = widget.roundScore;
    }

    setState(() {
      _visualProgress = visual;
      _displayScore = display;
    });
  }

  void _finish() {
    if (!mounted) return;
    if (widget.onSessionComplete != null) {
      widget.onSessionComplete!(widget.roundScore);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageLayer(),
          if (_imageMissing) _buildMissingImageFallback(),
          _buildScoreCaption(l10n),
          if (widget.showBackToMenu && _revealComplete)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 32),
                    tooltip: l10n.backToMenu,
                    onPressed: () {
                      if (widget.onBackToMenu != null) {
                        widget.onBackToMenu!();
                      } else {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCaption(AppLocalizations l10n) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${l10n.sessionScoreTitle}:',
                  key: const ValueKey('session-score-label'),
                  maxLines: 1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppType.title,
                      height: 1.3,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.percentValue('$_displayScore'),
                key: const ValueKey('session-score-value'),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppType.metric,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageLayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _scoreImage(sharp: true),
        ShaderMask(
          shaderCallback: (bounds) => _blurMaskShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _maxBlurSigma,
              sigmaY: _maxBlurSigma,
            ),
            child: _scoreImage(sharp: false),
          ),
        ),
      ],
    );
  }

  Shader _blurMaskShader(Rect bounds) {
    final blurFraction = (1.0 - _visualProgress).clamp(0.0, 1.0);
    final innerStop = blurFraction * 0.85;

    return RadialGradient(
      center: const Alignment(0, 0.12),
      radius: 1.2,
      colors: const [Colors.white, Colors.white, Colors.transparent],
      stops: [0.0, innerStop, 1.0],
    ).createShader(bounds);
  }

  Widget _scoreImage({required bool sharp}) {
    return Image.asset(
      _imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        if (!_imageMissing && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _imageMissing = true);
          });
        }
        return Container(color: const Color(0xFF1A1A1A));
      },
    );
  }

  Widget _buildMissingImageFallback() {
    return Center(
      child: Text(
        'Add assets/score_image.png',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: AppType.secondary),
      ),
    );
  }
}
