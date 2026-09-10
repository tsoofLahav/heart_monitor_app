import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/pulse_guide_assets.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_colors.dart';

/// Single illustrated step with optional caption lines.
class PulseGuideStepImage extends StatelessWidget {
  final String assetPath;
  final List<String> captionLines;
  final double maxHeight;

  const PulseGuideStepImage({
    super.key,
    required this.assetPath,
    this.captionLines = const [],
    this.maxHeight = 340,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: brightenGuideImage(
            Image.asset(
              assetPath,
              fit: BoxFit.contain,
              width: double.infinity,
              height: maxHeight,
            ),
          ),
        ),
        if (captionLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...captionLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppType.body,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

enum PulseGuideInstructionsFinale { practiceOffer, comics }

/// Swipeable instruction walkthrough (steps 1–4), then finale page.
class PulseGuideInstructionsPager extends StatefulWidget {
  final VoidCallback onFinished;
  final VoidCallback? onPracticeOfferReached;
  final PulseGuideInstructionsFinale finale;

  const PulseGuideInstructionsPager({
    super.key,
    required this.onFinished,
    this.onPracticeOfferReached,
    this.finale = PulseGuideInstructionsFinale.practiceOffer,
  });

  @override
  State<PulseGuideInstructionsPager> createState() =>
      _PulseGuideInstructionsPagerState();
}

class _PulseGuideInstructionsPagerState
    extends State<PulseGuideInstructionsPager> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  int get _pageCount => PulseGuideAssets.instructionSteps.length + 1;

  int get _finalePageIndex => PulseGuideAssets.instructionSteps.length;

  bool get _onFinalePage => _pageIndex == _finalePageIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _pageIndex = index);
    if (index == _finalePageIndex) {
      widget.onPracticeOfferReached?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final captions = PulseGuideAssets.instructionCaptionLines(l10n);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              if (index == _finalePageIndex) {
                return ProtocolCenteredScrollBody(
                  child: widget.finale == PulseGuideInstructionsFinale.comics
                      ? _buildComicsPage(l10n)
                      : _buildPracticeOfferPage(l10n),
                );
              }
              return ProtocolCenteredScrollBody(
                child: PulseGuideStepImage(
                  assetPath: PulseGuideAssets.instructionSteps[index],
                  captionLines: captions[index],
                ),
              );
            },
          ),
        ),
        AppActionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_onFinalePage) ...[
                ProtocolPrimaryButton(
                  label: widget.finale ==
                          PulseGuideInstructionsFinale.practiceOffer
                      ? l10n.startPractice
                      : l10n.done,
                  onPressed: widget.onFinished,
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _pageIndex ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _pageIndex ? AppColors.accent : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeOfferPage(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.fingerprint, color: AppColors.accent, size: 72),
        const SizedBox(height: 28),
        Text(
          l10n.readyForQualityPractice,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppType.body,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.nextYoullTakeShortReadings,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: AppType.body,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComicsPage(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.pulseGuideComicsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppType.title,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: PulseGuideAssets.instructionSteps.length,
          itemBuilder: (context, i) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: brightenGuideImage(Image.asset(
              PulseGuideAssets.instructionSteps[i],
              fit: BoxFit.contain,
            )),
          ),
        ),
      ],
    );
  }
}
