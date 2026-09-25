import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/application/editor_history_entry.dart';
import 'package:presetstudio/features/editor/domain/crop_state.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/application/preset_library_store.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/application/preset_library_controller.dart';
import 'package:presetstudio/features/presets/presentation/widgets/preset_library_view.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  late PresetLibraryController libraryController;
  late EditorController editorController;

  setUp(() async {
    final store = _MemoryPresetLibraryStore();
    libraryController = PresetLibraryController(
      idGenerator: () => 'ui-local-preset',
      clock: () => DateTime.utc(2026, 9, 25, 16),
      libraryLoader: () async {
        return PresetLibrary(
          store: store,
          clock: () => DateTime.utc(2026, 9, 25, 16),
        );
      },
    );
    editorController = EditorController();
    await libraryController.initialize();
  });

  tearDown(() {
    libraryController.dispose();
    editorController.dispose();
  });

  testWidgets(
    'applies a preset as one history operation without changing geometry',
    (tester) async {
      final record = await libraryController.saveCurrent(
        name: 'Warm Film',
        adjustments: const ImageAdjustments(
          exposure: 0.6,
          contrast: 18,
          temperature: 14,
          vibrance: 20,
        ),
      );

      editorController.setSourceImage('photo.jpg');
      const crop = CropState(
        normalizedRect: NormalizedCropRect(
          left: 0.1,
          top: 0.2,
          right: 0.9,
          bottom: 0.8,
        ),
        straightenDegrees: 2,
        scale: 1.4,
        offset: NormalizedCropOffset(dx: 0.1, dy: -0.08),
      );
      const transform = ImageTransform(
        rotationDegrees: 90,
        flipHorizontal: true,
      );
      editorController.updateCrop(crop);
      editorController.updateTransform(transform);
      final historyBeforeApply = editorController.history.length;

      await tester.pumpWidget(
        _testApp(
          libraryController: libraryController,
          editorController: editorController,
        ),
      );

      await tester.tap(
        find.byKey(ValueKey('preset-apply-${record.libraryId}')),
      );
      await tester.pump();

      expect(editorController.session.adjustments.exposure, 0.6);
      expect(editorController.session.adjustments.temperature, 14);
      expect(editorController.session.crop, crop);
      expect(
        editorController.session.transform.normalizedRotationDegrees,
        transform.normalizedRotationDegrees,
      );
      expect(
        editorController.session.transform.flipHorizontal,
        transform.flipHorizontal,
      );
      expect(
        editorController.session.transform.flipVertical,
        transform.flipVertical,
      );
      expect(editorController.session.activePresetId, record.libraryId);
      expect(editorController.history, hasLength(historyBeforeApply + 1));
      expect(
        editorController.currentHistoryEntry?.action,
        EditorHistoryAction.preset,
      );
      expect(editorController.currentHistoryEntry?.label, 'Preset: Warm Film');

      editorController.undo();
      expect(editorController.session.adjustments.exposure, 0);
      expect(editorController.session.adjustments.contrast, 0);
      expect(editorController.session.adjustments.temperature, 0);
      expect(editorController.session.adjustments.vibrance, 0);
      expect(editorController.session.crop, crop);
      expect(
        editorController.session.transform.normalizedRotationDegrees,
        transform.normalizedRotationDegrees,
      );
      expect(
        editorController.session.transform.flipHorizontal,
        transform.flipHorizontal,
      );
      expect(
        editorController.session.transform.flipVertical,
        transform.flipVertical,
      );

      editorController.redo();
      expect(editorController.session.adjustments.exposure, 0.6);
      expect(editorController.session.activePresetId, record.libraryId);

      await _drainPresetFeedback(tester);
    },
  );

  testWidgets('save, rename, and delete are available from My Presets', (
    tester,
  ) async {
    editorController.setSourceImage('photo.jpg');
    editorController.updateAdjustments(
      const ImageAdjustments(contrast: 24, saturation: -8),
    );

    await tester.pumpWidget(
      _testApp(
        libraryController: libraryController,
        editorController: editorController,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('preset-save-current')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preset-save-name')),
      'My Look',
    );
    await tester.enterText(
      find.byKey(const ValueKey('preset-save-description')),
      'A local test preset',
    );
    await tester.tap(find.byKey(const ValueKey('preset-save-confirm')));
    await tester.pumpAndSettle();

    expect(libraryController.records, hasLength(1));
    final record = libraryController.records.single;
    expect(record.preset.name, 'My Look');
    expect(record.preset.adjustments.contrast, 24);
    expect(record.preset.adjustments.saturation, -8);

    await tester.tap(find.byKey(ValueKey('preset-menu-${record.libraryId}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preset-rename-name')),
      'My Look Renamed',
    );
    await tester.tap(find.byKey(const ValueKey('preset-rename-confirm')));
    await tester.pumpAndSettle();

    expect(libraryController.records.single.preset.name, 'My Look Renamed');

    await tester.tap(find.byKey(ValueKey('preset-menu-${record.libraryId}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-delete-confirm')));
    await tester.pumpAndSettle();

    expect(libraryController.records, isEmpty);

    await _drainPresetFeedback(tester);
  });
}

Future<void> _drainPresetFeedback(WidgetTester tester) async {
  // Preset actions show a SnackBar with the Material default duration.
  // Advance fake test time so the SnackBar timer cannot remain pending
  // after the widget test body completes.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

class _MemoryPresetLibraryStore implements PresetLibraryStore {
  final Map<String, PresetRecord> _records = <String, PresetRecord>{};

  @override
  Future<List<PresetRecord>> loadRecords() async {
    return List<PresetRecord>.unmodifiable(_records.values);
  }

  @override
  Future<void> upsertRecord(PresetRecord record) async {
    _records[record.libraryId] = record;
  }

  @override
  Future<void> deleteRecord(String libraryId) async {
    _records.remove(libraryId);
  }
}

Widget _testApp({
  required PresetLibraryController libraryController,
  required EditorController editorController,
}) {
  return MaterialApp(
    theme: PresetStudioTheme.dark,
    home: Scaffold(
      body: SizedBox(
        width: 420,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PresetLibraryView(
            libraryController: libraryController,
            editorController: editorController,
          ),
        ),
      ),
    ),
  );
}
