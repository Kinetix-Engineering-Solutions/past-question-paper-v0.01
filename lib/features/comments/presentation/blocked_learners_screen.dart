import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/blocked_learner.dart';
import '../providers/blocked_learners_providers.dart';

class BlockedLearnersScreen extends ConsumerWidget {
  const BlockedLearnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedLearners = ref.watch(blockedLearnersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked learners')),
      body: blockedLearners.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stackTrace) => _LoadError(
          onRetry: () {
            ref.read(blockedLearnersControllerProvider.notifier).refresh();
          },
        ),
        data: (state) {
          if (state.learners.isEmpty) {
            return const _EmptyBlockedLearners();
          }

          return RefreshIndicator(
            onRefresh: () {
              return ref
                  .read(blockedLearnersControllerProvider.notifier)
                  .refresh();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount:
                  state.learners.length + (state.errorMessage == null ? 0 : 1),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (state.errorMessage != null && index == 0) {
                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(state.errorMessage!),
                      trailing: IconButton(
                        tooltip: 'Dismiss',
                        onPressed: () {
                          ref
                              .read(blockedLearnersControllerProvider.notifier)
                              .clearError();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  );
                }

                final learnerIndex =
                    index - (state.errorMessage == null ? 0 : 1);
                final learner = state.learners[learnerIndex];

                return _BlockedLearnerTile(
                  learner: learner,
                  isUnblocking: state.isUnblocking(learner.userId),
                  onUnblock: () {
                    _unblockLearner(context, ref, learner);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _unblockLearner(
    BuildContext context,
    WidgetRef ref,
    BlockedLearner learner,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unblock learner?'),
          content: Text(
            'Comments from ${learner.displayName} '
            'will become visible to you again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Unblock'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await ref
        .read(blockedLearnersControllerProvider.notifier)
        .unblockUser(learner.userId);

    if (!context.mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${learner.displayName} has been unblocked.')),
    );
  }
}

class _BlockedLearnerTile extends StatelessWidget {
  const _BlockedLearnerTile({
    required this.learner,
    required this.isUnblocking,
    required this.onUnblock,
  });

  final BlockedLearner learner;
  final bool isUnblocking;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(learner.displayName.substring(0, 1).toUpperCase()),
        ),
        title: Text(learner.displayName),
        subtitle: const Text('Their comments are hidden from you.'),
        trailing: isUnblocking
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(onPressed: onUnblock, child: const Text('Unblock')),
      ),
    );
  }
}

class _EmptyBlockedLearners extends StatelessWidget {
  const _EmptyBlockedLearners();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 56),
            SizedBox(height: 16),
            Text(
              'You have not blocked any learners.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry blocked learners'),
      ),
    );
  }
}
