import 'preset_browse_model.dart';

class PresetBrowseQuery {
  const PresetBrowseQuery({
    this.searchText = '',
    this.categoryKey = PresetBrowseCategory.allKey,
  });

  final String searchText;
  final String categoryKey;

  PresetBrowseQuery copyWith({String? searchText, String? categoryKey}) {
    return PresetBrowseQuery(
      searchText: searchText ?? this.searchText,
      categoryKey: categoryKey ?? this.categoryKey,
    );
  }

  List<PresetBrowseItem> apply(PresetBrowseSnapshot snapshot) {
    final normalizedCategory = normalizeCategoryKey(categoryKey);
    final source = normalizedCategory == PresetBrowseCategory.savedKey
        ? snapshot.saved
        : snapshot.all;
    final searchTerms = _searchTerms(searchText);

    return List<PresetBrowseItem>.unmodifiable(
      source.where((item) {
        if (!_matchesCategory(item, normalizedCategory)) {
          return false;
        }

        return _matchesSearch(item, searchTerms);
      }),
    );
  }

  bool _matchesCategory(PresetBrowseItem item, String category) {
    if (category.isEmpty || category == PresetBrowseCategory.allKey) {
      return true;
    }

    if (category == PresetBrowseCategory.savedKey) {
      return item.isSaved;
    }

    final remote = item.remoteItem;
    if (remote == null) {
      return false;
    }

    return remote.entry.tags.any(
      (tag) => normalizeCategoryKey(tag) == category,
    );
  }

  bool _matchesSearch(PresetBrowseItem item, List<String> terms) {
    if (terms.isEmpty) {
      return true;
    }

    final remote = item.remoteItem;
    final record = item.localRecord;
    final searchable = <String>[
      item.name,
      if (remote != null) ...[
        remote.entry.id,
        remote.entry.author ?? '',
        remote.entry.description ?? '',
        remote.source.name,
        ...remote.entry.tags,
      ] else if (record != null) ...[
        record.preset.id,
        record.preset.author ?? '',
        record.preset.description ?? '',
      ],
    ].join(' ').toLowerCase();

    return terms.every(searchable.contains);
  }
}

List<String> _searchTerms(String value) {
  return value
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
}
