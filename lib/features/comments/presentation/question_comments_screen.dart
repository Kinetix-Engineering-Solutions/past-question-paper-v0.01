import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:past_question_paper_v1/features/auth/domain/app_user.dart';
import 'package:past_question_paper_v1/features/auth/presentation/auth_screen.dart';
import 'package:past_question_paper_v1/features/auth/providers/auth_providers.dart';
import 'package:past_question_paper_v1/features/comments/domain/community_guidelines_status.dart';
import 'package:past_question_paper_v1/features/comments/domain/question_comment.dart';
import 'package:past_question_paper_v1/features/comments/domain/question_comment_report_reason.dart';
import 'package:past_question_paper_v1/features/comments/presentation/community_guidelines_screen.dart';
import 'package:past_question_paper_v1/features/comments/providers/community_guidelines_providers.dart';
import 'package:past_question_paper_v1/features/comments/providers/question_comments_providers.dart';
import 'package:past_question_paper_v1/features/comments/providers/question_comments_state.dart';
import 'package:past_question_paper_v1/features/profile/domain/learner_profile.dart';
import 'package:past_question_paper_v1/features/profile/presentation/profile_screen.dart';
import 'package:past_question_paper_v1/features/profile/providers/profile_providers.dart';
import 'package:past_question_paper_v1/features/questions/data/models/question.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionCommentsScreen extends ConsumerStatefulWidget {
  const QuestionCommentsScreen({required this.question, super.key});

  final Question question;

  @override
  ConsumerState<QuestionCommentsScreen> createState() =>
      _QuestionCommentsScreenState();
}

class _QuestionCommentsScreenState
    extends ConsumerState<QuestionCommentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void dispose() {
    _bodyController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final provider = questionCommentsControllerProvider(question.id);
    final comments = ref.watch(provider);

    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    final AsyncValue<CommunityGuidelinesStatus>? guidelinesState = user == null
        ? null
        : ref.watch(communityGuidelinesControllerProvider(user.id));

    final AsyncValue<LearnerProfile>? profileState = user == null
        ? null
        : ref.watch(profileControllerProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${question.questionNumber} discussion'),
      ),
      body: comments.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () {
              ref.read(provider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry comments'),
          ),
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildComposer(
                  user: user,
                  profileState: profileState,
                  guidelinesState: guidelinesState,
                  state: state,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  '${state.comments.length} '
                  '${state.comments.length == 1 ? 'comment' : 'comments'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (state.comments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No comments yet. Be the first '
                        'learner to share an explanation.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...state.comments.map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CommentCard(
                        comment: comment,
                        isDeleting: state.isDeleting(comment.id),
                        isReporting: state.isReporting(comment.id),
                        isBlocking: state.isBlocking(comment.id),
                        onDelete: comment.isOwnComment
                            ? () => _deleteComment(comment.id)
                            : null,
                        onReport: user != null && !comment.isOwnComment
                            ? () => _reportComment(comment.id)
                            : null,
                        onBlock: user != null && !comment.isOwnComment
                            ? () => _blockCommentAuthor(comment)
                            : null,
                        onOpenLink: comment.externalUrl == null
                            ? null
                            : () => _openExternalLink(comment.externalUrl!),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer({
    required AppUser? user,
    required AsyncValue<LearnerProfile>? profileState,
    required AsyncValue<CommunityGuidelinesStatus>? guidelinesState,
    required QuestionCommentsState state,
  }) {
    if (user == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.forum_outlined),
          title: const Text('Sign in to join the discussion'),
          subtitle: const Text('Everyone can read comments.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
          },
        ),
      );
    }

    if (profileState == null || profileState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (profileState.hasError) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('Unable to load your profile'),
          trailing: const Icon(Icons.refresh),
          onTap: () {
            ref.invalidate(profileControllerProvider(user.id));
          },
        ),
      );
    }

    final profile = profileState.asData?.value;

    if (profile == null || !profile.isComplete) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('Complete your profile to comment'),
          subtitle: const Text('Add a display name and grade first.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileScreen(user: user),
              ),
            );
          },
        ),
      );
    }

    if (guidelinesState == null || guidelinesState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (guidelinesState.hasError) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('Unable to check Community Guidelines'),
          subtitle: const Text('Tap to try again.'),
          trailing: const Icon(Icons.refresh),
          onTap: () {
            ref
                .read(communityGuidelinesControllerProvider(user.id).notifier)
                .refresh();
          },
        ),
      );
    }

    final guidelinesStatus = guidelinesState.asData?.value;

    if (guidelinesStatus == null || !guidelinesStatus.isAccepted) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Accept the Community Guidelines'),
          subtitle: const Text('Review the discussion rules before posting.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CommunityGuidelinesScreen(userId: user.id),
              ),
            );
          },
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share an explanation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                enabled: !state.isBusy,
                maxLength: 1000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  hintText:
                      'Explain how you approached '
                      'this question.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final body = value?.trim() ?? '';

                  if (body.length < 2) {
                    return 'Enter at least 2 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                enabled: !state.isBusy,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'YouTube or TikTok link (optional)',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                validator: _validateExternalUrl,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.isBusy ? null : _submit,
                icon: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(state.isSubmitting ? 'Posting...' : 'Post comment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateExternalUrl(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(raw);

    if (uri == null || uri.scheme != 'https') {
      return 'Enter a valid HTTPS link.';
    }

    final host = uri.host.toLowerCase();

    final isYouTube =
        host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be';

    final isTikTok = host == 'tiktok.com' || host.endsWith('.tiktok.com');

    if (!isYouTube && !isTikTok) {
      return 'Only YouTube and TikTok links are supported.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(questionCommentsControllerProvider(widget.question.id).notifier)
        .createComment(
          body: _bodyController.text,
          externalUrl: _linkController.text,
        );

    if (!mounted || !success) {
      return;
    }

    _bodyController.clear();
    _linkController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete comment?'),
          content: const Text(
            'This comment will be removed '
            'from the discussion.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref
        .read(questionCommentsControllerProvider(widget.question.id).notifier)
        .deleteComment(commentId);
  }

  Future<void> _reportComment(String commentId) async {
    final request = await showDialog<_CommentReportRequest>(
      context: context,
      builder: (_) => const _CommentReportDialog(),
    );

    if (request == null || !mounted) {
      return;
    }

    final success = await ref
        .read(questionCommentsControllerProvider(widget.question.id).notifier)
        .reportComment(
          commentId: commentId,
          reason: request.reason,
          details: request.details,
        );

    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted for review.')),
    );
  }

  Future<void> _blockCommentAuthor(QuestionComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block learner?'),
          content: Text(
            'Comments from ${comment.authorDisplayName} will no '
            'longer appear for you.',
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
              child: const Text('Block'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await ref
        .read(questionCommentsControllerProvider(widget.question.id).notifier)
        .blockCommentAuthor(comment.id);

    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Learner blocked. Their comments are now hidden.'),
      ),
    );
  }

  Future<void> _openExternalLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);

    if (uri == null) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }
}

final class _CommentReportRequest {
  const _CommentReportRequest({required this.reason, required this.details});

  final QuestionCommentReportReason reason;
  final String details;
}

class _CommentReportDialog extends StatefulWidget {
  const _CommentReportDialog();

  @override
  State<_CommentReportDialog> createState() => _CommentReportDialogState();
}

class _CommentReportDialogState extends State<_CommentReportDialog> {
  final _detailsController = TextEditingController();
  var _selectedReason = QuestionCommentReportReason.spam;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report comment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tell us why this comment should be reviewed.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<QuestionCommentReportReason>(
              // ignore: deprecated_member_use
              value: _selectedReason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: QuestionCommentReportReason.values
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (reason) {
                if (reason == null) {
                  return;
                }

                setState(() {
                  _selectedReason = reason;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _CommentReportRequest(
                reason: _selectedReason,
                details: _detailsController.text,
              ),
            );
          },
          child: const Text('Submit report'),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isDeleting,
    required this.isReporting,
    required this.isBlocking,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
    required this.onOpenLink,
  });

  final QuestionComment comment;
  final bool isDeleting;
  final bool isReporting;
  final bool isBlocking;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onOpenLink;

  bool get isWorking => isDeleting || isReporting || isBlocking;

  @override
  Widget build(BuildContext context) {
    final providerLabel = comment.linkProvider == CommentLinkProvider.youtube
        ? 'Watch on YouTube'
        : 'Watch on TikTok';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    comment.authorDisplayName.substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorDisplayName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isWorking)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (comment.isOwnComment && onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Comment actions',
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  )
                else if (onReport != null && onBlock != null)
                  PopupMenuButton<String>(
                    tooltip: 'Comment actions',
                    onSelected: (value) {
                      switch (value) {
                        case 'report':
                          onReport?.call();
                        case 'block':
                          onBlock?.call();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'report',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.flag_outlined),
                          title: Text('Report'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.block),
                          title: Text('Block learner'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(comment.body),
            if (comment.hasExternalLink) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenLink,
                icon: const Icon(Icons.open_in_new),
                label: Text(providerLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}
