import 'dart:async';

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('app.arianneorpilla.yuuna/toast');

/// Show [msg] in an Android toast, for a long time if [long], without waiting
/// for it. Being native, the toast shows above dialogs too.
void showToast({
  required String msg,
  bool long = false,
}) {
  unawaited(_channel.invokeMethod<void>(
    'showToast',
    <String, dynamic>{'message': msg, 'long': long},
  ));
}
