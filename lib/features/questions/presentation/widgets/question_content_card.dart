import 'package:flutter/material.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';

import '../../data/models/question.dart';

class QuestionContentCard extends StatelessWidget {
  const QuestionContentCard({
    required this.question,
    required this.showMemo,
    super.key,
  });

  final Question question;
  final bool showMemo;

  @override
  Widget build(BuildContext context) {
    final imageUri = showMemo
        ? question.memoImageUrl
        : question.questionImageUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    showMemo ? Icons.task_alt : Icons.description_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    showMemo ? 'Memo' : 'Question',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    imageUri.toString(),
                    width: constraints.maxWidth,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }

                      return const ShimmerLoading(
                        child: SkeletonBlock(height: 200),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_outlined, size: 48),
                              SizedBox(height: 12),
                              Text('Unable to load this image.'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
