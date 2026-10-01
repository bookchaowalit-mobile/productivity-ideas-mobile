/// Ideas with ICE (impact x confidence x ease) scoring.
library;

import 'package:characters/characters.dart';

class Idea {
  Idea({
    required this.id,
    required String title,
    required this.impact,
    required this.confidence,
    required this.ease,
    this.archived = false,
  }) : title = title.trim() {
    for (final (name, v) in [
      ('impact', impact),
      ('confidence', confidence),
      ('ease', ease),
    ]) {
      if (v < 1 || v > 10) throw ArgumentError.value(v, name, 'must be 1-10');
    }
  }

  final int id;
  final String title;
  final int impact;
  final int confidence;
  final int ease;
  final bool archived;

  /// Product score, 1-1000.
  int get iceScore => impact * confidence * ease;

  /// Mean of the three scores, 1.0-10.0 (the other common ICE variant).
  double get iceAverage => (impact + confidence + ease) / 3;

  /// Throws [ArgumentError] when a new score is outside 1-10.
  Idea copyWith({bool? archived, int? impact, int? confidence, int? ease}) =>
      Idea(
        id: id,
        title: title,
        impact: impact ?? this.impact,
        confidence: confidence ?? this.confidence,
        ease: ease ?? this.ease,
        archived: archived ?? this.archived,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'impact': impact,
        'confidence': confidence,
        'ease': ease,
        'archived': archived,
      };

  /// Throws on malformed input (wrong types or scores outside 1-10).
  static Idea fromJson(Map<String, Object?> json) => Idea(
        id: json['id'] as int,
        title: json['title'] as String,
        impact: json['impact'] as int,
        confidence: json['confidence'] as int,
        ease: json['ease'] as int,
        archived: json['archived'] as bool? ?? false,
      );
}

Map<String, Object?> ideaToJson(Idea idea) => idea.toJson();

/// Case- and whitespace-insensitive key used for duplicate detection.
String titleKey(String title) =>
    title.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String? validateTitle(String title, Iterable<Idea> existing) {
  final t = title.trim();
  if (t.isEmpty) return 'Describe the idea';
  // Grapheme clusters, so emoji and Thai combining marks count once.
  if (t.characters.length > 120) return 'Keep it under 120 characters';
  if (existing.any((i) => !i.archived && titleKey(i.title) == titleKey(t))) {
    return 'You already have this idea';
  }
  return null;
}

/// Whether restoring [idea] from the archive would create a second active
/// idea with the same title (which [validateTitle] prevents when adding).
bool restoreWouldDuplicate(Idea idea, Iterable<Idea> existing) => existing.any(
      (i) =>
          !i.archived &&
          i.id != idea.id &&
          titleKey(i.title) == titleKey(idea.title),
    );

/// Active (or archived) ideas ranked by ICE score, then impact, then
/// newest id first.
List<Idea> ranked(Iterable<Idea> ideas, {bool archived = false}) {
  return ideas.where((i) => i.archived == archived).toList()
    ..sort((a, b) {
      var c = b.iceScore.compareTo(a.iceScore);
      if (c != 0) return c;
      c = b.impact.compareTo(a.impact);
      if (c != 0) return c;
      return b.id.compareTo(a.id);
    });
}

String tierOf(int score) {
  if (score >= 400) return 'Do now';
  if (score >= 150) return 'Next';
  if (score >= 50) return 'Later';
  return 'Park';
}
