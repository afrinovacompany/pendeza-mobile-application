import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendeza/screens/splash_view.dart';

void main() {
  const title = 'Pendeza';
  const tagline = 'Your Style, Your Schedule';

  Widget host({bool disableAnimations = false, Animation<double>? exit}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: SplashView(
            title: title,
            tagline: tagline,
            exit: exit ?? const AlwaysStoppedAnimation<double>(0),
          ),
        ),
      ),
    );
  }

  testWidgets('starts on the flat native launch colour', (tester) async {
    await tester.pumpWidget(host());

    // Frame 0 has no visible content yet, so it matches the native launch
    // screen exactly (that is what makes the hand-off seamless).
    final letters = tester.widgetList<Opacity>(
      find.ancestor(of: find.text('P'), matching: find.byType(Opacity)),
    );
    expect(letters.first.opacity, 0);
    expect(
      tester
          .widget<ColoredBox>(find.descendant(
            of: find.byType(SplashView),
            matching: find.byType(ColoredBox),
          ).first)
          .color,
      SplashView.launchColor,
    );
  });

  testWidgets('announces the app name and tagline to screen readers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host());
    await tester.pump(const Duration(seconds: 2));

    expect(find.bySemanticsLabel('$title. $tagline'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reduce motion: shows the finished state and stays still',
      (tester) async {
    await tester.pumpWidget(host(disableAnimations: true));
    await tester.pump();

    final letters = tester.widgetList<Opacity>(
      find.ancestor(of: find.text('P'), matching: find.byType(Opacity)),
    );
    expect(letters.first.opacity, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('exit animation fades the content out', (tester) async {
    final exit = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 350),
    );
    addTearDown(exit.dispose);

    await tester.pumpWidget(host(disableAnimations: true, exit: exit));
    await tester.pump();

    double contentOpacity() => tester
        .widgetList<Opacity>(find.ancestor(
            of: find.text('P'), matching: find.byType(Opacity)))
        .map((o) => o.opacity)
        .reduce((a, b) => a < b ? a : b);

    expect(contentOpacity(), 1);
    exit.value = 1;
    await tester.pump();
    expect(contentOpacity(), 0);
  });
}
