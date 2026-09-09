import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../progress/domain/topic_progress.dart';
import '../../data/models/topic.dart';

const _mathematicsIconPath = 'assets/icons/mathematics_icons';
const _physicalSciencesIconPath =
    'assets/icons/physical_sciences_icons/physical_sciences_icons';

String? topicIconAsset(String slug) {
  return switch (slug) {
    'finance-growth-and-decay' =>
      '$_mathematicsIconPath/finance-growth-and-decay.svg',
    'algebra-equations-and-inequalities' =>
      '$_mathematicsIconPath/algebra-equations-and-inequalities.svg',
    'differential-calculus' =>
      '$_mathematicsIconPath/differential-calculus.svg',
    'statistics-and-regression' =>
      '$_mathematicsIconPath/statistics-and-regression.svg',
    'number-patterns' => '$_mathematicsIconPath/number-patterns.svg',
    'trigonometry' => '$_mathematicsIconPath/trigonometry.svg',
    'counting-principle-and-probability' =>
      '$_mathematicsIconPath/counting-principle-and-probability.svg',
    'euclidean-geometry' => '$_mathematicsIconPath/euclidean-geometry.svg',
    'analytical-geometry' => '$_mathematicsIconPath/analytical-geometry.svg',
    'functions-and-graphs' =>
      '$_mathematicsIconPath/functions-and-graphs.svg',
    'newtons-laws' => '$_physicalSciencesIconPath/newtons-laws.svg',
    'momentum-and-impulse' =>
      '$_physicalSciencesIconPath/momentum-and-impulse.svg',
    'vertical-projectile-motion' =>
      '$_physicalSciencesIconPath/vertical-projectile-motion.svg',
    'work-energy-and-power' =>
      '$_physicalSciencesIconPath/work-energy-and-power.svg',
    'doppler-effect' => '$_physicalSciencesIconPath/doppler-effect.svg',
    'electrostatics' => '$_physicalSciencesIconPath/electrostatics.svg',
    'electric-circuits' =>
      '$_physicalSciencesIconPath/electric-circuits.svg',
    'electrodynamics' => '$_physicalSciencesIconPath/electrodynamics.svg',
    'optical-phenomena' =>
      '$_physicalSciencesIconPath/optical-phenomena.svg',
    'organic-molecules' =>
      '$_physicalSciencesIconPath/organic-molecules.svg',
    'intermolecular-forces' =>
      '$_physicalSciencesIconPath/intermolecular-forces.svg',
    'rate-and-extent-of-reaction' =>
      '$_physicalSciencesIconPath/rate-and-extent-of-reaction.svg',
    'chemical-equilibrium' =>
      '$_physicalSciencesIconPath/chemical-equilibrium.svg',
    'acids-and-bases' =>
      '$_physicalSciencesIconPath/acids-and-bases.svg',
    'electrochemical-reactions' =>
      '$_physicalSciencesIconPath/electrochemical-reactions.svg',
    _ => null,
  };
}

class TopicGridCard extends StatelessWidget {
  const TopicGridCard({
    required this.topic,
    required this.onTap,
    this.progress,
    super.key,
  });

  final Topic topic;
  final TopicProgress? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable = topic.questionCount > 0;
    final iconAsset = topicIconAsset(topic.slug);
    final questionLabel = topic.questionCount == 1
        ? '1 question'
        : '${topic.questionCount} questions';

    return Semantics(
      button: isAvailable,
      enabled: isAvailable,
      label: isAvailable
          ? '${topic.name}, $questionLabel'
          : '${topic.name}, coming soon',
      child: Card(
        color: AppColors.neutralCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAvailable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.iconTile,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: iconAsset == null
                      ? const Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.topicIcon,
                          size: 25,
                        )
                      : SvgPicture.asset(
                          iconAsset,
                          colorFilter: const ColorFilter.mode(
                            AppColors.topicIcon,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      topic.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isAvailable ? AppColors.ink : AppColors.mutedInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAvailable ? questionLabel : 'Coming soon',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAvailable && progress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${progress!.summary.reviewedCount} reviewed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: progress!.reviewCoverage,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
