import '../domain/preset_source.dart';

abstract final class PresetDefaultSources {
  static final PresetRemoteSource presetStudio = PresetRemoteSource(
    id: 'presetstudio-default',
    name: 'PresetStudio Presets',
    kind: PresetSourceKind.repository,
    location: 'https://github.com/jijinraj/presetstudio-presets',
  );

  static List<PresetRemoteSource> get all => <PresetRemoteSource>[presetStudio];
}
