import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The words stashed while reading a book, in reading order. Long-press
/// selects items for deletion.
class StashPage extends BasePage {
  /// Create the page for [item]'s stash.
  const StashPage({
    required this.item,
    super.key,
  });

  /// The book whose stash is shown.
  final MediaItem item;

  @override
  BasePageState<StashPage> createState() => _StashPageState();
}

class _StashPageState extends BasePageState<StashPage> {
  List<StashItem> _items = [];
  final Set<int> _selected = {};

  bool get _isSelecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _items = appModelNoUpdate.getStashItems(widget.item);
  }

  void _reload() {
    if (!mounted) {
      return;
    }
    setState(() {
      _items = appModelNoUpdate.getStashItems(widget.item);
      _selected.removeWhere((id) => !_items.any((item) => item.id == id));
    });
  }

  void _toggle(StashItem item) {
    setState(() {
      if (!_selected.remove(item.id)) {
        _selected.add(item.id!);
      }
    });
  }

  Future<void> _open(StashItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StashItemPage(
          item: item,
          mediaItem: widget.item,
        ),
      ),
    );
    _reload();
  }

  Future<void> _deleteSelected() async {
    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(t.stash_delete_confirm(n: _selected.length)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  t.dialog_delete,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.dialog_cancel),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    appModelNoUpdate.deleteStashItems(_selected.toList());
    _selected.clear();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(_selected.clear);
        }
      },
      child: Scaffold(
        appBar: _isSelecting ? buildSelectionAppBar() : buildAppBar(),
        body: SafeArea(
          child: _items.isEmpty ? buildPlaceholder() : buildList(),
        ),
      ),
    );
  }

  /// The app bar outside selection mode.
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      titleSpacing: 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.stash),
          Text(
            widget.item.title,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// The app bar in selection mode.
  PreferredSizeWidget buildSelectionAppBar() {
    return AppBar(
      titleSpacing: 8,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: t.dialog_cancel,
        onPressed: () => setState(_selected.clear),
      ),
      title: Text(t.stash_selected(n: _selected.length)),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: t.stash_select_all,
          onPressed: () => setState(() {
            _selected.addAll(_items.map((item) => item.id!));
          }),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: t.dialog_delete,
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  /// Shown when the book has no stashed words.
  Widget buildPlaceholder() {
    return Center(
      child: JidoujishoPlaceholderMessage(
        icon: Icons.bookmark_border,
        message: t.stash_empty,
      ),
    );
  }

  /// The stashed words.
  Widget buildList() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) => buildTile(_items[index]),
    );
  }

  /// One stashed word: the term with its reading, and its meanings on one
  /// line.
  Widget buildTile(StashItem item) {
    bool isSelected = _selected.contains(item.id);
    bool showReading = item.reading.isNotEmpty && item.reading != item.term;

    return ListTile(
      selected: isSelected,
      leading: _isSelecting
          ? Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank)
          : null,
      title: Text(
        showReading ? '${item.term}【${item.reading}】' : item.term,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.definitions.join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _isSelecting ? _toggle(item) : _open(item),
      onLongPress: () => _toggle(item),
    );
  }
}
