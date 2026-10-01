import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideas/data/list_repository.dart';
import 'package:ideas/data/idea_repository.dart';
import 'package:ideas/logic/ice.dart';
import 'package:ideas/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final sample =
      Idea(id: 7, title: 'Newsletter', impact: 8, confidence: 6, ease: 5);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips ideas through shared_preferences', () async {
    await deviceIdeaRepository.save([sample]);
    final loaded = await deviceIdeaRepository.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.toJson(), sample.toJson());
  });

  test('empty storage loads an empty list', () async {
    expect(await deviceIdeaRepository.load(), isEmpty);
  });

  test('skips malformed records and rejects non-list payloads', () async {
    SharedPreferences.setMockInitialValues({
      'ideas_ideas_v1': jsonEncode([
        sample.toJson(),
        {'id': 'x'},
        42,
      ]),
    });
    expect(await deviceIdeaRepository.load(), hasLength(1));

    SharedPreferences.setMockInitialValues({'ideas_ideas_v1': '{}'});
    expect(deviceIdeaRepository.load(), throwsFormatException);
  });

  testWidgets('home screen restores saved ideas and saves changes',
      (tester) async {
    final repo = InMemoryListRepository<Idea>([sample]);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Newsletter'), findsWidgets);

    await tester.tap(find.byTooltip('Archive Newsletter'));
    await tester.pumpAndSettle();
    expect((await repo.load()).single.archived, isTrue);
  });

  testWidgets('shows an error when saved ideas cannot be read', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: _FailingRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('storage-error')), findsOneWidget);
  });
}

class _FailingRepository implements ListRepository<Idea> {
  @override
  Future<List<Idea>> load() async => throw const FormatException('bad');

  @override
  Future<void> save(List<Idea> items) async => throw StateError('full');
}
