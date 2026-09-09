import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';

class PastPaperHero extends StatelessWidget {
  const PastPaperHero({
    required this.learnerName,
    required this.progress,
    required this.reviewedQuestions,
    required this.totalQuestions,
    required this.onInfoPressed,
    required this.onAccountPressed,
    required this.isSignedIn,
    super.key,
  });

  static const _assetPath = 'assets/branding/Hero SVG Base — Static.svg';
  static const _aspectRatio = 424 / 474;
  static const _visibleCardWidthRatio = 380 / 424;

  final String? learnerName;
  final double? progress;
  final int? reviewedQuestions;
  final int? totalQuestions;
  final VoidCallback onInfoPressed;
  final VoidCallback? onAccountPressed;
  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The SVG viewBox includes 22 logical pixels of whitespace on both
        // sides. Compensate so its visible 380px paper fills the content width.
        final heroWidth = constraints.maxWidth / _visibleCardWidthRatio;
        final heroHeight = heroWidth / _aspectRatio;

        return SizedBox(
          height: heroHeight,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: heroWidth,
            maxWidth: heroWidth,
            minHeight: heroHeight,
            maxHeight: heroHeight,
            child: SizedBox(
              width: heroWidth,
              height: heroHeight,
              child: Stack(
                children: [
                  // Match the shadow to the visible paper, excluding SVG margins.
                  Positioned(
                    left: heroWidth * 22 / 424,
                    top: heroHeight * 15 / 474,
                    width: heroWidth * 380 / 424,
                    height: heroHeight * 430 / 474,
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(heroWidth * 20 / 424),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned.fill(
                    child: SvgPicture.asset(
                      _assetPath,
                      fit: BoxFit.contain,
                      semanticsLabel: 'Past Papers learner progress card',
                    ),
                  ),
                  Positioned(
                    left: heroWidth * 0.265,
                    top: heroHeight * 0.63,
                    width: heroWidth * 0.47,
                    height: heroHeight * 0.075,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: heroWidth * 0.12,
                    top: heroHeight * 0.78,
                    width: heroWidth * 0.76,
                    height: heroHeight * 0.15,
                    child: _ProgressOverlay(
                      progress: progress,
                      reviewedQuestions: reviewedQuestions,
                      totalQuestions: totalQuestions,
                    ),
                  ),
                  Positioned(
                    left: heroWidth * 0.7,
                    top: heroHeight * 0.045,
                    width: heroWidth * 0.2,
                    height: heroWidth * 0.1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeroActionButton(
                          tooltip: 'Legal and privacy',
                          icon: Icons.info_outline,
                          onPressed: onInfoPressed,
                        ),
                        _HeroActionButton(
                          tooltip: isSignedIn ? 'Account' : 'Sign in',
                          icon: isSignedIn
                              ? Icons.account_circle
                              : Icons.person_outline,
                          onPressed: onAccountPressed,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _displayName {
    final name = learnerName?.trim();
    return name == null || name.isEmpty ? 'Learner' : name;
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 21,
        color: AppColors.ink,
        icon: Icon(icon),
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay({
    required this.progress,
    required this.reviewedQuestions,
    required this.totalQuestions,
  });

  final double? progress;
  final int? reviewedQuestions;
  final int? totalQuestions;

  @override
  Widget build(BuildContext context) {
    final value = progress?.clamp(0.0, 1.0).toDouble();
    final hasProgressData =
        value != null && reviewedQuestions != null && totalQuestions != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!hasProgressData) {
          return Padding(
            padding: EdgeInsets.only(
              left: constraints.maxWidth * 0.33,
              top: constraints.maxHeight * 0.4,
            ),
            child: const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Sign in to track your progress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final percentage = (value * 100).round();

        return Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * 0.14,
              top: constraints.maxHeight * 0.27,
              width: constraints.maxWidth * 0.18,
              height: constraints.maxHeight * 0.37,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$percentage%',
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.33,
              top: constraints.maxHeight * 0.43,
              width: constraints.maxWidth * 0.65,
              height: constraints.maxHeight * 0.54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$reviewedQuestions of $totalQuestions questions reviewed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.success,
                    backgroundColor: AppColors.softGreen,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
