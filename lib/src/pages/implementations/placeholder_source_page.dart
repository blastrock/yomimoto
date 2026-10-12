import 'package:flutter/material.dart';
import 'package:yuuna/src/pages/base_source_page.dart';
import 'package:yuuna/utils.dart';

/// The media page used for unimplemented sources.
class PlaceholderSourcePage extends BaseSourcePage {
  /// Create an instance of this page.
  const PlaceholderSourcePage({
    super.item,
    super.key,
  });

  @override
  BaseSourcePageState createState() => _PlaceholderSourcePage();
}

class _PlaceholderSourcePage extends BaseSourcePageState {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // PopScope inverts WillPopScope: refuse the pop up front, run the
      // same confirmation, and pop by hand if it is accepted.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (await onWillPop() && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        body: Center(
          child: buildPlaceholder(),
        ),
      ),
    );
  }

  Widget buildPlaceholder() {
    return JidoujishoPlaceholderMessage(
      icon: Icons.construction,
      message: t.unimplemented_source,
    );
  }
}
