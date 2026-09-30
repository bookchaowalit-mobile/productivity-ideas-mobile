import 'package:flutter_test/flutter_test.dart';
import 'package:ideas/logic/ice.dart';

Idea idea(int id, String t, int i, int c, int e, {bool archived = false}) =>
    Idea(
        id: id,
        title: t,
        impact: i,
        confidence: c,
        ease: e,
        archived: archived);

void main() {
  test('scores and tiers', () {
    final a = idea(1, 'a', 10, 10, 10);
    expect(a.iceScore, 1000);
    expect(a.iceAverage, 10);
    expect(idea(2, 'b', 1, 2, 3).iceAverage, 2);
    expect(tierOf(400), 'Do now');
    expect(tierOf(399), 'Next');
    expect(tierOf(150), 'Next');
    expect(tierOf(50), 'Later');
    expect(tierOf(49), 'Park');
  });

  test('scores must be 1-10', () {
    expect(() => idea(1, 'x', 0, 5, 5), throwsArgumentError);
    expect(() => idea(1, 'x', 5, 11, 5), throwsArgumentError);
  });

  test('ranked orders by score, impact, then newest', () {
    final ideas = [
      idea(1, 'low', 2, 2, 2),
      idea(2, 'tie-low-impact', 4, 5, 5),
      idea(3, 'tie-high-impact', 5, 4, 5),
      idea(4, 'tie-high-impact-newer', 5, 5, 4),
      idea(5, 'archived', 10, 10, 10, archived: true),
    ];
    expect(ranked(ideas).map((i) => i.id), [4, 3, 2, 1]);
    expect(ranked(ideas, archived: true).map((i) => i.id), [5]);
  });

  test('validateTitle', () {
    final ideas = [
      idea(1, 'Dark mode', 5, 5, 5),
      idea(2, 'Old', 1, 1, 1, archived: true)
    ];
    expect(validateTitle('  ', ideas), 'Describe the idea');
    expect(validateTitle('dark MODE', ideas), 'You already have this idea');
    expect(validateTitle('old', ideas), isNull);
    expect(validateTitle('x' * 121, ideas), isNotNull);
  });

  test('copyWith toggles archive', () {
    final a = idea(1, 'a', 1, 1, 1).copyWith(archived: true);
    expect(a.archived, isTrue);
    expect(a.copyWith().archived, isTrue);
  });
}
