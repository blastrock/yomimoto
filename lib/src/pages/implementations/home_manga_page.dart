import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// The body content for the Manga tab in the main menu.
class HomeMangaPage extends BaseTabPage {
  /// Create an instance of this page.
  const HomeMangaPage({super.key});

  @override
  BaseTabPageState<BaseTabPage> createState() => _HomeMangaPageState();
}

class _HomeMangaPageState<T extends BaseTabPage> extends BaseTabPageState {
  @override
  MediaType get mediaType => MangaMediaType.instance;
}
