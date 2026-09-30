/// Ideas with ICE (impact x confidence x ease) scoring.
library;

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

  Idea copyWith({bool? archived}) => Idea(
        id: id,
        title: title,
        impact: impact,
        confidence: confidence,
        ease: ease,
        archived: archived ?? this.archived,
      );
}

String? validateTitle(String title, Iterable<Idea> existing) {
  final t = title.trim();
  if (t.isEmpty) return 'Describe the idea';
  if (t.length > 120) return 'Keep it under 120 characters';
  if (existing
      .any((i) => !i.archived && i.title.toLowerCase() == t.toLowerCase())) {
    return 'You already have this idea';
  }
  return null;
}

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
