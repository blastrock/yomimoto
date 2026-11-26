import 'package:yuuna/creator.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// The app-wide settings. Each reader source declares its own next to the
/// getters that use them.
abstract final class Preferences {
  // App.

  /// Whether the app is light, dark, e-ink or follows the system.
  static const EnumPreference<AppThemeMode> themeMode = EnumPreference(
      'theme_mode', AppThemeMode.values,
      defaultValue: AppThemeMode.system);

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

  /// The font size of dictionary meanings.
  static const Preference<double> dictionaryFontSize =
      Preference('dictionary_entry_font_size', defaultValue: 16);

  /// The `uniqueKey` of the format dictionaries are imported as.
  static const Preference<String> lastSelectedDictionaryFormat =
      Preference('last_selected_dictionary_format', defaultValue: 'yomichan');

  /// The maximum number of terms in a search result.
  static const Preference<int> maximumTerms =
      Preference('maximum_terms', defaultValue: 10);

  // Card creation.

  /// The id of the card creation profile in use.
  static const Preference<int> selectedMappingId = Preference(
      'selected_mapping_id',
      defaultValue: AnkiMapping.standardProfileId);

  /// The AnkiDroid note type last picked for a new profile, if any.
  static const Preference<String?> lastSelectedModel =
      Preference('last_selected_model', defaultValue: null);

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

  // Sentence explanation.

  /// The Anthropic API key sentence explanations are requested with; empty
  /// while unset.
  static const Preference<String> explanationApiKey =
      Preference('explanation_api_key', defaultValue: '');

  /// The `name` of the [ExplanationPreset] explanations use.
  static const Preference<String> explanationPreset =
      Preference('explanation_preset', defaultValue: 'sonnet');
}
