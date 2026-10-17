import 'package:yuuna/creator.dart';
import 'package:yuuna/preferences.dart';

/// The app-wide settings. Each reader source declares its own next to the
/// getters that use them.
abstract final class Preferences {
  // App.

  /// The index of the home tab shown, in the order of `AppModel.tabs`.
  static const Preference<int> currentHomeTabIndex =
      Preference('current_home_tab_index', defaultValue: 0);

  /// Whether the first-launch explanation of the permission requests has yet
  /// to be shown.
  static const Preference<bool> firstTimeSetup =
      Preference('first_time_setup', defaultValue: true);

  // Dictionary search.

  /// Whether typing searches without pressing the submit button.
  static const Preference<bool> autoSearch =
      Preference('auto_search', defaultValue: true);

  /// The delay in milliseconds between typing and an automatic search.
  static const Preference<int> searchDebounceDelay =
      Preference('auto_search_debounce_delay', defaultValue: 100);

  /// The font size of dictionary meanings.
  static const Preference<double> dictionaryFontSize =
      Preference('dictionary_entry_font_size', defaultValue: 16);

  /// The maximum number of terms in a search result.
  static const Preference<int> maximumTerms =
      Preference('maximum_terms', defaultValue: 10);

  // Card creation.

  /// The AnkiDroid deck cards are exported to.
  static const Preference<String> lastSelectedDeck =
      Preference('last_selected_deck', defaultValue: 'Default');

  /// Whether the creator closes after exporting a card.
  static const Preference<bool> closeCreatorOnExport =
      Preference('close_on_export', defaultValue: false);

  /// The tags saved for the tags field.
  static const Preference<String> savedTags =
      Preference('saved_tags', defaultValue: '');

  /// The AnkiDroid note types checked for duplicates.
  static const StringListPreference duplicateCheckModels =
      StringListPreference('duplicate_check_models',
          defaultValue: [AnkiMapping.standardModelName]);
}
