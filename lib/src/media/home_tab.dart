import 'package:flutter/widgets.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

/// One tab of the bottom navigation bar on the main menu: an identity, a pair
/// of icons and the body to show when it is selected. A tab backed by a
/// library of media items is a media source, which extends this.
abstract class HomeTab with ChangeNotifier {
  /// Initialise this home tab with the predetermined and hardset values.
  HomeTab({
    required this.uniqueKey,
    required this.icon,
    required this.outlinedIcon,
  });

  /// A unique name that allows distinguishing this type from others,
  /// particularly for the purposes of differentiating between persistent
  /// settings keys. This does not differ when the user's app language changes.
  final String uniqueKey;

  /// An icon that will represent this home tab when selected.
  final IconData icon;

  /// An icon that represents this home tab when unselected.
  final IconData outlinedIcon;

  /// The body that will be shown when this is the current selected home
  /// tab.
  Widget get home;

  /// The controller to be used for this home tab when it has
  /// enough media items to display that require the tab to be scrollable.
  ScrollController scrollController = ScrollController();

  /// The floating search bar controller for this home tab's page.
  final FloatingSearchBarController floatingSearchBarController =
      FloatingSearchBarController();

  /// Used to notify the home tab to refresh.
  final ChangeNotifier tabRefreshNotifier = ChangeNotifier();

  /// Use this to refresh a home tab's page on the main menu.
  void refreshTab() {
    tabRefreshNotifier.notifyListeners();
  }

  @override
  operator ==(Object other) =>
      other is HomeTab && other.uniqueKey == uniqueKey;

  @override
  int get hashCode => uniqueKey.hashCode;
}
