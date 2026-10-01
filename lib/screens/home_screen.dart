import 'package:flutter/material.dart';

import '../data/idea_repository.dart';
import '../data/list_repository.dart';
import '../logic/ice.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});

  /// Where ideas are stored. Defaults to an in-memory store (tests); the
  /// app passes [deviceIdeaRepository].
  final IdeaRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Idea> _ideas = [];
  final _title = TextEditingController();
  double _impact = 5;
  double _confidence = 5;
  double _ease = 5;
  bool _showArchived = false;
  String? _error;
  int _nextId = 1;

  late final IdeaRepository _repository =
      widget.repository ?? InMemoryListRepository<Idea>();
  bool _loading = true;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _repository.load();
      if (!mounted) return;
      setState(() {
        _ideas
          ..clear()
          ..addAll(saved);
        _nextId = saved.fold(0, (m, e) => e.id > m ? e.id : m) + 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _storageError = 'Saved ideas could not be read.';
      });
    }
  }

  Future<void> _persist() async {
    try {
      await _repository.save(List.of(_ideas));
      if (mounted && _storageError != null) {
        setState(() => _storageError = null);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _storageError = 'Could not save ideas on this device.');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _add() {
    final error = validateTitle(_title.text, _ideas);
    setState(() {
      _error = error;
      if (error != null) return;
      _ideas.add(
        Idea(
          id: _nextId++,
          title: _title.text,
          impact: _impact.round(),
          confidence: _confidence.round(),
          ease: _ease.round(),
        ),
      );
      _title.clear();
    });
    if (error == null) _persist();
  }

  void _replace(Idea idea, Idea updated) {
    setState(() => _ideas[_ideas.indexOf(idea)] = updated);
    _persist();
  }

  void _snack(SnackBar bar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(bar);
  }

  void _toggleArchive(Idea idea) {
    if (idea.archived && restoreWouldDuplicate(idea, _ideas)) {
      _snack(
        const SnackBar(
          content: Text('An active idea already has this title.'),
        ),
      );
      return;
    }
    _replace(idea, idea.copyWith(archived: !idea.archived));
  }

  void _delete(Idea idea) {
    final index = _ideas.indexOf(idea);
    setState(() => _ideas.remove(idea));
    _persist();
    _snack(
      SnackBar(
        content: Text('Deleted "${idea.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (!mounted || _ideas.contains(idea)) return;
            setState(() => _ideas.insert(index.clamp(0, _ideas.length), idea));
            _persist();
          },
        ),
      ),
    );
  }

  Future<void> _editScores(Idea idea) async {
    final updated = await showDialog<Idea>(
      context: context,
      builder: (_) => _ScoreDialog(idea: idea),
    );
    if (updated == null || !mounted || !_ideas.contains(idea)) return;
    _replace(idea, updated);
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text('$label ${value.round()}')),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${value.round()}',
            semanticFormatterCallback: (v) => '$label ${v.round()} of 10',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final list = ranked(_ideas, archived: _showArchived);
    final preview = _impact.round() * _confidence.round() * _ease.round();
    return Scaffold(
      appBar: AppBar(title: const Text('Ideas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_storageError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _storageError!,
                key: const Key('storage-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextField(
            key: const Key('title-input'),
            controller: _title,
            decoration: InputDecoration(
              labelText: 'New idea',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          _slider('Impact', _impact, (v) => setState(() => _impact = v)),
          _slider(
            'Confidence',
            _confidence,
            (v) => setState(() => _confidence = v),
          ),
          _slider('Ease', _ease, (v) => setState(() => _ease = v)),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text('ICE $preview · ${tierOf(preview)}'),
              FilledButton.icon(
                key: const Key('add-idea'),
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Active')),
              ButtonSegment(value: true, label: Text('Archived')),
            ],
            selected: {_showArchived},
            onSelectionChanged: (s) => setState(() => _showArchived = s.first),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _showArchived ? 'Nothing archived.' : 'No ideas yet.',
                textAlign: TextAlign.center,
              ),
            ),
          for (var i = 0; i < list.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${i + 1}', semanticsLabel: 'Rank ${i + 1}'),
                ),
                // Tap the idea to re-score it.
                onTap: () => _editScores(list[i]),
                title: Text(list[i].title, key: Key('rank-$i')),
                subtitle: Text(
                  'ICE ${list[i].iceScore} · ${tierOf(list[i].iceScore)} · '
                  'I${list[i].impact} C${list[i].confidence} E${list[i].ease}',
                  style: textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: list[i].archived
                          ? 'Restore ${list[i].title}'
                          : 'Archive ${list[i].title}',
                      icon: Icon(
                        list[i].archived ? Icons.unarchive : Icons.archive,
                      ),
                      onPressed: () => _toggleArchive(list[i]),
                    ),
                    IconButton(
                      tooltip: 'Delete ${list[i].title}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(list[i]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog({required this.idea});

  final Idea idea;

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  late int _impact = widget.idea.impact;
  late int _confidence = widget.idea.confidence;
  late int _ease = widget.idea.ease;

  Widget _slider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label $value'),
        Slider(
          key: Key('edit-${label.toLowerCase()}'),
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: '$value',
          semanticFormatterCallback: (v) => '$label ${v.round()} of 10',
          onChanged: (v) => setState(() => onChanged(v.round())),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _impact * _confidence * _ease;
    return AlertDialog(
      title: Text('Re-score "${widget.idea.title}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _slider('Impact', _impact, (v) => _impact = v),
            _slider('Confidence', _confidence, (v) => _confidence = v),
            _slider('Ease', _ease, (v) => _ease = v),
            Text('ICE $score · ${tierOf(score)}', key: const Key('edit-score')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-scores'),
          onPressed: () => Navigator.of(context).pop(
            widget.idea.copyWith(
              impact: _impact,
              confidence: _confidence,
              ease: _ease,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
