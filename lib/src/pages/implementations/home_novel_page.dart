import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// The body content for the Novels tab in the main menu.
class HomeNovelPage extends BaseTabPage {
  /// Create an instance of this page.
  const HomeNovelPage({super.key});

  @override
  BaseTabPageState<BaseTabPage> createState() => _HomeNovelPageState();
}

class _HomeNovelPageState<T extends BaseTabPage> extends BaseTabPageState {
  @override
  MediaType get mediaType => NovelMediaType.instance;
}
