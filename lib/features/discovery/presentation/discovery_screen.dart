import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:past_question_paper_v1/features/questions/presentation/question_screen.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/account_screen.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../legal/presentation/legal_documents_screen.dart';
import '../../progress/domain/topic_progress.dart';
import '../../progress/providers/topic_progress_provider.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/models/discovery_data.dart';
import '../data/models/topic.dart';
import '../providers/discovery_providers.dart';
import 'widgets/past_paper_hero.dart';
import 'widgets/topic_grid_card.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(discoveryControllerProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.asData?.value;
    final learnerName = currentUser == null
        ? null
        : ref
              .watch(profileControllerProvider(currentUser.id))
              .valueOrNull
              ?.displayName;

    return Scaffold(
      body: SafeArea(
        child: discovery.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DiscoveryError(
            message: _errorMessage(error),
            onRetry: () =>
                ref.read(discoveryControllerProvider.notifier).refresh(),
          ),
          data: (data) {
            if (data.isEmpty) {
              return _EmptyDiscovery(
                onRefresh: () =>
                    ref.read(discoveryControllerProvider.notifier).refresh(),
              );
            }

            final progress = currentUser == null
                ? const AsyncValue<List<TopicProgress>>.data(<TopicProgress>[])
                : ref.watch(topicProgressProvider(currentUser.id));

            return _DiscoveryContent(
              data: data,
              progress: progress,
              learnerName: learnerName,
              tracksProgress: currentUser != null,
              isSignedIn: currentUser != null,
              onInfoPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalDocumentsScreen(),
                  ),
                );
              },
              onAccountPressed: authState.isLoading
                  ? null
                  : () => _openAccount(context, currentUser),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAccount(BuildContext context, AppUser? user) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            user == null ? const AuthScreen() : AccountScreen(user: user),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Unable to load subjects and topics.';
  }
}

class _DiscoveryContent extends ConsumerStatefulWidget {
  const _DiscoveryContent({
    required this.data,
    required this.progress,
    required this.learnerName,
    required this.tracksProgress,
    required this.isSignedIn,
    required this.onInfoPressed,
    required this.onAccountPressed,
  });

  final DiscoveryData data;
  final AsyncValue<List<TopicProgress>> progress;
  final String? learnerName;
  final bool tracksProgress;
  final bool isSignedIn;
  final VoidCallback onInfoPressed;
  final VoidCallback? onAccountPressed;

  @override
  ConsumerState<_DiscoveryContent> createState() => _DiscoveryContentState();
}

class _DiscoveryContentState extends ConsumerState<_DiscoveryContent> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = _initialSubjectId();
  }

  @override
  void didUpdateWidget(covariant _DiscoveryContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectionStillExists = widget.data.subjects.any(
      (subject) => subject.id == _selectedSubjectId,
    );

    if (!selectionStillExists) {
      _selectedSubjectId = _initialSubjectId();
    }
  }

  String? _initialSubjectId() {
    if (widget.data.subjects.isEmpty) {
      return null;
    }

    return widget.data.subjects.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSubjectId = _selectedSubjectId;
    final visibleTopics = selectedSubjectId == null
        ? const <Topic>[]
        : widget.data.topicsForSubject(selectedSubjectId);
    final sortedTopics = visibleTopics.toList(growable: false)
      ..sort((a, b) {
        final availability = (b.questionCount > 0 ? 1 : 0).compareTo(
          a.questionCount > 0 ? 1 : 0,
        );
        return availability != 0
            ? availability
            : a.displayOrder.compareTo(b.displayOrder);
      });
    final progressByTopic = {
      for (final item in widget.progress.valueOrNull ?? const <TopicProgress>[])
        item.topic.id: item,
    };
    final progressItems = widget.progress.valueOrNull;
    final reviewedQuestions = progressItems?.fold<int>(
      0,
      (total, item) => total + item.summary.reviewedCount,
    );
    final totalQuestions = widget.data.topics.fold<int>(
      0,
      (total, topic) => total + topic.questionCount,
    );
    final overallProgress = reviewedQuestions == null || totalQuestions == 0
        ? null
        : (reviewedQuestions / totalQuestions).clamp(0.0, 1.0).toDouble();
    final continueItem =
        (widget.progress.valueOrNull ?? const <TopicProgress>[])
            .where(
              (item) =>
                  item.topic.subjectId == selectedSubjectId &&
                  item.topic.questionCount > 0,
            )
            .fold<TopicProgress?>(
              null,
              (latest, item) =>
                  latest == null ||
                      item.summary.lastReviewedAt.isAfter(
                        latest.summary.lastReviewedAt,
                      )
                  ? item
                  : latest,
            );

    return RefreshIndicator(
      onRefresh: () => ref.read(discoveryControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          PastPaperHero(
            learnerName: widget.learnerName,
            progress: widget.tracksProgress ? overallProgress : null,
            reviewedQuestions: widget.tracksProgress ? reviewedQuestions : null,
            totalQuestions: widget.tracksProgress ? totalQuestions : null,
            onInfoPressed: widget.onInfoPressed,
            onAccountPressed: widget.onAccountPressed,
            isSignedIn: widget.isSignedIn,
          ),
          if (widget.data.subjects.isNotEmpty)
            _SubjectSelector(
              subjects: widget.data.subjects
                  .map(
                    (subject) =>
                        _SubjectOption(id: subject.id, name: subject.name),
                  )
                  .toList(growable: false),
              selectedSubjectId: selectedSubjectId,
              onSelected: (subjectId) {
                setState(() {
                  _selectedSubjectId = subjectId;
                });
              },
            ),
          if (continueItem != null) ...[
            const SizedBox(height: 24),
            Text(
              'Continue practising',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _ContinueCard(progress: continueItem),
          ],
          const SizedBox(height: 24),
          _TopicsHeader(topicCount: sortedTopics.length),
          const SizedBox(height: 12),
          if (sortedTopics.isEmpty)
            const _NoTopicsForSubject()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = constraints.maxWidth < 300 ? 1 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedTopics.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 172,
                  ),
                  itemBuilder: (context, index) {
                    final topic = sortedTopics[index];
                    return TopicGridCard(
                      topic: topic,
                      progress: progressByTopic[topic.id],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => QuestionScreen(topic: topic),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SubjectOption {
  const _SubjectOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _SubjectSelector extends StatelessWidget {
  const _SubjectSelector({
    required this.subjects,
    required this.selectedSubjectId,
    required this.onSelected,
  });

  final List<_SubjectOption> subjects;
  final String? selectedSubjectId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedId = selectedSubjectId;

    if (selectedId == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < subjects.length; index++) ...[
            Semantics(
              button: true,
              selected: subjects[index].id == selectedId,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(subjects[index].id),
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Text(
                          subjects[index].name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: subjects[index].id == selectedId
                                    ? AppColors.ink
                                    : AppColors.mutedInk,
                                fontWeight: subjects[index].id == selectedId
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                      if (subjects[index].id == selectedId)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (index != subjects.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress});

  final TopicProgress progress;

  @override
  Widget build(BuildContext context) {
    final topic = progress.topic;
    return Card(
      color: AppColors.neutralCard,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => QuestionScreen(topic: topic)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                '${progress.summary.reviewedCount} of ${topic.questionCount} questions reviewed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: AppColors.mutedInk, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicsHeader extends StatelessWidget {
  const _TopicsHeader({required this.topicCount});

  final int topicCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Topics', style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(
          '$topicCount ${topicCount == 1 ? 'topic' : 'topics'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _NoTopicsForSubject extends StatelessWidget {
  const _NoTopicsForSubject();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: AppColors.mutedInk,
          ),
          const SizedBox(height: 12),
          Text(
            'No topics are available for this subject yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.message, required this.onRetry});

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

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Grade 12 topics are available yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}
