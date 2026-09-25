import 'dart:typed_data';

import 'export_render_plan.dart';

class ExportRenderResult {
  const ExportRenderResult({required this.bytes, required this.plan});

  final Uint8List bytes;
  final ExportRenderPlan plan;
}
