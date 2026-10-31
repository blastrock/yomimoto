import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

/// Run [task] behind a blocking progress dialog; on failure show the error
/// and return null.
Future<T?> runWithProgress<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() task,
}) async {
  NavigatorState navigator = Navigator.of(context);
  bool progressShown = true;
  unawaited(showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 24),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  ).then((_) => progressShown = false));

  try {
    return await task();
  } catch (error) {
    if (progressShown) {
      progressShown = false;
      navigator.pop();
    }
    await showDialog(
      context: navigator.context,
      builder: (context) => AlertDialog(
        title: Text(t.ttu_operation_failed),
        content: Text(error is TtuBridgeException ? error.message : '$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.dialog_close),
          ),
        ],
      ),
    );
    return null;
  } finally {
    if (progressShown) {
      progressShown = false;
      navigator.pop();
    }
  }
}
