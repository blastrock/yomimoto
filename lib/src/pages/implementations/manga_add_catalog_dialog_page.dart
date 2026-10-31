import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The popup asking for a mokuro-bunko catalog's address. It checks that a
/// catalog answers there before adding it, and pops with the normalised
/// address, or null when cancelled.
class MangaAddCatalogDialogPage extends BasePage {
  /// Create an instance of this page.
  const MangaAddCatalogDialogPage({super.key});

  @override
  BasePageState<MangaAddCatalogDialogPage> createState() =>
      _MangaAddCatalogDialogPageState();
}

class _MangaAddCatalogDialogPageState
    extends BasePageState<MangaAddCatalogDialogPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.manga_add_catalog),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        autocorrect: false,
        decoration: InputDecoration(hintText: t.manga_catalog_url_hint),
        onSubmitted: (_) => _add(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.dialog_cancel),
        ),
        TextButton(
          onPressed: _add,
          child: Text(t.dialog_add),
        ),
      ],
    );
  }

  Future<void> _add() async {
    ReaderMokuroSource source = ReaderMokuroSource.instance;
    String? url = normaliseCatalogUrl(_controller.text);
    if (url == null) {
      showToast(msg: t.manga_catalog_invalid_url);
      return;
    }
    if (source.catalogs.contains(url)) {
      Navigator.pop(context, url);
      return;
    }

    bool found = await runWithProgress<bool>(
          context: context,
          message: t.manga_catalog_checking,
          task: () async {
            MokuroCatalogClient client = MokuroCatalogClient(url);
            try {
              await client.fetchLibrary();
              return true;
            } on CatalogException catch (error) {
              debugPrint('catalog check: $error');
              return false;
            } finally {
              client.close();
            }
          },
        ) ??
        false;
    if (!found) {
      showToast(msg: t.manga_catalog_not_found);
      return;
    }

    await source.addCatalog(url);
    if (mounted) {
      Navigator.pop(context, url);
    }
  }
}
