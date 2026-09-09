import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_user.dart';
import '../../questions/data/models/question.dart';
import '../providers/saved_questions_provider.dart';
import 'saved_question_detail_screen.dart';

class SavedQuestionsScreen extends ConsumerWidget {
  const SavedQuestionsScreen({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(savedQuestionsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Saved questions')),
      body: questions.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stackTrace) => _SavedError(
          onRetry: () {
            ref.invalidate(savedQuestionsProvider(user.id));
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptySavedQuestions();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savedQuestionsProvider(user.id));

              await ref.read(savedQuestionsProvider(user.id).future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SavedQuestionTile(
                  question: items[index],
                  onTap: () => _openQuestion(context, ref, items[index]),
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
        builder: (_) =>
            SavedQuestionDetailScreen(user: user, question: question),
      ),
    );

    ref.invalidate(savedQuestionsProvider(user.id));
  }
}

class _SavedQuestionTile extends StatelessWidget {
  const _SavedQuestionTile({required this.question, required this.onTap});

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.bookmark),
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
  }
}

class _EmptySavedQuestions extends StatelessWidget {
  const _EmptySavedQuestions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 56),
            SizedBox(height: 16),
            Text('No saved questions yet.', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Bookmark a question while studying '
              'and it will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedError extends StatelessWidget {
  const _SavedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry saved questions'),
      ),
    );
  }
}
