import '../logic/ice.dart';
import 'list_repository.dart';

typedef IdeaRepository = ListRepository<Idea>;

/// Device storage for ideas (shared_preferences, JSON).
const IdeaRepository deviceIdeaRepository =
    SharedPreferencesListRepository<Idea>(
  storageKey: 'ideas_ideas_v1',
  fromJson: Idea.fromJson,
  toJson: ideaToJson,
);
