import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The message telling the user why a catalog request failed with
/// [failure].
String catalogFailureMessage(CatalogFailure failure) {
  switch (failure) {
    case CatalogFailure.network:
      return t.manga_catalog_unreachable;
    case CatalogFailure.http:
      return t.manga_catalog_http_error;
    case CatalogFailure.unparseable:
      return t.manga_catalog_unexpected;
    case CatalogFailure.unsupported:
      return t.manga_catalog_unsupported;
    case CatalogFailure.noOcr:
      return t.manga_catalog_no_ocr;
  }
}

/// The series of a mokuro-bunko catalog, as a grid of covers in the
/// server's order, with a search over their titles. The list is fetched
/// each time the page is opened, and kept while pages are pushed over it.
class MangaCatalogPage extends BasePage {
  /// Create the page for the catalog at [catalogUrl].
  const MangaCatalogPage({
    required this.catalogUrl,
    super.key,
  });

  /// The catalog's base URL.
  final String catalogUrl;

  @override
  BasePageState<MangaCatalogPage> createState() => _MangaCatalogPageState();
}

class _MangaCatalogPageState extends BasePageState<MangaCatalogPage> {
  late final MokuroCatalogClient _client =
      MokuroCatalogClient(widget.catalogUrl);
  final TextEditingController _search = TextEditingController();

  List<CatalogSeries>? _series;
  CatalogFailure? _failure;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _series = null;
      _failure = null;
    });
    try {
      List<CatalogSeries> series = await _client.fetchLibrary();
      if (mounted) {
        setState(() => _series = series);
      }
    } on CatalogException catch (error) {
      debugPrint('catalog library: $error');
      if (mounted) {
        setState(() => _failure = error.failure);
      }
    }
  }

  void _stopSearching() {
    setState(() {
      _searching = false;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _stopSearching();
        }
      },
      child: Scaffold(
        appBar: _searching ? buildSearchBar() : buildAppBar(),
        body: SafeArea(child: buildBody()),
      ),
    );
  }

  /// The app bar showing the catalog's name.
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      titleSpacing: 8,
      title: Text(catalogHost(widget.catalogUrl)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: t.search,
          onPressed: () => setState(() => _searching = true),
        ),
      ],
    );
  }

  /// The app bar while searching: the search field.
  PreferredSizeWidget buildSearchBar() {
    return AppBar(
      titleSpacing: 8,
      title: TextField(
        controller: _search,
        autofocus: true,
        decoration: InputDecoration(
          hintText: t.manga_catalog_search_hint,
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: t.dialog_close,
          onPressed: _stopSearching,
        ),
      ],
    );
  }

  /// A spinner, the failure with a retry button, or the series.
  Widget buildBody() {
    CatalogFailure? failure = _failure;
    if (failure != null) {
      return buildFailure(failure);
    }
    List<CatalogSeries>? series = _series;
    if (series == null) {
      return const Center(child: CircularProgressIndicator());
    }

    List<CatalogSeries> shown =
        series.where((item) => item.matches(_search.text)).toList();
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: ReaderMokuroSource.instance.aspectRatio,
      ),
      itemCount: shown.length,
      itemBuilder: (context, index) => buildSeries(shown[index]),
    );
  }

  /// Why the series could not be shown, with a way to try again.
  Widget buildFailure(CatalogFailure failure) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(catalogFailureMessage(failure)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: Text(t.dialog_retry),
          ),
        ],
      ),
    );
  }

  /// One series' cover.
  Widget buildSeries(CatalogSeries series) {
    return MangaCatalogTile(
      coverUrl: _client.coverUri(series.cover).toString(),
      title: series.displayTitle,
      badge: series.tag,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MangaSeriesPage(
            catalogUrl: widget.catalogUrl,
            series: series,
          ),
        ),
      ),
    );
  }
}
