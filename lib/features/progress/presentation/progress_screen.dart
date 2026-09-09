import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_user.dart';
import '../domain/topic_progress.dart';
import '../providers/topic_progress_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(topicProgressProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Study progress')),
      body: progress.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () {
              ref.invalidate(topicProgressProvider(user.id));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry progress'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyProgress();
          }

          final reviewed = items.fold<int>(
            0,
            (total, item) => total + item.summary.reviewedCount,
          );

          final understood = items.fold<int>(
            0,
            (total, item) => total + item.summary.understoodCount,
          );

          final needsReview = items.fold<int>(
            0,
            (total, item) => total + item.summary.needsReviewCount,
          );

          final attempts = items.fold<int>(
            0,
            (total, item) => total + item.summary.reviewAttemptCount,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(topicProgressProvider(user.id));

              await ref.read(topicProgressProvider(user.id).future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ProgressSummary(
                    reviewed: reviewed,
                    understood: understood,
                    needsReview: needsReview,
                    attempts: attempts,
                  );
                }

                return _TopicProgressCard(progress: items[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.reviewed,
    required this.understood,
    required this.needsReview,
    required this.attempts,
  });

  final int reviewed;
  final int understood;
  final int needsReview;
  final int attempts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _Metric(value: reviewed, label: 'Reviewed'),
                _Metric(value: understood, label: 'Understood'),
                _Metric(value: needsReview, label: 'Needs review'),
                _Metric(value: attempts, label: 'Attempts'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class _TopicProgressCard extends StatelessWidget {
  const _TopicProgressCard({required this.progress});

  final TopicProgress progress;

  @override
  Widget build(BuildContext context) {
    final topic = progress.topic;
    final summary = progress.summary;
    final percentage = (progress.reviewCoverage * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              topic.subjectName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress.reviewCoverage),
            const SizedBox(height: 8),
            Text(
              '${summary.reviewedCount} of '
              '${progress.totalQuestionCount} questions '
              'reviewed ($percentage%)',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('${summary.understoodCount} understood'),
                ),
                Chip(
                  avatar: const Icon(Icons.replay_outlined, size: 18),
                  label: Text('${summary.needsReviewCount} need review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 56),
            SizedBox(height: 16),
            Text('No study progress yet.', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Reveal a memo and record whether you '
              'understood the question.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
