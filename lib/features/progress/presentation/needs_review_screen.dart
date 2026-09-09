import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:past_question_paper_v1/features/progress/presentation/needs_review_detail_screen.dart';
import '../../auth/domain/app_user.dart';
import '../../questions/data/models/question.dart';
import '../providers/needs_review_questions_provider.dart';

class NeedsReviewScreen extends ConsumerWidget {
  const NeedsReviewScreen({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(needsReviewQuestionsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Needs review')),
      body: questions.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () {
              ref.invalidate(needsReviewQuestionsProvider(user.id));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry questions'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyNeedsReview();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(needsReviewQuestionsProvider(user.id));

              await ref.read(needsReviewQuestionsProvider(user.id).future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final question = items[index];

                return Card(
                  child: ListTile(
                    onTap: () => _openQuestion(context, ref, question),
                    leading: const Icon(Icons.replay_outlined),
                    title: Text(
                      '${question.topicName} '
                      '— Question ${question.questionNumber}',
                    ),
                    subtitle: Text(
                      '${question.examYear} • '
                      '${question.examSeason} • '
                      'Paper ${question.paperNumber}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openQuestion(
    BuildContext context,
    WidgetRef ref,
    Question question,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NeedsReviewDetailScreen(user: user, question: question),
      ),
    );

    ref.invalidate(needsReviewQuestionsProvider(user.id));
  }
}

class _EmptyNeedsReview extends StatelessWidget {
  const _EmptyNeedsReview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 56),
            SizedBox(height: 16),
            Text('Nothing needs review.', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Questions you mark as needing review '
              'will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
