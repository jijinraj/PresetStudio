import '../domain/preset_record.dart';
import 'preset_remote_controller.dart';

enum PresetBrowseItemState {
  builtIn,
  local,
  remoteAvailable,
  remoteSaved,
  remoteUpdateAvailable,
}

class PresetBrowseCategory {
  const PresetBrowseCategory({
    required this.key,
    required this.label,
    required this.count,
  });

  static const String allKey = 'all';
  static const String savedKey = 'saved';

  final String key;
  final String label;
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetBrowseCategory &&
          key == other.key &&
          label == other.label &&
          count == other.count;

  @override
  int get hashCode => Object.hash(key, label, count);
}

class PresetBrowseItem {
  const PresetBrowseItem._({
    required this.key,
    required this.name,
    required this.state,
    required this.localRecord,
    required this.remoteItem,
  });

  factory PresetBrowseItem.local(PresetRecord record) {
    return PresetBrowseItem._(
      key: record.libraryId,
      name: record.preset.name,
      state: record.origin.type == PresetOriginType.builtIn
          ? PresetBrowseItemState.builtIn
          : PresetBrowseItemState.local,
      localRecord: record,
      remoteItem: null,
    );
  }

  factory PresetBrowseItem.remote({
    required RemotePresetCatalogItem item,
    PresetRecord? savedRecord,
  }) {
    final savedRevision = savedRecord?.origin.remoteRevision;
    final state = savedRevision == null
        ? PresetBrowseItemState.remoteAvailable
        : savedRevision < item.entry.revision
        ? PresetBrowseItemState.remoteUpdateAvailable
        : PresetBrowseItemState.remoteSaved;

    return PresetBrowseItem._(
      key: 'remote:${item.source.id}:${item.entry.id}',
      name: item.entry.name,
      state: state,
      localRecord: savedRecord,
      remoteItem: item,
    );
  }

  final String key;
  final String name;
  final PresetBrowseItemState state;
  final PresetRecord? localRecord;
  final RemotePresetCatalogItem? remoteItem;

  bool get isRemote => remoteItem != null;
  bool get isSaved => localRecord != null;
  bool get hasUpdate => state == PresetBrowseItemState.remoteUpdateAvailable;
}

class PresetBrowseSnapshot {
  PresetBrowseSnapshot({
    required Iterable<PresetRecord> records,
    required Iterable<RemotePresetCatalogItem> remoteItems,
  }) {
    final localRecords = List<PresetRecord>.unmodifiable(records);
    final catalogItems = List<RemotePresetCatalogItem>.unmodifiable(
      remoteItems,
    );
    final remoteRecords = <String, PresetRecord>{};

    for (final record in localRecords) {
      if (record.origin.type == PresetOriginType.remoteInstalled) {
        final sourceId = record.origin.sourceId;
        final remotePresetId = record.origin.remotePresetId;
        if (sourceId != null && remotePresetId != null) {
          remoteRecords[_remoteIdentity(sourceId, remotePresetId)] = record;
        }
      }
    }

    final catalogByIdentity = <String, RemotePresetCatalogItem>{
      for (final item in catalogItems)
        _remoteIdentity(item.source.id, item.entry.id): item,
    };

    discover = List<PresetBrowseItem>.unmodifiable(
      catalogItems.map(
        (item) => PresetBrowseItem.remote(
          item: item,
          savedRecord:
              remoteRecords[_remoteIdentity(item.source.id, item.entry.id)],
        ),
      ),
    );

    saved = List<PresetBrowseItem>.unmodifiable(
      localRecords.map((record) {
        if (record.origin.type == PresetOriginType.remoteInstalled) {
          final sourceId = record.origin.sourceId;
          final remotePresetId = record.origin.remotePresetId;
          if (sourceId != null && remotePresetId != null) {
            final remote =
                catalogByIdentity[_remoteIdentity(sourceId, remotePresetId)];
            if (remote != null) {
              return PresetBrowseItem.remote(item: remote, savedRecord: record);
            }
          }
        }
        return PresetBrowseItem.local(record);
      }),
    );

    final standalone = localRecords
        .where((record) {
          if (record.origin.type != PresetOriginType.remoteInstalled) {
            return true;
          }
          final sourceId = record.origin.sourceId;
          final remotePresetId = record.origin.remotePresetId;
          if (sourceId == null || remotePresetId == null) {
            return true;
          }
          return !catalogByIdentity.containsKey(
            _remoteIdentity(sourceId, remotePresetId),
          );
        })
        .map(PresetBrowseItem.local);

    all = List<PresetBrowseItem>.unmodifiable([...standalone, ...discover]);
    categories = _buildCategories(
      remoteItems: catalogItems,
      allCount: all.length,
      savedCount: saved.length,
    );
  }

  late final List<PresetBrowseItem> all;
  late final List<PresetBrowseItem> saved;
  late final List<PresetBrowseItem> discover;
  late final List<PresetBrowseCategory> categories;

  PresetBrowseItem? remoteItemFor({
    required String sourceId,
    required String remotePresetId,
  }) {
    final identity = _remoteIdentity(sourceId, remotePresetId);
    for (final item in discover) {
      final remote = item.remoteItem;
      if (remote != null &&
          _remoteIdentity(remote.source.id, remote.entry.id) == identity) {
        return item;
      }
    }
    return null;
  }

  static List<PresetBrowseCategory> _buildCategories({
    required List<RemotePresetCatalogItem> remoteItems,
    required int allCount,
    required int savedCount,
  }) {
    final counts = <String, int>{};
    final labels = <String, String>{};

    for (final item in remoteItems) {
      for (final tag in item.entry.tags) {
        final key = normalizeCategoryKey(tag);
        if (key.isEmpty ||
            key == PresetBrowseCategory.allKey ||
            key == PresetBrowseCategory.savedKey) {
          continue;
        }
        counts.update(key, (value) => value + 1, ifAbsent: () => 1);
        labels.putIfAbsent(key, () => humanizeCategoryLabel(tag));
      }
    }

    final tagKeys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0
            ? byCount
            : labels[a]!.toLowerCase().compareTo(labels[b]!.toLowerCase());
      });

    return List<PresetBrowseCategory>.unmodifiable([
      PresetBrowseCategory(
        key: PresetBrowseCategory.allKey,
        label: 'All',
        count: allCount,
      ),
      PresetBrowseCategory(
        key: PresetBrowseCategory.savedKey,
        label: 'Saved',
        count: savedCount,
      ),
      for (final key in tagKeys)
        PresetBrowseCategory(
          key: key,
          label: labels[key]!,
          count: counts[key]!,
        ),
    ]);
  }
}

String normalizeCategoryKey(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

String humanizeCategoryLabel(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[-_]+'), ' ');
  if (normalized.isEmpty) return normalized;
  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _remoteIdentity(String sourceId, String remotePresetId) =>
    '${sourceId.trim()}:${remotePresetId.trim()}';
