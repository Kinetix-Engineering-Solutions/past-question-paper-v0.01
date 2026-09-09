import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:past_question_paper_v1/features/discovery/presentation/widgets/past_paper_hero.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';

void main() {
  Future<void> showHero(
    WidgetTester tester, {
    bool signedIn = true,
    bool loading = false,
    double? progress,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              child: PastPaperHero(
                learnerName: 'Learner',
                progress: progress,
                reviewedQuestions: progress == null ? null : 0,
                totalQuestions: progress == null ? null : 10,
                isSignedIn: signedIn,
                isProgressLoading: loading,
                onInfoPressed: () {},
                onAccountPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loading becomes progress without showing the sign-in prompt', (
    tester,
  ) async {
    await showHero(tester, loading: true);
    expect(find.byType(ShimmerLoading), findsOneWidget);
    expect(find.text('Sign in to track your progress'), findsNothing);
    await showHero(tester, progress: 0);
    expect(find.byType(ShimmerLoading), findsNothing);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 of 10 questions reviewed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in prompt appears only after auth resolves signed out', (
    tester,
  ) async {
    await showHero(tester, signedIn: false, loading: true);
    expect(find.byType(ShimmerLoading), findsOneWidget);
    expect(find.text('Sign in to track your progress'), findsNothing);
    await showHero(tester, signedIn: false);
    expect(find.text('Sign in to track your progress'), findsOneWidget);
    expect(find.byType(ShimmerLoading), findsNothing);
  });

  testWidgets(
    'unavailable progress does not ask signed-in learners to sign in',
    (tester) async {
      await showHero(tester);
      expect(
        find.text('Progress unavailable. Pull down to retry.'),
        findsOneWidget,
      );
      expect(find.text('Sign in to track your progress'), findsNothing);
      expect(find.byType(ShimmerLoading), findsNothing);
    },
  );

  testWidgets('refresh keeps previously loaded progress visible', (
    tester,
  ) async {
    await showHero(tester, loading: true, progress: 0);
    expect(find.text('0%'), findsOneWidget);
    expect(find.byType(ShimmerLoading), findsNothing);
  });
}
