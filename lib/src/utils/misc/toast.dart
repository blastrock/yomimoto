import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Show a toast without waiting for it. [Fluttertoast.showToast] returns a
/// [Future] that is never worth awaiting, so every toast goes through here.
void showToast({
  required String msg,
  Toast? toastLength,
  ToastGravity? gravity,
  Color? backgroundColor,
  Color? textColor,
}) {
  unawaited(Fluttertoast.showToast(
    msg: msg,
    toastLength: toastLength,
    gravity: gravity,
    backgroundColor: backgroundColor,
    textColor: textColor,
  ));
}
