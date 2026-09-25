import 'dart:isolate';
import 'dart:typed_data';

import '../domain/editor_session.dart';
import '../domain/export_render_result.dart';
import 'export_image_renderer.dart';

/// Runs the CPU-heavy full-resolution export renderer outside the UI isolate.
///
/// Keeping the isolate closure in this top-level rendering library is
/// intentional. Dart isolate closures can capture more state than their source
/// text appears to reference. Calling [Isolate.run] directly inside a State
/// method can therefore accidentally pull unsendable Flutter state into the
/// isolate message. This helper limits the closure's reachable state to the
/// plain export task data.
Future<ExportRenderResult> renderExportInBackground({
  required Uint8List sourceBytes,
  required EditorSession session,
}) {
  final task = _ExportRenderTask(sourceBytes: sourceBytes, session: session);

  return Isolate.run(() => _renderExportTask(task));
}

ExportRenderResult _renderExportTask(_ExportRenderTask task) {
  return const ExportImageRenderer().render(
    sourceBytes: task.sourceBytes,
    session: task.session,
  );
}

class _ExportRenderTask {
  const _ExportRenderTask({required this.sourceBytes, required this.session});

  final Uint8List sourceBytes;
  final EditorSession session;
}
