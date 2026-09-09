import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:past_question_paper_v1/features/questions/presentation/question_filter_dialog.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../comments/presentation/widgets/question_discussion_button.dart';
import '../../discovery/data/models/topic.dart';
import '../../progress/domain/question_progress.dart';
import '../../progress/presentation/widgets/question_reflection_card.dart';
import '../../progress/providers/needs_review_questions_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../progress/providers/topic_progress_provider.dart';
import '../data/models/question.dart';
import '../domain/question_query.dart';
import '../providers/question_providers.dart';
import 'widgets/question_bookmark_button.dart';
import 'widgets/question_content_card.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({required this.topic, super.key});

  final Topic topic;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  int _currentIndex = 0;
  bool _showMemo = false;
  late QuestionQuery _query;

  @override
  void initState() {
    super.initState();

    _query = QuestionQuery(topicId: widget.topic.id);
  }

  Future<void> _openFilters() async {
    final result = await showQuestionFilterDialog(
      context: context,
      currentQuery: _query,
    );

    if (result == null || result == _query || !mounted) {
      return;
    }

    setState(() {
      _query = result;
      _currentIndex = 0;
      _showMemo = false;
    });
  }

  Future<void> _recordProgress({
    required AppUser? user,
    required String questionId,
    required QuestionProgressStatus status,
  }) async {
    if (user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));

      return;
    }

    final provider = questionProgressControllerProvider(questionId);

    await ref.read(provider.notifier).setStatus(status);

    if (!mounted) {
      return;
    }

    final result = ref.read(provider);

    if (result.hasError) {
      return;
    }

    ref.invalidate(needsReviewQuestionsProvider(user.id));
    ref.invalidate(topicProgressProvider(user.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == QuestionProgressStatus.understood
              ? 'Marked as understood.'
              : 'Added to questions that need review.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsControllerProvider(_query));
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.name),
        actions: [
          IconButton(
            tooltip: 'Filter questions',
            onPressed: _openFilters,
            icon: Icon(
              _query.hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
          ),
        ],
      ),
      body: questions.when(
        loading: () => const LoadingSkeleton(layout: SkeletonLayout.question),
        error: (error, _) => _QuestionError(
          message: error is ApiException
              ? error.message
              : 'Unable to load questions.',
          onRetry: () =>
              ref.read(questionsControllerProvider(_query).notifier).refresh(),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const _EmptyQuestions();
          }

          final currentQuestion = page.items[_currentIndex];

          final progressProvider = questionProgressControllerProvider(
            currentQuestion.id,
          );

          final progressState = ref.watch(progressProvider);

          return Column(
            children: [
              _QuestionHeader(
                question: currentQuestion,
                currentIndex: _currentIndex,
                totalCount: page.totalCount,
                discussionAction: QuestionDiscussionButton(
                  question: currentQuestion,
                ),
                bookmarkAction: QuestionBookmarkButton(
                  user: currentUser,
                  question: currentQuestion,
                ),
              ),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / page.totalCount,
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: page.items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _showMemo = false;
                    });

                    if (index >= page.items.length - 2) {
                      ref
                          .read(questionsControllerProvider(_query).notifier)
                          .loadNextPage();
                    }
                  },
                  itemBuilder: (context, index) {
                    final question = page.items[index];

                    return QuestionContentCard(
                      question: question,
                      showMemo: index == _currentIndex && _showMemo,
                    );
                  },
                ),
              ),
              if (page.isLoadingMore)
                const LinearProgressIndicator()
              else if (page.loadMoreError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          page.loadMoreError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(questionsControllerProvider(_query).notifier)
                            .loadNextPage(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (_showMemo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: progressState.when(
                    loading: () => QuestionReflectionCard(
                      status: null,
                      isSaving: true,
                      onUnderstood: () {},
                      onNeedsReview: () {},
                    ),
                    error: (error, stackTrace) {
                      return QuestionReflectionCard(
                        status: null,
                        isSaving: false,
                        errorMessage: 'Unable to load or save your progress.',
                        onRetry: () {
                          ref.invalidate(progressProvider);
                        },
                        onUnderstood: () => _recordProgress(
                          user: currentUser,
                          questionId: currentQuestion.id,
                          status: QuestionProgressStatus.understood,
                        ),
                        onNeedsReview: () => _recordProgress(
                          user: currentUser,
                          questionId: currentQuestion.id,
                          status: QuestionProgressStatus.needsReview,
                        ),
                      );
                    },
                    data: (progress) => QuestionReflectionCard(
                      status: progress?.status,
                      isSaving: false,
                      onUnderstood: () => _recordProgress(
                        user: currentUser,
                        questionId: currentQuestion.id,
                        status: QuestionProgressStatus.understood,
                      ),
                      onNeedsReview: () => _recordProgress(
                        user: currentUser,
                        questionId: currentQuestion.id,
                        status: QuestionProgressStatus.needsReview,
                      ),
                    ),
                  ),
                ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMemo = !_showMemo;
                      });
                    },
                    icon: Icon(
                      _showMemo
                          ? Icons.description_outlined
                          : Icons.visibility_outlined,
                    ),
                    label: Text(_showMemo ? 'Show question' : 'Reveal memo'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.question,
    required this.currentIndex,
    required this.totalCount,
    required this.discussionAction,
    required this.bookmarkAction,
  });

  final Question question;
  final int currentIndex;
  final int totalCount;
  final Widget discussionAction;
  final Widget bookmarkAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${question.questionNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              discussionAction,
              bookmarkAction,
              const SizedBox(width: 4),
              Text(
                '${currentIndex + 1} of $totalCount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Text(
            '${question.examYear} • '
            '${question.examSeason} • '
            'Paper ${question.paperNumber}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _QuestionError extends StatelessWidget {
  const _QuestionError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No published questions are available for this topic yet.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
