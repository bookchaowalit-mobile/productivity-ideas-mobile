import 'package:flutter/material.dart';

import '../logic/ice.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  }

  void _replace(Idea idea, Idea updated) =>
      setState(() => _ideas[_ideas.indexOf(idea)] = updated);

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
          Row(
            children: [
              Text('ICE $preview · ${tierOf(preview)}'),
              const Spacer(),
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
                leading: CircleAvatar(child: Text('${i + 1}')),
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
                      onPressed: () => _replace(
                        list[i],
                        list[i].copyWith(archived: !list[i].archived),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete ${list[i].title}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _ideas.remove(list[i])),
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
