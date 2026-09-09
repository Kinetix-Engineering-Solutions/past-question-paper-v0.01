import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:past_question_paper_v1/shared/widgets/loading_skeleton.dart';

void main() {
  testWidgets('all layouts fit narrow and wide screens', (tester) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    for (final width in [280.0, 390.0, 800.0]) {
      tester.view.physicalSize = Size(width, 800);
      for (final layout in SkeletonLayout.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LoadingSkeleton(layout: layout)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion is static and loading has an accessible label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LoadingSkeleton()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.bySemanticsLabel('Loading content'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics.dispose();
  });
}
