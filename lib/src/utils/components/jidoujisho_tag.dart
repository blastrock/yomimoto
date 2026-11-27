import 'package:flutter/material.dart';
import 'package:yuuna/utils.dart';

/// A tag that can be clicked on for more information. Used in dictionary
/// entries to indicate information about a definition or term.
class JidoujishoTag extends StatelessWidget {
  /// Create a tag that can be clicked on for more information.
  const JidoujishoTag({
    required this.text,
    required this.backgroundColor,
    this.message,
    this.trailingText,
    this.icon,
    this.foregroundColor = Colors.white,
    this.iconSize,
    this.style,
    super.key,
  });

  /// The icon to display on the tag.
  final IconData? icon;

  /// The text to display on the tag.
  final String text;

  /// The message to show when the tag has been clicked on.
  final String? message;

  /// An extra bit to put on a rectangle on the right of the message.
  final String? trailingText;

  /// The color of the tag background.
  final Color backgroundColor;

  /// The color of the icon and text.
  final Color foregroundColor;

  /// The display size for the [icon].
  final double? iconSize;

  /// Text style to use for the [text] of the tag.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    AppColors appColors = Theme.of(context).appColors;
    Color background = appColors.chipBackground ?? backgroundColor;
    Color foreground = appColors.chipForeground ?? foregroundColor;

    return Padding(
      padding: const EdgeInsets.only(right: Spacing.small),
      child: InkWell(
        onTap: message != null
            ? () {
                showToast(
                  msg: message!,
                );
              }
            : null,
        child: Container(
          color: background,
          padding: const EdgeInsets.all(Spacing.small),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: foreground,
                  size: Theme.of(context).textTheme.labelSmall?.fontSize,
                ),
              if (icon != null) const SizedBox(width: Spacing.small),
              Flexible(
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingText != null) const SizedBox(width: Spacing.small),
              if (trailingText != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.extraSmall),
                    color: appColors.nestedChipBackground,
                    child: Text(
                      trailingText!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: appColors.nestedChipForeground ?? foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
