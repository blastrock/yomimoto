import 'package:flutter/services.dart';

/// The e-ink panel's own full refresh, where the device has one.
///
/// On a Supernote, the framework's `android.os.EinkManager` (the `eink`
/// system service) asks its compositor for a full refresh. It is not in
/// the SDK, so `MainActivity` finds it by reflection; elsewhere it is
/// simply unavailable.
class EinkRefresh {
  EinkRefresh._privateConstructor();

  /// Get the singleton instance of this class.
  static EinkRefresh get instance => _instance;

  static final EinkRefresh _instance = EinkRefresh._privateConstructor();

  static const MethodChannel _channel =
      MethodChannel('app.arianneorpilla.yuuna/eink');

  Future<bool>? _available;

  /// Whether the device has the refresh. Asked once, then remembered.
  Future<bool> get isAvailable => _available ??= _askAvailable();

  Future<bool> _askAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isRefreshAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Make the next frame drawn a full refresh. Throws a
  /// [PlatformException] if the device refuses.
  Future<void> refreshNextFrame() =>
      _channel.invokeMethod<void>('refreshNextFrame');
}
