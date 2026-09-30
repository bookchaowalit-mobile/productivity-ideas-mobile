import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideas/main.dart';
import 'package:ideas/screens/home_screen.dart';

void main() {
  testWidgets('app shell shows ideas and about tab', (tester) async {
    await tester.pumpWidget(const IdeasApp());
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
}
