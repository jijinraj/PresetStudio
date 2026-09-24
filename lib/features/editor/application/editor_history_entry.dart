import '../domain/editor_session.dart';

enum EditorHistoryAction {
  original,
  adjustment,
  transform,
  crop,
  preset,
  reset,
  checkpoint,
}

class EditorHistoryEntry {
  const EditorHistoryEntry({
    required this.label,
    required this.action,
    required this.beforeSession,
    required this.session,
    this.isEnabled = true,
  });

  final String label;
  final EditorHistoryAction action;

  /// Editable state immediately before this history operation.
  ///
  /// Together with [session], this lets the controller replay only the fields
  /// changed by this operation when earlier entries are disabled.
  final EditorSession beforeSession;

  /// Editable state immediately after this history operation.
  final EditorSession session;

  /// Whether this operation currently contributes to the effective editor
  /// state. Original/checkpoint entries are baseline states and are not
  /// toggleable in the UI.
  final bool isEnabled;

  EditorHistoryEntry copyWith({
    String? label,
    EditorHistoryAction? action,
    EditorSession? beforeSession,
    EditorSession? session,
    bool? isEnabled,
  }) {
    return EditorHistoryEntry(
      label: label ?? this.label,
      action: action ?? this.action,
      beforeSession: beforeSession ?? this.beforeSession,
      session: session ?? this.session,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
