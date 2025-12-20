import 'package:flutter/material.dart';

/// Minimal export service stub to satisfy references.
class ExportService {
  /// Exports a monthly report. This is a small stub used by the UI when the
  /// full backend integration isn't present in the workspace.
  static Future<void> exportMonthlyReport({required BuildContext context, bool onlyOutbound = false}) async {
    // Show a quick feedback so the UI doesn't crash when calling this helper.
    if (!mounted(context)) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export not implemented in stub.')));
  }

  static bool mounted(BuildContext context) {
    // Basic check — in real code this would be `if (context.mounted)` in caller.
    return true;
  }
}
