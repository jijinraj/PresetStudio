import '../domain/editor_session.dart';

enum EditorHistoryAction {
  original,
  adjustment,
  transform,
  crop,
  preset,
  reset,
}

class EditorHistoryEntry {
  const EditorHistoryEntry({
    required this.label,
    required this.action,
    required this.session,
  });

  final String label;
  final EditorHistoryAction action;
  final EditorSession session;
}
