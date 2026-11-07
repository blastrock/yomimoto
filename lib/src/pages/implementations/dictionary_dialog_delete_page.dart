import 'package:flutter/material.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The content of the dialog used for showing dictionary import progress when
/// deleting a dictionary from the dictionary menu. See the
/// [DictionaryDialogPage].
class DictionaryDialogDeletePage extends BasePage {
  /// Create an instance of this page.
  const DictionaryDialogDeletePage({
    this.name,
    super.key,
  });

  /// Name of current dictionary being deleted.
  final String? name;

  @override
  BasePageState createState() => _DictionaryDialogDeletePageState();
}

class _DictionaryDialogDeletePageState
    extends BasePageState<DictionaryDialogDeletePage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(Spacing.big),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildProgressSpinner(),
            const SizedBox(width: Spacing.semiBig),
            buildProgressMessage(),
          ],
        ),
      ),
    );
  }

  Widget buildProgressSpinner() {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        theme.colorScheme.primary,
      ),
    );
  }

  Widget buildProgressMessage() {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Spacing.extraSmall),
          Padding(
            padding: const EdgeInsets.only(left: 0.5),
            child: Text(
              widget.name != null
                  ? '${t.delete_in_progress}\n${widget.name}'
                  : t.delete_in_progress,
              style: TextStyle(
                fontSize: textTheme.bodySmall?.fontSize,
                color: theme.unselectedWidgetColor,
              ),
            ),
          ),
          const SizedBox(height: Spacing.small),
          Text(
            t.dictionaries_deleting_data,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
