import 'package:flutter/material.dart';
import 'package:yuuna/utils.dart';

/// The manga reader's bar: page turning buttons, a slider over the whole
/// volume and the page number. Everything runs right to left like the
/// pages: the next page is on the left, the first page at the slider's right
/// end.
class MokuroReaderBar extends StatefulWidget {
  /// Create the bar for a volume of [count] pages showing [firstShown] to
  /// [lastShown].
  const MokuroReaderBar({
    required this.firstShown,
    required this.lastShown,
    required this.count,
    required this.onHide,
    required this.onNext,
    required this.onPrevious,
    required this.onGoTo,
    super.key,
  });

  /// The lowest page shown.
  final int firstShown;

  /// The highest page shown: the same as [firstShown] unless a spread is
  /// shown.
  final int lastShown;

  /// How many pages the volume has.
  final int count;

  /// Hides the bar.
  final VoidCallback onHide;

  /// Shows the next pages in reading order.
  final VoidCallback onNext;

  /// Shows the previous pages in reading order.
  final VoidCallback onPrevious;

  /// Shows the given page, once the slider is let go.
  final ValueChanged<int> onGoTo;

  @override
  State<MokuroReaderBar> createState() => _MokuroReaderBarState();
}

class _MokuroReaderBarState extends State<MokuroReaderBar> {
  /// Where the slider is while it is dragged, null otherwise.
  double? _dragged;

  String get _label {
    int? dragged = _dragged?.round();
    if (dragged != null) {
      return '${dragged + 1} / ${widget.count}';
    }
    if (widget.firstShown == widget.lastShown) {
      return '${widget.firstShown + 1} / ${widget.count}';
    }
    return '${widget.firstShown + 1}–${widget.lastShown + 1} / '
        '${widget.count}';
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    int last = widget.count - 1;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: t.manga_hide_bar,
              onPressed: widget.onHide,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: t.manga_next_page,
              onPressed: widget.onNext,
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Slider(
                  value: (_dragged ?? widget.firstShown.toDouble())
                      .clamp(0, last.toDouble()),
                  max: last > 0 ? last.toDouble() : 1,
                  divisions: last > 0 ? last : null,
                  onChanged: last > 0
                      ? (value) => setState(() => _dragged = value)
                      : null,
                  onChangeEnd: (value) {
                    setState(() => _dragged = null);
                    widget.onGoTo(value.round());
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: t.manga_previous_page,
              onPressed: widget.onPrevious,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(_label, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
