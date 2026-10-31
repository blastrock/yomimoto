import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The popup the Manga tab's add button opens: the catalogs to download a
/// volume from, adding and removing catalogs, and importing a file.
class MangaAddVolumeDialogPage extends BasePage {
  /// Create an instance of this page.
  const MangaAddVolumeDialogPage({super.key});

  @override
  BasePageState<MangaAddVolumeDialogPage> createState() =>
      _MangaAddVolumeDialogPageState();
}

class _MangaAddVolumeDialogPageState
    extends BasePageState<MangaAddVolumeDialogPage> {
  ReaderMokuroSource get _source => ReaderMokuroSource.instance;

  @override
  Widget build(BuildContext context) {
    List<String> catalogs = _source.catalogs;
    return AlertDialog(
      title: Text(t.manga_add_volume),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (catalogs.isEmpty)
              ListTile(
                title: Text(
                  t.manga_catalogs_empty,
                  style: TextStyle(color: theme.unselectedWidgetColor),
                ),
              ),
            for (String url in catalogs) _buildCatalog(url),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(t.manga_add_catalog),
              onTap: _addCatalog,
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: Text(t.manga_import_file),
              onTap: _importFile,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.dialog_close),
        ),
      ],
    );
  }

  Widget _buildCatalog(String url) {
    return ListTile(
      leading: const Icon(Icons.public),
      title: Text(catalogHost(url)),
      onTap: () => _openCatalog(url),
      trailing: IconButton(
        tooltip: t.manga_catalog_remove,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _removeCatalog(url),
      ),
    );
  }

  void _openCatalog(String url) {
    NavigatorState navigator = Navigator.of(context);
    navigator.pop();
    unawaited(navigator.push(MaterialPageRoute<void>(
      builder: (_) => MangaCatalogPage(catalogUrl: url),
    )));
  }

  Future<void> _removeCatalog(String url) async {
    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(
                t.manga_catalog_remove_confirm(host: catalogHost(url))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  t.dialog_remove,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
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

    await _source.removeCatalog(url);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addCatalog() async {
    await showDialog<String>(
      context: context,
      builder: (_) => const MangaAddCatalogDialogPage(),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _importFile() async {
    NavigatorState navigator = Navigator.of(context);
    navigator.pop();
    await _source.importVolume(
      context: navigator.context,
      appModel: appModelNoUpdate,
    );
  }
}
