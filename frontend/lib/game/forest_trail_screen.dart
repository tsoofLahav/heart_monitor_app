import 'package:heart_feedback/shell/app_navigation.dart';
import 'package:heart_feedback/shell/app_design.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_feedback/experiment/assessment_screen.dart';
import 'package:heart_feedback/experiment/experiment_models.dart';
import 'package:heart_feedback/experiment/experiment_store.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/game/trail_unlock_store.dart';
import 'package:heart_feedback/protocols/control_protocol_flow_screen.dart';
import 'package:heart_feedback/protocols/protocol_flow_screen.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

/// Forest trail progress screen — shown between training sessions.
/// [currentSession]: 0 = before first session, 10 = after last session
class ForestTrailScreen extends StatelessWidget {
  final int currentSession; // 0–10
  final VoidCallback onContinue;
  final int totalSessions;

  const ForestTrailScreen({
    Key? key,
    required this.currentSession,
    required this.onContinue,
    this.totalSessions = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isFinished = currentSession >= totalSessions;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isFinished, l10n),
            Expanded(
              child: TrailMap(
                currentSession: currentSession,
                totalSessions: totalSessions,
                sessionScores: const {},
              ),
            ),
            _buildFooter(context, isFinished, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFinished, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFinished ? l10n.youReachedTheEnd : l10n.yourJourney,
            style: const TextStyle(
              color: Color(0xFFD4E8B0),
              fontSize: AppType.title,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFinished
                ? l10n.allSessionsCompleted(totalSessions)
                : l10n.sessionOfTotal(currentSession + 1, totalSessions),
            style: const TextStyle(
              color: Color(0xFF7BA05B),
              fontSize: AppType.secondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    bool isFinished,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C9E3A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            isFinished
                ? l10n.finish
                : l10n.continueToSession(currentSession + 1),
            style: const TextStyle(
              fontSize: AppType.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated scrollable trail
// ─────────────────────────────────────────────

class TrailMap extends StatefulWidget {
  final int currentSession;
  final int totalSessions;
  final Map<int, int> sessionScores;
  final bool experimentLabels;

  /// Steps that are not yet unlocked (show lock).
  final Set<int> lockedSteps;

  /// Extra soft glow (coach highlight), in addition to current step.
  final Set<int> highlightSteps;

  /// Keys for coach targeting (trail step → key).
  final Map<int, GlobalKey> nodeKeys;

  /// Next trail step (1–10) whose circle is the start control, if unlocked.
  final int? ctaStep;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final bool ctaEnabled;

  /// Ephemeral “opens tomorrow” tip targeting this locked step.
  final int? tomorrowHintStep;
  final String? tomorrowHintText;

  /// QA: tap any trail step (1–10) to enter it, regardless of progress.
  final void Function(int trailStep)? onQaEnterStep;

  const TrailMap({
    super.key,
    required this.currentSession,
    required this.totalSessions,
    required this.sessionScores,
    this.experimentLabels = false,
    this.lockedSteps = const {},
    this.highlightSteps = const {},
    this.nodeKeys = const {},
    this.ctaStep,
    this.ctaLabel,
    this.onCtaPressed,
    this.ctaEnabled = true,
    this.tomorrowHintStep,
    this.tomorrowHintText,
    this.onQaEnterStep,
  });

  @override
  State<TrailMap> createState() => TrailMapState();
}

class TrailMapState extends State<TrailMap>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late AnimationController _pulseController;
  late AnimationController _fireflyController;
  late AnimationController _bubbleController;
  int? _bubbleStep;
  final _scroll = ScrollController();
  bool _needsFocus = true;
  double _topPad = 0;
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of<void>(context);
    if (_route != route) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() => _focusCurrent();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _focusCurrent();
  }

  void _focusCurrent() {
    if (mounted) setState(() => _needsFocus = true);
  }

  @override
  void didUpdateWidget(covariant TrailMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSession != widget.currentSession ||
        (!oldWidget.ctaEnabled && widget.ctaEnabled)) _needsFocus = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _scroll.dispose();
    _pulseController.dispose();
    _fireflyController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  double _nodeX(int index, double width) {
    const double center = 0.5;
    const double offset = 0.10;
    final double shift = (index % 2 == 0) ? -offset : offset;
    return width * (center + shift);
  }

  double _nodeY(int index, double segmentHeight) =>
      _topPad + index * segmentHeight;

  void _toggleScoreBubble(int trailStep) {
    final score = widget.sessionScores[trailStep];
    if (score == null) return;
    if (_bubbleStep == trailStep) {
      setState(() => _bubbleStep = null);
      return;
    }
    setState(() => _bubbleStep = trailStep);
    _bubbleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final int totalNodes = widget.totalSessions;
    const double segmentHeight = 160.0;
    return LayoutBuilder(builder: (context, viewport) {
      final pad = viewport.maxHeight / 2;
      if (_topPad != pad) _needsFocus = true;
      _topPad = pad;
      final totalHeight = segmentHeight * (totalNodes - 1) + viewport.maxHeight;
      if (_needsFocus) {
        _needsFocus = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll.hasClients) return;
          final step = widget.currentSession.clamp(0, totalNodes - 1);
          _scroll.jumpTo((step * segmentHeight)
              .clamp(0.0, _scroll.position.maxScrollExtent));
        });
      }
      return SingleChildScrollView(
        controller: _scroll,
        reverse: true,
        padding: EdgeInsets.zero,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _fireflyController,
            _bubbleController,
          ]),
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                return SizedBox(
                  height: totalHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ForestBackgroundPainter(),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrailPainter(
                            topPad: _topPad,
                            totalNodes: totalNodes,
                            currentSession: widget.currentSession,
                            segmentHeight: segmentHeight,
                            totalHeight: totalHeight,
                            pulseValue: _pulseController.value,
                            sessionScores: widget.sessionScores,
                            experimentLabels: widget.experimentLabels,
                            lockedSteps: widget.lockedSteps,
                            highlightSteps: widget.highlightSteps,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FireflyPainter(
                            phase: _fireflyController.value,
                            totalHeight: totalHeight,
                          ),
                        ),
                      ),
                      ..._stepHitTargets(
                        totalNodes: totalNodes,
                        width: width,
                        segmentHeight: segmentHeight,
                      ),
                      if (_bubbleStep != null)
                        _scoreBubble(
                          trailStep: _bubbleStep!,
                          totalNodes: totalNodes,
                          width: width,
                          segmentHeight: segmentHeight,
                        ),
                      if (widget.ctaStep != null &&
                          widget.ctaLabel != null &&
                          widget.onCtaPressed != null)
                        _besideNodeCta(
                          trailStep: widget.ctaStep!,
                          totalNodes: totalNodes,
                          width: width,
                          segmentHeight: segmentHeight,
                        ),
                      if (widget.tomorrowHintStep != null &&
                          widget.tomorrowHintText != null)
                        _tomorrowHintBubble(
                          trailStep: widget.tomorrowHintStep!,
                          totalNodes: totalNodes,
                          width: width,
                          segmentHeight: segmentHeight,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }

  Widget _besideNodeCta({
    required int trailStep,
    required int totalNodes,
    required double width,
    required double segmentHeight,
  }) {
    final i = totalNodes - trailStep;
    return Positioned(
      left: _nodeX(i, width) - 36,
      top: _nodeY(i, segmentHeight) - 36,
      width: 72,
      height: 72,
      child: Semantics(
        key: ValueKey('trail-start-$trailStep'),
        button: true,
        enabled: widget.ctaEnabled,
        label: widget.ctaLabel,
        child: Tooltip(
            message: widget.ctaLabel ?? '',
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                radius: 36,
                onTap: widget.ctaEnabled ? widget.onCtaPressed : null,
                child: const Center(
                    child: Icon(Icons.play_arrow_rounded,
                        color: Color(0xFF1A2E1A), size: 40)),
              ),
            )),
      ),
    );
  }

  Widget _tomorrowHintBubble({
    required int trailStep,
    required int totalNodes,
    required double width,
    required double segmentHeight,
  }) {
    final i = totalNodes - trailStep;
    final x = _nodeX(i, width);
    final y = _nodeY(i, segmentHeight);
    final nodeOnLeft = x < width * 0.5;
    const gap = 28.0;

    final bubble = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        constraints:
            BoxConstraints(maxWidth: math.min(168, width * 0.6 - gap - 12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF142214).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB8E0C0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.tomorrowHintText!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE8F5D8),
            fontSize: AppType.secondary,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (nodeOnLeft) {
      return Positioned(left: x + gap, top: y - 28, child: bubble);
    }
    return Positioned(right: width - x + gap, top: y - 28, child: bubble);
  }

  Widget _scoreBubble({
    required int trailStep,
    required int totalNodes,
    required double width,
    required double segmentHeight,
  }) {
    final score = widget.sessionScores[trailStep];
    if (score == null) return const SizedBox.shrink();

    final i = totalNodes - trailStep;
    final x = _nodeX(i, width);
    final y = _nodeY(i, segmentHeight);
    final onLeft = x < width * 0.5;
    final t = Curves.easeOutBack.transform(_bubbleController.value);
    final dx = onLeft ? 28.0 * t : -28.0 * t;
    final opacity = t.clamp(0.0, 1.0);
    final label = context.l10n.trailSessionScoreBubble(trailStep, score);

    return Positioned(
      left: onLeft ? x + 18 : null,
      right: onLeft ? null : (width - x + 18),
      top: y - 22,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(dx, -8 * (1 - t)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: width * 0.6 - 60),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E1A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7BBF50), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD4E8B0),
                  fontSize: AppType.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _stepHitTargets({
    required int totalNodes,
    required double width,
    required double segmentHeight,
  }) {
    const hit = 52.0;
    final targets = <Widget>[];
    final qa = widget.onQaEnterStep != null;

    for (var i = 0; i < totalNodes; i++) {
      final trailStep = totalNodes - i;
      if (trailStep < 1 || trailStep > widget.totalSessions) continue;

      final hasScore = widget.sessionScores[trailStep] != null;
      final completedOrCurrent = trailStep <= widget.currentSession;
      final hasKey = widget.nodeKeys.containsKey(trailStep);
      final interactive = qa || (completedOrCurrent && hasScore);

      // Always place anchors for coach keys; only interactive when allowed.
      if (!interactive && !hasKey && trailStep != widget.currentSession + 1)
        continue;

      final x = _nodeX(i, width);
      final y = _nodeY(i, segmentHeight);
      final key = widget.nodeKeys[trailStep];
      targets.add(
        Positioned(
          left: x - hit / 2,
          top: y - hit / 2,
          width: hit,
          height: hit,
          child: KeyedSubtree(
            key: key ?? ValueKey('trail-node-$trailStep'),
            child: interactive
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (qa) {
                        widget.onQaEnterStep!(trailStep);
                      } else {
                        _toggleScoreBubble(trailStep);
                      }
                    },
                    child: qa
                        ? Tooltip(
                            message: 'QA: enter step $trailStep',
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orangeAccent
                                      .withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.expand(),
                  )
                : const SizedBox.expand(),
          ),
        ),
      );
    }
    return targets;
  }
}

// ─────────────────────────────────────────────
// Forest background — static, painted once
// ─────────────────────────────────────────────

class _ForestBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient: near-black at top → deep forest green at bottom
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040C04),
          Color(0xFF091509),
          Color(0xFF0F2010),
          Color(0xFF1A2E1A),
        ],
        stops: [0.0, 0.25, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final rng = math.Random(42);

    // Layer 1 — far trees: tiny, very dark, spaced across full height
    for (int i = 0; i < 22; i++) {
      final double x = rng.nextBool()
          ? rng.nextDouble() * size.width * 0.20
          : size.width * 0.80 + rng.nextDouble() * size.width * 0.20;
      final double y = rng.nextDouble() * size.height;
      _drawTree(canvas, x, y, 0.30 + rng.nextDouble() * 0.20,
          const Color(0xFF0C1A0C), rng);
    }

    // Layer 2 — mid trees: medium size, slightly brighter
    for (int i = 0; i < 22; i++) {
      final double x = rng.nextBool()
          ? rng.nextDouble() * size.width * 0.23
          : size.width * 0.77 + rng.nextDouble() * size.width * 0.23;
      final double y = rng.nextDouble() * size.height;
      _drawTree(canvas, x, y, 0.48 + rng.nextDouble() * 0.30,
          const Color(0xFF183214), rng);
    }

    // Layer 3 — close trees: large, hugging the edges
    for (int i = 0; i < 14; i++) {
      final double x = rng.nextBool()
          ? rng.nextDouble() * size.width * 0.14
          : size.width * 0.86 + rng.nextDouble() * size.width * 0.14;
      final double y = rng.nextDouble() * size.height;
      _drawTree(canvas, x, y, 0.85 + rng.nextDouble() * 0.55,
          const Color(0xFF233D19), rng);
    }

    // Mist bands — soft horizontal glow at a few depths
    _drawMist(canvas, size, 0.20);
    _drawMist(canvas, size, 0.48);
    _drawMist(canvas, size, 0.73);
    _drawMist(canvas, size, 0.91);

    // Forest floor — dark gradient at the very bottom
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF060F06).withOpacity(0.95),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height - 90, size.width, 90));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 90, size.width, 90), floorPaint);
  }

  void _drawMist(Canvas canvas, Size size, double yFrac) {
    final double y = size.height * yFrac;
    final mistPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFF7BA05B).withOpacity(0.055),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 28, size.width, 56));
    canvas.drawRect(Rect.fromLTWH(0, y - 28, size.width, 56), mistPaint);
  }

  void _drawTree(Canvas canvas, double x, double y, double scale,
      Color baseColor, math.Random rng) {
    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(x, y + 6 * scale),
          width: 4 * scale,
          height: 14 * scale),
      Paint()
        ..color = const Color(0xFF120A04)
        ..style = PaintingStyle.fill,
    );

    final double h = 44 * scale;
    final double w = 26 * scale;
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Three layered canopy triangles (bottom to top)
    for (int layer = 0; layer < 3; layer++) {
      final double layerY = y - layer * h * 0.25;
      final double lw = w * (1.0 - layer * 0.10);
      final path = Path()
        ..moveTo(x, layerY - h * (0.38 + layer * 0.06))
        ..lineTo(x - lw * 0.5, layerY + h * 0.13)
        ..lineTo(x + lw * 0.5, layerY + h * 0.13)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Trail path and nodes
// ─────────────────────────────────────────────

class _TrailPainter extends CustomPainter {
  final double topPad;
  final int totalNodes;
  final int currentSession;
  final double segmentHeight;
  final double totalHeight;
  final double pulseValue; // 0.0–1.0 for current-node pulse animation
  final Map<int, int> sessionScores;
  final bool experimentLabels;
  final Set<int> lockedSteps;
  final Set<int> highlightSteps;

  _TrailPainter({
    required this.topPad,
    required this.totalNodes,
    required this.currentSession,
    required this.segmentHeight,
    required this.totalHeight,
    required this.pulseValue,
    required this.sessionScores,
    this.experimentLabels = false,
    this.lockedSteps = const {},
    this.highlightSteps = const {},
  });

  double _nodeX(int index, double width) {
    const double center = 0.5;
    const double offset = 0.10;
    final double shift = (index % 2 == 0) ? -offset : offset;
    return width * (center + shift);
  }

  double _nodeY(int index) => topPad + index * segmentHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Glow pass for completed segments ──
    final glowPaint = Paint()
      ..color = const Color(0xFF5CB83A).withOpacity(0.35)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    for (int i = 0; i < totalNodes - 1; i++) {
      final int fromSession = totalNodes - i;
      final int toSession = totalNodes - (i + 1);
      if (fromSession <= currentSession && toSession <= currentSession) {
        canvas.drawLine(
          Offset(_nodeX(i, size.width), _nodeY(i)),
          Offset(_nodeX(i + 1, size.width), _nodeY(i + 1)),
          glowPaint,
        );
      }
    }

    // ── Dashed path (completed brighter, future dim) ──
    final completedPathPaint = Paint()
      ..color = const Color(0xFF7BBF50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final futurePathPaint = Paint()
      ..color = const Color(0xFF2E4220)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < totalNodes - 1; i++) {
      final int fromSession = totalNodes - i;
      final bool completed = fromSession <= currentSession;
      _drawDashedLine(
        canvas,
        completed ? completedPathPaint : futurePathPaint,
        Offset(_nodeX(i, size.width), _nodeY(i)),
        Offset(_nodeX(i + 1, size.width), _nodeY(i + 1)),
      );
    }

    // ── Nodes (exactly the 10 trail steps; bottom = step 1) ──
    final int nextStep = currentSession < totalNodes ? currentSession + 1 : -1;
    for (int i = 0; i < totalNodes; i++) {
      final Offset pos = Offset(_nodeX(i, size.width), _nodeY(i));
      final int nodeSessionIndex = totalNodes - i;
      final bool isCompleted = nodeSessionIndex <= currentSession;
      final bool isCurrent = nodeSessionIndex == nextStep;
      final bool locked =
          lockedSteps.contains(nodeSessionIndex) && !isCompleted;
      final bool highlight =
          highlightSteps.contains(nodeSessionIndex) || isCurrent;

      _drawNode(
        canvas,
        size.width,
        pos,
        isCompleted,
        isCurrent,
        nodeSessionIndex,
        locked: locked,
        highlight: highlight,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset from, Offset to) {
    const double dashLen = 8;
    const double gapLen = 5;
    final double dx = to.dx - from.dx;
    final double dy = to.dy - from.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double ux = dx / dist;
    final double uy = dy / dist;

    double traveled = 0;
    bool drawing = true;
    while (traveled < dist) {
      final double segEnd =
          math.min(traveled + (drawing ? dashLen : gapLen), dist);
      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + ux * traveled, from.dy + uy * traveled),
          Offset(from.dx + ux * segEnd, from.dy + uy * segEnd),
          paint,
        );
      }
      traveled = segEnd;
      drawing = !drawing;
    }
  }

  void _drawNode(
    Canvas canvas,
    double canvasWidth,
    Offset pos,
    bool isCompleted,
    bool isCurrent,
    int sessionIndex, {
    bool locked = false,
    bool highlight = false,
  }) {
    final double radius = isCurrent && !locked
        ? 32
        : isCurrent || highlight
            ? 24
            : 18;

    // Animated pulse rings for current / coach-highlighted node
    // (including when the next step is still locked for 24h)
    if (highlight) {
      for (int ring = 0; ring < 2; ring++) {
        final double delay = ring * 0.4;
        final double t = ((pulseValue + delay) % 1.0);
        final double pulseRadius = radius + 6 + t * 20;
        final double opacity = (1 - t) * 0.45;
        canvas.drawCircle(
          pos,
          pulseRadius,
          Paint()
            ..color = const Color(0xFF5CB83A).withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // Soft glow behind the node
      canvas.drawCircle(
        pos,
        radius + 10,
        Paint()
          ..color = const Color(0xFF5CB83A).withOpacity(0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Drop shadow
    canvas.drawCircle(
      pos + const Offset(0, 3),
      radius,
      Paint()
        ..color =
            Colors.black.withOpacity(isCurrent || highlight ? 0.45 : 0.25),
    );

    // Fill
    Color fillColor;
    if (locked) {
      fillColor = const Color(0xFF1A2418);
    } else if (isCurrent || highlight) {
      fillColor = const Color(0xFFEAF7C5);
    } else if (isCompleted) {
      fillColor = const Color(0xFF4E9030);
    } else {
      fillColor = const Color(0xFF243520);
    }
    canvas.drawCircle(pos, radius, Paint()..color = fillColor);

    // Border ring
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = locked
            ? (isCurrent || highlight
                ? const Color(0xFF6CC840)
                : const Color(0xFF556B45))
            : isCurrent || highlight
                ? const Color(0xFF6CC840)
                : isCompleted
                    ? const Color(0xFF7BBF50)
                    : const Color(0xFF344F24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent || highlight ? 3.0 : 1.5,
    );

    // Content — locks on all not-yet-open steps (including glowing next)
    if (locked) {
      final lockPaint = Paint()
        ..color = const Color(0xFF9BB07A)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
          Rect.fromCenter(
              center: pos + const Offset(0, -4), width: 10, height: 12),
          math.pi,
          math.pi,
          false,
          lockPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: pos + const Offset(0, 3), width: 16, height: 12),
              const Radius.circular(2)),
          lockPaint);
      canvas.drawLine(
          pos + const Offset(0, 1), pos + const Offset(0, 5), lockPaint);
    } else if (isCompleted && !isCurrent) {
      _drawCheckmark(canvas, pos, radius);
    } else if (!isCurrent) {
      _drawText(
        canvas,
        pos,
        _nodeLabel(sessionIndex),
        isCurrent || highlight
            ? const Color(0xFF1A2E1A)
            : const Color(0xFF4A6A35),
        isCurrent || highlight ? 14 : 11,
        isCurrent || highlight ? FontWeight.w700 : FontWeight.w500,
      );
    }
  }

  String _nodeLabel(int sessionIndex) => '$sessionIndex';

  void _drawCheckmark(Canvas canvas, Offset pos, double radius) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double r = radius * 0.45;
    final path = Path()
      ..moveTo(pos.dx - r * 0.9, pos.dy)
      ..lineTo(pos.dx - r * 0.15, pos.dy + r * 0.75)
      ..lineTo(pos.dx + r, pos.dy - r * 0.65);
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, Offset pos, String text, Color color,
      double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.topPad != topPad ||
      old.totalHeight != totalHeight ||
      old.currentSession != currentSession ||
      old.pulseValue != pulseValue ||
      old.sessionScores != sessionScores ||
      old.experimentLabels != experimentLabels ||
      old.lockedSteps != lockedSteps ||
      old.highlightSteps != highlightSteps;
}

// ─────────────────────────────────────────────
// Fireflies — animated floating glowing dots
// ─────────────────────────────────────────────

class _FireflyPainter extends CustomPainter {
  final double phase; // 0.0–1.0, repeating
  final double totalHeight;

  _FireflyPainter({required this.phase, required this.totalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);

    for (int i = 0; i < 18; i++) {
      // Each firefly has a fixed base position and unique phase offset
      final double baseXFrac = 0.22 + rng.nextDouble() * 0.56;
      final double baseYFrac = rng.nextDouble();
      final double phaseOffset = rng.nextDouble() * 2 * math.pi;
      final double speedMult = 0.4 + rng.nextDouble() * 0.9;
      final double driftRadius = 10 + rng.nextDouble() * 16;

      final double t = phase * 2 * math.pi * speedMult + phaseOffset;
      final double x = size.width * baseXFrac + driftRadius * math.sin(t);
      final double y =
          size.height * baseYFrac + driftRadius * math.cos(t * 0.65 + 1.1);

      // Brightness pulses independently
      final double brightness = (math.sin(t * 1.4 + phaseOffset * 0.7) + 1) / 2;
      if (brightness < 0.08) continue;

      final double dotRadius = 1.2 + brightness * 2.0;
      final double opacity = 0.12 + brightness * 0.60;

      // Soft outer glow
      canvas.drawCircle(
        Offset(x, y),
        dotRadius + 4,
        Paint()
          ..color = const Color(0xFFCCFF66).withOpacity(opacity * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Bright core
      canvas.drawCircle(
        Offset(x, y),
        dotRadius,
        Paint()..color = const Color(0xFFEEFF99).withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter old) => old.phase != phase;
}

// ─────────────────────────────────────────────
// Home widget — persists progress across launches
// ─────────────────────────────────────────────

class ForestTrailHome extends StatefulWidget {
  /// When true, trail is hosted under the prep shell (no back-to-menu).
  final bool embedded;
  final Widget Function(bool highlightTiming)? bottomBarBuilder;
  final GlobalKey? timingIconKey;

  const ForestTrailHome({
    Key? key,
    this.embedded = false,
    this.bottomBarBuilder,
    this.timingIconKey,
  }) : super(key: key);

  @override
  State<ForestTrailHome> createState() => _ForestTrailHomeState();
}

class _ForestTrailHomeState extends State<ForestTrailHome> {
  static const _scoresKey = 'experiment_trail_scores_v1';
  static const int _totalSteps = 10;

  Map<int, int> _sessionScores = {};
  Map<int, DateTime> _completedAt = {};
  bool _loading = true;
  bool _busy = false;

  /// 0 = inactive, 1..3 = coach bubble index.
  int _coachIndex = 0;
  int? _tomorrowHintStep;
  Timer? _tomorrowHintTimer;

  final GlobalKey _step1Key = GlobalKey();
  final GlobalKey _step2Key = GlobalKey();
  final GlobalKey _mapKey = GlobalKey();

  ExperimentProgress? get _progress => ExperimentStore.instance.progress;

  @override
  void initState() {
    super.initState();
    ExperimentStore.instance.addListener(_onStoreChanged);
    QaOverrides.instance.addListener(_onStoreChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _tomorrowHintTimer?.cancel();
    ExperimentStore.instance.removeListener(_onStoreChanged);
    QaOverrides.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await QaOverrides.instance.load();
    await ExperimentStore.instance.loadCached();
    await _loadLocalScores();
    _completedAt = await TrailUnlockStore.instance.loadCompletedAt();
    final coachDone = await TrailCoachStore.instance.isDone();
    if (mounted) {
      setState(() {
        _loading = false;
        if (!coachDone) _coachIndex = 1;
      });
    }
    await ExperimentStore.instance.bootstrap();
    if (mounted) setState(() {});
  }

  Future<void> _loadLocalScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionScores = _decodeScores(prefs.getString(_scoresKey));
    });
  }

  Map<int, int> _decodeScores(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveTrailStepScore(int trailStep, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = Map<int, int>.from(_sessionScores)..[trailStep] = score;
    final encoded = jsonEncode(
      updated.map((key, value) => MapEntry(key.toString(), value)),
    );
    await prefs.setString(_scoresKey, encoded);
    if (mounted) setState(() => _sessionScores = updated);
  }

  String _effectiveTrainingMode(ExperimentProgress progress) {
    return QaOverrides.instance.effectiveTrainingMode(progress.trainingMode);
  }

  Future<void> _markStepDoneLocally(int step) async {
    await TrailUnlockStore.instance.markStepCompleted(step);
    _completedAt = await TrailUnlockStore.instance.loadCompletedAt();
    if (mounted) setState(() {});
    _maybeShowTomorrowHint(step);
  }

  void _maybeShowTomorrowHint(int finishedStep) {
    final next = finishedStep + 1;
    if (next > 10) return;
    if (_isUnlocked(next)) return;
    _tomorrowHintTimer?.cancel();
    setState(() => _tomorrowHintStep = next);
    _tomorrowHintTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _tomorrowHintStep = null);
    });
  }

  bool _isUnlocked(int step) {
    final completed = _progress?.completedTrailSteps ?? 0;
    return TrailUnlockStore.instance.isStepUnlocked(
      step,
      completedAt: _completedAt,
      completedTrailSteps: completed,
      qaBypass: qaSkipEnabled,
    );
  }

  Future<void> _runTrailStep(int step) async {
    if (_busy) return;
    if (_coachIndex > 0) return;
    final progress = _progress;
    if (progress == null) return;
    if (!_isUnlocked(step)) {
      final left = TrailUnlockStore.instance.remainingUntilUnlock(
        step,
        completedAt: _completedAt,
      );
      if (mounted && left != null) {
        final hours = left.inHours;
        final mins = left.inMinutes % 60;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.trailStepLockedHours(hours, mins)),
          ),
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      if (isPreTrailStep(step)) {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const AssessmentScreen(phase: 'pre'),
          ),
        );
        if (saved == true) {
          await _markStepDoneLocally(step);
          await ExperimentStore.instance.refresh();
        }
        return;
      }

      if (isPostTrailStep(step)) {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const AssessmentScreen(phase: 'post'),
          ),
        );
        if (saved == true) {
          await _markStepDoneLocally(step);
          await ExperimentStore.instance.refresh();
        }
        return;
      }

      final sessionNumber = trainingSessionForTrailStep(step);
      if (sessionNumber == null) return;

      final useAudio = _effectiveTrainingMode(progress) == 'audio';
      final sessionResult = await Navigator.push<ProtocolSessionResult>(
        context,
        MaterialPageRoute(
          builder: (_) => useAudio
              ? ControlProtocolFlowScreen(
                  returnScoreToCaller: true,
                  sessionNumber: sessionNumber,
                )
              : ProtocolFlowScreen(
                  returnScoreToCaller: true,
                  sessionNumber: sessionNumber,
                ),
        ),
      );
      if (!mounted || sessionResult == null) return;

      await _saveTrailStepScore(step, sessionResult.score);
      await _markStepDoneLocally(step);
      final remote = await ExperimentStore.instance.saveTrainingSession(
        sessionNumber: sessionNumber,
        score: sessionResult.score,
        avgHeartRate: sessionResult.avgHeartRate,
        durationSeconds: sessionResult.durationSeconds,
      );
      if (remote == null && mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.experimentSessionSaveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startNextStep() async {
    final progress = _progress;
    if (progress == null || progress.isCompleted) return;
    await _runTrailStep(progress.trailStep.clamp(1, 10));
  }

  Future<void> _advanceCoach() async {
    if (_coachIndex >= 3) {
      await TrailCoachStore.instance.markDone();
      if (mounted) setState(() => _coachIndex = 0);
      return;
    }
    setState(() => _coachIndex += 1);
  }

  Future<void> _onQaTrailStepTap(int trailStep) async {
    if (!qaSkipEnabled || _busy) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E1A),
        title: Text(
          'QA: enter step $trailStep?',
          style: const TextStyle(color: Color(0xFFD4E8B0)),
        ),
        content: const Text(
          'Opens this step for testing even if it is not next on the trail. '
          'May replace or discard previous data for this step.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Enter',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
    if (go == true) await _runTrailStep(trailStep);
  }

  String _footerLabel(AppLocalizations l10n, ExperimentProgress? progress) {
    if (progress == null || progress.isCompleted) return l10n.allDone;
    return l10n.startSession;
  }

  String _qaModeLabel(ExperimentProgress? progress) {
    if (progress == null) return '';
    final override = QaOverrides.instance.trainingModeOverride;
    final effective = _effectiveTrainingMode(progress);
    final arm = effective == 'audio' ? 'control (audio)' : 'regular (ppg)';
    if (override == null) return 'QA arm: $arm · server';
    return 'QA arm: $arm · forced';
  }

  List<PopupMenuEntry<VoidCallback>> _qaModeMenuEntries() {
    return [
      qaSkipItem(
        'Use server assignment',
        () => QaOverrides.instance.setTrainingModeOverride(null),
      ),
      qaSkipItem(
        'Force regular (PPG)',
        () => QaOverrides.instance.setTrainingModeOverride('ppg'),
      ),
      qaSkipItem(
        'Force control (audio)',
        () => QaOverrides.instance.setTrainingModeOverride('audio'),
      ),
    ];
  }

  Set<int> _coachHighlightSteps() {
    return switch (_coachIndex) {
      1 => {1},
      2 => {2},
      _ => {},
    };
  }

  GlobalKey? _coachTargetKey() {
    return switch (_coachIndex) {
      1 => _step1Key,
      2 => _step2Key,
      3 => widget.timingIconKey,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF5C9E3A))),
      );
    }

    final progress = _progress;
    final completed = progress?.completedTrailSteps ?? 0;
    final bool isFinished = progress?.isCompleted == true;
    final l10n = context.l10n;
    final nextStep = isFinished ? -1 : (completed + 1).clamp(1, 10);
    final locked = <int>{};
    for (var s = 1; s <= 10; s++) {
      if (!_isUnlocked(s) && s > completed) locked.add(s);
    }
    final nextLocked = nextStep > 0 && locked.contains(nextStep);
    final highlightTiming = _coachIndex == 3;
    final bottomBar = widget.bottomBarBuilder?.call(highlightTiming);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Black upper chrome: status bar + header as one stripe
              ColoredBox(
                color: Colors.black,
                child: SafeArea(
                  bottom: false,
                  child: AbsorbPointer(
                    absorbing: _coachIndex > 0,
                    child: _buildHeader(
                      isFinished,
                      completed,
                      l10n,
                      progress,
                    ),
                  ),
                ),
              ),
              // Green map only — CTA sits beside the current trail node
              Expanded(
                child: ColoredBox(
                  key: _mapKey,
                  color: const Color(0xFF0A1A0A),
                  child: AbsorbPointer(
                    absorbing: _coachIndex > 0,
                    child: TrailMap(
                      currentSession: completed,
                      totalSessions: _totalSteps,
                      sessionScores: _sessionScores,
                      experimentLabels: false,
                      lockedSteps: locked,
                      highlightSteps: {
                        ..._coachHighlightSteps(),
                        if (_tomorrowHintStep != null) _tomorrowHintStep!,
                      },
                      nodeKeys: {
                        1: _step1Key,
                        2: _step2Key,
                      },
                      ctaStep: (!isFinished &&
                              nextStep > 0 &&
                              !nextLocked &&
                              _tomorrowHintStep == null)
                          ? nextStep
                          : null,
                      ctaLabel: progress == null
                          ? l10n.tryAgain
                          : _busy
                              ? l10n.saving
                              : _footerLabel(l10n, progress),
                      ctaEnabled: !_busy && progress != null,
                      onCtaPressed: _onPrimaryPressed,
                      tomorrowHintStep: _tomorrowHintStep,
                      tomorrowHintText: _tomorrowHintStep != null
                          ? l10n.trailOpensTomorrow
                          : null,
                      onQaEnterStep: qaSkipEnabled ? _onQaTrailStepTap : null,
                    ),
                  ),
                ),
              ),
              // Black bottom chrome — menu only
              if (bottomBar != null)
                AbsorbPointer(
                  absorbing: _coachIndex > 0,
                  child: bottomBar,
                ),
            ],
          ),
          if (_coachIndex > 0) _buildCoachOverlay(l10n),
        ],
      ),
    );
  }

  Widget _buildCoachOverlay(AppLocalizations l10n) {
    final text = switch (_coachIndex) {
      1 => l10n.trailCoachBubble1,
      2 => l10n.trailCoachBubble2,
      _ => l10n.trailCoachBubble3,
    };
    final targetKey = _coachTargetKey();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          _CoachAnchoredBubble(
            targetKey: targetKey,
            text: text,
            buttonLabel: _coachIndex >= 3 ? l10n.finish : l10n.nextAction,
            onNext: _advanceCoach,
            preferAbove: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isFinished,
    int completed,
    AppLocalizations l10n,
    ExperimentProgress? progress,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embedded)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF7BA05B)),
                  tooltip: l10n.backToMenu,
                  onPressed: () => Navigator.pop(context),
                ),
              Expanded(
                child: Text(
                  isFinished ? l10n.youReachedTheEnd : l10n.yourJourney,
                  style: const TextStyle(
                    color: Color(0xFFD4E8B0),
                    fontSize: AppType.title,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (qaSkipEnabled)
                QaSkipMenuButton(entries: _qaModeMenuEntries()),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: widget.embedded ? 8 : 48),
            child: Text(
              isFinished
                  ? l10n.allSessionsCompleted(_totalSteps)
                  : l10n.experimentStepsDone(completed, _totalSteps),
              style: const TextStyle(
                color: Color(0xFF7BA05B),
                fontSize: AppType.secondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (qaSkipEnabled) ...[
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: widget.embedded ? 8 : 48),
              child: Text(
                _qaModeLabel(progress),
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: AppType.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onPrimaryPressed() async {
    if (_busy) return;
    if (_progress == null) {
      setState(() => _busy = true);
      try {
        await ExperimentStore.instance.bootstrap();
        if (_progress == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.experimentBootstrapFailed)),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    await _startNextStep();
  }
}

/// Speech bubble anchored above/below a [GlobalKey] target, with a thin
/// outline and a pointer toward the highlighted object.
class _CoachAnchoredBubble extends StatefulWidget {
  final GlobalKey? targetKey;
  final String text;
  final String buttonLabel;
  final VoidCallback onNext;
  final bool preferAbove;

  const _CoachAnchoredBubble({
    required this.targetKey,
    required this.text,
    required this.buttonLabel,
    required this.onNext,
    this.preferAbove = true,
  });

  @override
  State<_CoachAnchoredBubble> createState() => _CoachAnchoredBubbleState();
}

class _CoachAnchoredBubbleState extends State<_CoachAnchoredBubble> {
  Offset? _anchor;
  Size? _targetSize;
  bool _placeAbove = true;
  final _bubbleKey = GlobalKey();
  double _bubbleHeight = 170;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _CoachAnchoredBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey ||
        oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted) return;
    final bubbleBox =
        _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (bubbleBox != null && bubbleBox.hasSize)
      _bubbleHeight = bubbleBox.size.height;
    final key = widget.targetKey;
    final ctx = key?.currentContext;
    if (ctx == null) {
      setState(() {
        _anchor = null;
        _targetSize = null;
        _placeAbove = widget.preferAbove;
      });
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    final stackBox = context.findRenderObject() as RenderBox?;
    if (box == null || stackBox == null || !box.hasSize || !stackBox.hasSize) {
      return;
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: stackBox);
    final size = box.size;
    final center = topLeft + Offset(size.width / 2, size.height / 2);
    setState(() {
      _anchor = center;
      _targetSize = size;
      _placeAbove = widget.preferAbove;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final anchor = _anchor ?? Offset(size.width / 2, size.height * 0.35);
    final targetSize = _targetSize ?? const Size(48, 48);
    final placeAbove = _placeAbove;

    final bubbleMaxW = math.min(300.0, size.width - 32);
    final bubbleMaxH = math.min(320.0, size.height - 64);
    final bubble = Container(
      key: _bubbleKey,
      constraints: BoxConstraints(maxWidth: bubbleMaxW, maxHeight: bubbleMaxH),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF142214),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8E0C0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: SingleChildScrollView(
                  child: Text(
            widget.text,
            style: const TextStyle(
              color: Color(0xFFE8F5D8),
              fontSize: AppType.secondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onNext,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: const Color(0xFF5C9E3A),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              widget.buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // Soft glow ring around the pointed target
    final glowLeft = anchor.dx - targetSize.width / 2 - 10;
    final glowTop = anchor.dy - targetSize.height / 2 - 10;

    return Stack(
      children: [
        Positioned(
          left: glowLeft.clamp(0, size.width - targetSize.width - 20),
          top: glowTop.clamp(0, size.height - targetSize.height - 20),
          child: IgnorePointer(
            child: Container(
              width: targetSize.width + 20,
              height: targetSize.height + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7CFF9A).withValues(alpha: 0.55),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: (anchor.dx - bubbleMaxW / 2)
              .clamp(16, size.width - bubbleMaxW - 16),
          top: placeAbove
              ? (anchor.dy - targetSize.height / 2 - _bubbleHeight - 18)
                  .clamp(16, size.height - _bubbleHeight - 32)
              : (anchor.dy + targetSize.height / 2 + 18)
                  .clamp(16, size.height - _bubbleHeight - 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!placeAbove)
                CustomPaint(
                  size: const Size(18, 10),
                  painter: _BubblePointerPainter(pointUp: true),
                ),
              bubble,
              if (placeAbove)
                CustomPaint(
                  size: const Size(18, 10),
                  painter: _BubblePointerPainter(pointUp: false),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BubblePointerPainter extends CustomPainter {
  final bool pointUp;

  _BubblePointerPainter({required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    final fill = Paint()..color = const Color(0xFF142214);
    final stroke = Paint()
      ..color = const Color(0xFFB8E0C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BubblePointerPainter old) =>
      old.pointUp != pointUp;
}
