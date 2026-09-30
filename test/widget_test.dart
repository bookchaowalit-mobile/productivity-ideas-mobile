import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ideas/main.dart';
import 'package:ideas/screens/home_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app shell shows ideas and about tab', (tester) async {
    await tester.pumpWidget(const IdeasApp());
    await tester.pumpAndSettle();
    expect(find.text('Ideas'), findsWidgets);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('add ideas, rank them and archive', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-idea')));
    await tester.pump();
    expect(find.text('Describe the idea'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('title-input')), 'Small');
    await tester.tap(find.byKey(const Key('add-idea')));
    await tester.pump();
    expect(find.text('ICE 125 · Later'), findsOneWidget);

    // Max out impact for the second idea so it ranks first.
    await tester.drag(find.byType(Slider).first, const Offset(2000, 0));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('title-input')), 'Big');
    await tester.tap(find.byKey(const Key('add-idea')));
    await tester.pump();
    String rank(int i) => tester.widget<Text>(find.byKey(Key('rank-$i'))).data!;
    expect(rank(0), 'Big');
    expect(rank(1), 'Small');

    await tester.tap(find.byTooltip('Archive Big'));
    await tester.pump();
    expect(rank(0), 'Small');
    await tester.tap(find.text('Archived'));
    await tester.pump();
    expect(rank(0), 'Big');
  });

  Widget home({double textScale = 1}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const HomeScreen(),
        ),
      );

  Future<void> addIdea(WidgetTester tester, String title) async {
    await tester.enterText(find.byKey(const Key('title-input')), title);
    await tester.tap(find.byKey(const Key('add-idea')));
    await tester.pump();
  }

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('restoring a duplicate is blocked with a message', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    await addIdea(tester, 'Dark mode');
    await tester.tap(find.byTooltip('Archive Dark mode'));
    await tester.pump();
    await addIdea(tester, 'dark  mode');
    expect(find.text('You already have this idea'), findsNothing);
    await tester.tap(find.text('Archived'));
    await tester.pump();
    await tester.tap(find.byTooltip('Restore Dark mode'));
    await tester.pump();
    expect(find.text('An active idea already has this title.'), findsOneWidget);
    expect(find.byTooltip('Restore Dark mode'), findsOneWidget);
  });

  testWidgets('tapping an idea re-scores it', (tester) async {
    tall(tester);
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    await addIdea(tester, 'Small');
    expect(find.text('ICE 125 · Later · I5 C5 E5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rank-0')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('edit-impact')),
      const Offset(2000, 0),
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('edit-score'))).data,
      'ICE 250 · Next',
    );
    await tester.tap(find.byKey(const Key('save-scores')));
    await tester.pumpAndSettle();
    expect(find.text('ICE 250 · Next · I10 C5 E5'), findsOneWidget);
  });

  testWidgets('delete can be undone', (tester) async {
    tall(tester);
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    await addIdea(tester, 'Small');
    await tester.tap(find.byTooltip('Delete Small'));
    await tester.pumpAndSettle();
    expect(find.text('No ideas yet.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rank-0')), findsOneWidget);
  });

  testWidgets('meets tap-target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    await addIdea(tester, 'Small');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('lays out at 200% text scale on a phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(home(textScale: 2));
    await tester.pumpAndSettle();
    await addIdea(tester, 'Small');
    expect(tester.takeException(), isNull);
  });
}
