/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 1
/// Strings: 216

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	String get reader_ttu => 'Novels';
	String get reader_mokuro => 'Manga';
	String get dictionary => 'Dictionary';
	String get back => 'Back';
	String get search => 'Search';
	String get search_ellipsis => 'Search...';
	String get show_more => 'Show More';
	String get pick_image => 'Pick Image';
	String get undo => 'Undo';
	String get copy => 'Copy';
	String get clear => 'Clear';
	String get creator => 'Creator';
	String get share => 'Share';
	String get resume_last_media => 'Resume Last Media';
	String get card_creator => 'Card Creator';
	String get show_options => 'Show Options';
	String get switch_profiles => 'Switch Profiles';
	String get dictionaries => 'Dictionaries';
	String get enhancements => 'Enhancements';
	String get dialog_read => 'READ';
	String get dialog_edit => 'EDIT';
	String get dialog_import => 'IMPORT';
	String get dialog_close => 'CLOSE';
	String get dialog_clear => 'CLEAR';
	String get dialog_create => 'CREATE';
	String get dialog_delete => 'DELETE';
	String get dialog_cancel => 'CANCEL';
	String get dialog_select => 'SELECT';
	String get dialog_search => 'SEARCH';
	String get dialog_exit => 'EXIT';
	String get dialog_save => 'SAVE';
	String get dialog_crop => 'CROP';
	String get dialog_append => 'APPEND';
	String get dialog_record => 'RECORD';
	String get dialog_manage => 'MANAGE';
	String get dialog_stop => 'STOP';
	String get dialog_done => 'DONE';
	String get reset => 'Reset';
	String get dialog_launch_ankidroid => 'LAUNCH ANKIDROID';
	String get mappings_delete_confirmation => 'This profile will be deleted. Are you sure you want to do this?';
	String get catalog_delete_confirmation => 'This catalog will be deleted. Are you sure you want to do this?';
	String get dictionaries_deleting_data => 'Deleting dictionary data...';
	String get dictionaries_menu_empty => 'Import a dictionary for use';
	String get options_dictionaries => 'Manage dictionaries';
	String get options_profiles => 'Export profiles';
	String get options_enhancements => 'User enhancements';
	String get options_github => 'View repository on GitHub';
	String get options_attribution => 'Licenses and attribution';
	String get options_copy => 'Copy';
	String get options_collapse => 'Collapse';
	String get options_expand => 'Expand';
	String get options_delete => 'Delete';
	String get options_show => 'Show';
	String get options_hide => 'Hide';
	String get options_edit => 'Edit';
	String get info_empty_home_tab => 'History is empty';
	String get delete_in_progress => 'Delete in progress';
	String get import_format => 'Import format';
	String get import_in_progress => 'Import in progress';
	String get import_start => 'Preparing for import...';
	String import_extract_count({required Object n}) => 'Extracted ${n} files...';
	String get import_extract => 'Extracting files...';
	String import_name({required Object name}) => 'Importing 『${name}』...';
	String import_found_entry({required Object count}) => 'Found ${count} entries...';
	String import_found_tag({required Object count}) => 'Found ${count} tags...';
	String import_found_frequency({required Object count}) => 'Found ${count} frequency entries...';
	String import_found_pitch({required Object count}) => 'Found ${count} pitch accent entries...';
	String import_write_entry({required Object count, required Object total}) => 'Writing entries:\n${count} / ${total}';
	String import_write_tag({required Object count, required Object total}) => 'Writing tags:\n${count} / ${total}';
	String import_write_frequency({required Object count, required Object total}) => 'Writing frequency entries:\n${count} / ${total}';
	String import_write_pitch({required Object count, required Object total}) => 'Writing pitch accent entries:\n${count} / ${total}';
	String get import_failed => 'Dictionary import failed.';
	String get import_complete => 'Dictionary import complete.';
	String import_duplicate({required Object name}) => 'A dictionary with the name『${name}』is already imported.';
	String get dialog_title_dictionary_clear => 'Clear all dictionaries?';
	String get dialog_content_dictionary_clear => 'Wiping the dictionary database will also clear all search results in history.';
	String dialog_title_dictionary_delete({required Object name}) => 'Delete 『${name}』?';
	String get dialog_content_dictionary_delete => 'Deleting a single dictionary may take longer than clearing the entire dictionary database. This will also clear all search results in history.';
	String get legalese => '読本 — a Japanese book reader, dictionary and card creation toolkit for e-ink devices, by Philippe Daouadi.\n\nYomimoto is a fork of jidoujisho, originally built for the Japanese language learning community by Arianne Orpilla. Logo by suzy and Aaron Marbella.\n\nYomimoto is free and open source software. See the project repository for a comprehensive list of other licenses and attribution notices.';
	String get field_label_empty => 'Empty';
	String get model_to_map => 'Card type to use for new profile';
	String get mapping_name => 'Profile name';
	String get mapping_name_hint => 'Name to assign to profile';
	String get error_profile_name => 'Invalid profile name';
	String get error_profile_name_content => 'A profile with this name already exists or is not valid and cannot be saved.';
	String get error_standard_profile_name => 'Invalid profile name';
	String get error_standard_profile_name_content => 'Cannot rename the standard profile.';
	String get error_ankidroid_api => 'AnkiDroid error';
	String get error_ankidroid_api_content => 'There was an issue communicating with AnkiDroid.\n\nEnsure that the AnkiDroid background service is active and all relevant app permissions are granted in order to continue.';
	String get info_standard_model => 'Standard card type added';
	String get info_standard_model_content => '『Yomimoto』 has been added to AnkiDroid as a new card type.\n\nSetups making use of a different card type or field order may be used by adding a new export profile.';
	String get error_model_missing => 'Missing card type';
	String get error_model_missing_content => 'The corresponding card type of the currently selected profile is missing.\n\nThe profile will be deleted, and the standard profile has now been selected in its place.';
	String get error_model_changed => 'Card type changed';
	String get error_model_changed_content => 'The number of fields of the card type corresponding to the selected profile has changed.\n\nThe fields of the currently selected profile have been reset and will require reconfiguration.';
	String get creator_exporting_as => 'Creating card with profile';
	String get creator_exporting_as_fields_editing => 'Editing fields for profile';
	String get creator_exporting_as_enhancements_editing => 'Editing enhancements for profile';
	String get creator_export_card => 'Create Card';
	String get info_enhancements => 'Enhancements enable the automation of field editing prior to card creation. Pick a slot on the right of a field to allow use of an enhancement. Up to five right slots may be utilised for each field. The enhancement in the left slot of a field will be automatically applied in instant card creation or upon launch of the Card Creator.';
	String get info_actions => 'Quick actions allow for instant card creation and other automations to be used on dictionary search results. Actions can be assigned via the slots below. Up to six slots may be utilised.';
	String get no_more_available_enhancements => 'No more available enhancements for this field';
	String get no_more_available_quick_actions => 'No more available quick actions';
	String get assign_auto_enhancement => 'Assign Auto Enhancement';
	String get assign_manual_enhancement => 'Assign Manual Enhancement';
	String get remove_enhancement => 'Remove Enhancement';
	String copy_of_mapping({required Object name}) => 'Copy of ${name}';
	String get enter_search_term => 'Enter a search term...';
	String get no_search_results => 'No search results found.';
	String get edit_actions => 'Edit Dictionary Quick Actions';
	String get remove_action => 'Remove Action';
	String get assign_action => 'Assign Action';
	String get no_sentences_found => 'No sentences found';
	String get failed_online_service => 'Failed to communicate with online service';
	String get search_label_before => 'Show all ';
	String get search_label_after => 'search results found for';
	String get clear_dictionary_title => 'Clear Dictionary Result History';
	String get clear_dictionary_description => 'This will clear all dictionary results from history. Are you sure?';
	String get clear_search_title => 'Clear Search History';
	String get clear_search_description => 'This will clear all search terms for this history. Are you sure?';
	String get clear_creator_title => 'Clear Creator';
	String get clear_creator_description => 'This will clear all fields. Are you sure?';
	String get copied_to_clipboard => 'Copied to clipboard.';
	String get no_text => 'No text.';
	String get info_fields => 'Fields are pre-filled based on the term selected on instant export or prior to opening the Card Creator. In order to include a field for card export, it must be enabled below as well as mapped in the current selected export profile. Enabled fields may also be collapsed below in order to reduce clutter during editing. Use the Clear button on the top-right of the Card Creator in order to wipe these hidden fields quickly when manually editing a card.';
	String get edit_fields => 'Edit and Reorder Fields';
	String get remove_field => 'Remove Field';
	String get add_field => 'Assign Field';
	String get add_field_hint => 'Assign a field to this row';
	String get no_more_available_fields => 'No more available fields';
	String get hidden_fields => 'Additional fields';
	String field_fallback_used({required Object field, required Object secondField}) => 'The ${field} field used ${secondField} as its fallback search term.';
	String get no_text_to_search => 'No text to search.';
	String get image_search_label_before => 'Selecting image ';
	String get image_search_label_middle => 'out of ';
	String get image_search_label_after => 'found for';
	String get image_search_label_none_middle => 'no image ';
	String get image_search_label_none_before => 'Selecting ';
	String get processing_in_progress => 'Preparing images';
	String get searching_in_progress => 'Searching for ';
	String get audio_unavailable => 'No audio could be found.';
	String get no_audio_enhancements => 'No audio enhancements are assigned.';
	String card_exported({required Object deck}) => 'Card exported to 『${deck}』.';
	String get exit_media_title => 'Exit Media';
	String get exit_media_description => 'This will return you to the main menu. Are you sure?';
	String get unimplemented_source => 'Unimplemented source';
	String get ttu_no_books_added => 'No books yet: import EPUB, HTMLZ or TXT files';
	String get ttu_refresh_library => 'Refresh library';
	String get ttu_refreshing => 'Refreshing library…';
	String get ttu_operation_failed => 'Library operation failed';
	String get ttu_import_books => 'Import books';
	String get ttu_importing => 'Importing books…';
	String get ttu_unsupported_files => 'Only EPUB, HTMLZ and TXT files can be imported';
	String get ttu_delete_book_confirm => 'Delete this book and its reading position?';
	String get ttu_deleting => 'Deleting book…';
	String get ttu_bridge_mismatch => 'The reader build does not match this app version';
	String get stash => 'Stash';
	String get stash_added => 'Added to stash';
	String get stash_already => 'Already stashed';
	String get stash_unavailable => 'Open a book to stash words';
	String get stash_jump => 'Jump to word';
	String get stash_all_dictionaries => 'All dictionaries';
	String get stash_entry_missing => 'This dictionary entry is no longer installed';
	String get stash_delete_one => 'Delete this stashed word?';
	String get stash_empty => 'No stashed words yet: use the stash button in the dictionary popup';
	String stash_selected({required Object n}) => '${n} selected';
	String get stash_select_all => 'Select all';
	String stash_delete_confirm({required Object n}) => 'Delete ${n} stashed word(s)?';
	String get paste => 'Paste';
	String get no_recordings_found => 'No recordings found';
	String get wrap_image_audio => 'Include image/audio HTML tags on export';
	String get text_segmentation => 'Text Segmentation';
	String get settings => 'Settings';
	String get settings_appearance => 'Appearance';
	String get settings_dark_theme => 'Dark theme';
	String get settings_about => 'About';
	String get volume_button_page_turning => 'Volume button page turning';
	String get invert_volume_buttons => 'Invert volume buttons';
	String get extend_page_beyond_navbar => 'Extend page beyond navigation bar';
	String get unit_milliseconds => 'ms';
	String get unit_pixels => 'px';
	String get auto_search => 'Auto search';
	String get auto_search_debounce_delay => 'Auto search debounce delay';
	String get dictionary_font_size => 'Dictionary font size';
	String get close_on_export => 'Close on Export';
	String get close_on_export_on => 'The Card Creator will now automatically close upon card export.';
	String get close_on_export_off => 'The Card Creator will no longer close upon card export.';
	String get export_profile_empty => 'Your export profile has no set fields and requires configuration.';
	String get error_export_media_ankidroid => 'There was an error in exporting media to AnkiDroid.';
	String get error_add_note => 'There was an error in adding a note to AnkiDroid.';
	String get maximum_terms => 'Maximum dictionary headwords in result';
	String get use_br_tags => 'Use line break tag instead of newline on export';
	String get prepend_dictionary_names => 'Prepend dictionary name in meaning';
	String get highlight_on_tap => 'Highlight text on tap';
	String get no_audio_file => 'No audio file to save.';
	String get storage_permissions => 'Please grant the following permissions for exporting to AnkiDroid.';
	String get pick_file => 'Pick File';
	String get open_url => 'Open URL';
	String get catalogs => 'Catalogs';
	String get name => 'Name';
	String get url => 'URL';
	String get duplicate_catalog => 'A catalog with this URL already exists.';
	String get no_catalogs_listed => 'No catalogs listed';
	String get invalid_mokuro_file => 'File is not a Mokuro generated HTML file.';
	String get create_catalog => 'Create Catalog';
	String get adapt_ttu_theme => 'Adapt dictionary popup to theme';
	String field_locked({required Object field}) => '${field} locked and will not clear on export while Creator is active.';
	String field_unlocked({required Object field}) => '${field} unlocked and will clear on export.';
	String get field_lock => 'Lock Field';
	String get field_unlock => 'Unlock Field';
	String get use_dark_theme => 'Use dark theme';
	String get saved_tags => 'Tags saved.';
	String get cloze => 'Cloze';
	String get info_standard_update => 'New standard profile card type';
	String get info_standard_update_content => 'The standard profile now uses the『Yomimoto』 card type.\n\nYour legacy standard profile remains available for backwards compatibility.';
	String get manage_duplicate_checks => 'Manage Duplicate Checks';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'reader_ttu': return 'Novels';
			case 'reader_mokuro': return 'Manga';
			case 'dictionary': return 'Dictionary';
			case 'back': return 'Back';
			case 'search': return 'Search';
			case 'search_ellipsis': return 'Search...';
			case 'show_more': return 'Show More';
			case 'pick_image': return 'Pick Image';
			case 'undo': return 'Undo';
			case 'copy': return 'Copy';
			case 'clear': return 'Clear';
			case 'creator': return 'Creator';
			case 'share': return 'Share';
			case 'resume_last_media': return 'Resume Last Media';
			case 'card_creator': return 'Card Creator';
			case 'show_options': return 'Show Options';
			case 'switch_profiles': return 'Switch Profiles';
			case 'dictionaries': return 'Dictionaries';
			case 'enhancements': return 'Enhancements';
			case 'dialog_read': return 'READ';
			case 'dialog_edit': return 'EDIT';
			case 'dialog_import': return 'IMPORT';
			case 'dialog_close': return 'CLOSE';
			case 'dialog_clear': return 'CLEAR';
			case 'dialog_create': return 'CREATE';
			case 'dialog_delete': return 'DELETE';
			case 'dialog_cancel': return 'CANCEL';
			case 'dialog_select': return 'SELECT';
			case 'dialog_search': return 'SEARCH';
			case 'dialog_exit': return 'EXIT';
			case 'dialog_save': return 'SAVE';
			case 'dialog_crop': return 'CROP';
			case 'dialog_append': return 'APPEND';
			case 'dialog_record': return 'RECORD';
			case 'dialog_manage': return 'MANAGE';
			case 'dialog_stop': return 'STOP';
			case 'dialog_done': return 'DONE';
			case 'reset': return 'Reset';
			case 'dialog_launch_ankidroid': return 'LAUNCH ANKIDROID';
			case 'mappings_delete_confirmation': return 'This profile will be deleted. Are you sure you want to do this?';
			case 'catalog_delete_confirmation': return 'This catalog will be deleted. Are you sure you want to do this?';
			case 'dictionaries_deleting_data': return 'Deleting dictionary data...';
			case 'dictionaries_menu_empty': return 'Import a dictionary for use';
			case 'options_dictionaries': return 'Manage dictionaries';
			case 'options_profiles': return 'Export profiles';
			case 'options_enhancements': return 'User enhancements';
			case 'options_github': return 'View repository on GitHub';
			case 'options_attribution': return 'Licenses and attribution';
			case 'options_copy': return 'Copy';
			case 'options_collapse': return 'Collapse';
			case 'options_expand': return 'Expand';
			case 'options_delete': return 'Delete';
			case 'options_show': return 'Show';
			case 'options_hide': return 'Hide';
			case 'options_edit': return 'Edit';
			case 'info_empty_home_tab': return 'History is empty';
			case 'delete_in_progress': return 'Delete in progress';
			case 'import_format': return 'Import format';
			case 'import_in_progress': return 'Import in progress';
			case 'import_start': return 'Preparing for import...';
			case 'import_extract_count': return ({required Object n}) => 'Extracted ${n} files...';
			case 'import_extract': return 'Extracting files...';
			case 'import_name': return ({required Object name}) => 'Importing 『${name}』...';
			case 'import_found_entry': return ({required Object count}) => 'Found ${count} entries...';
			case 'import_found_tag': return ({required Object count}) => 'Found ${count} tags...';
			case 'import_found_frequency': return ({required Object count}) => 'Found ${count} frequency entries...';
			case 'import_found_pitch': return ({required Object count}) => 'Found ${count} pitch accent entries...';
			case 'import_write_entry': return ({required Object count, required Object total}) => 'Writing entries:\n${count} / ${total}';
			case 'import_write_tag': return ({required Object count, required Object total}) => 'Writing tags:\n${count} / ${total}';
			case 'import_write_frequency': return ({required Object count, required Object total}) => 'Writing frequency entries:\n${count} / ${total}';
			case 'import_write_pitch': return ({required Object count, required Object total}) => 'Writing pitch accent entries:\n${count} / ${total}';
			case 'import_failed': return 'Dictionary import failed.';
			case 'import_complete': return 'Dictionary import complete.';
			case 'import_duplicate': return ({required Object name}) => 'A dictionary with the name『${name}』is already imported.';
			case 'dialog_title_dictionary_clear': return 'Clear all dictionaries?';
			case 'dialog_content_dictionary_clear': return 'Wiping the dictionary database will also clear all search results in history.';
			case 'dialog_title_dictionary_delete': return ({required Object name}) => 'Delete 『${name}』?';
			case 'dialog_content_dictionary_delete': return 'Deleting a single dictionary may take longer than clearing the entire dictionary database. This will also clear all search results in history.';
			case 'legalese': return '読本 — a Japanese book reader, dictionary and card creation toolkit for e-ink devices, by Philippe Daouadi.\n\nYomimoto is a fork of jidoujisho, originally built for the Japanese language learning community by Arianne Orpilla. Logo by suzy and Aaron Marbella.\n\nYomimoto is free and open source software. See the project repository for a comprehensive list of other licenses and attribution notices.';
			case 'field_label_empty': return 'Empty';
			case 'model_to_map': return 'Card type to use for new profile';
			case 'mapping_name': return 'Profile name';
			case 'mapping_name_hint': return 'Name to assign to profile';
			case 'error_profile_name': return 'Invalid profile name';
			case 'error_profile_name_content': return 'A profile with this name already exists or is not valid and cannot be saved.';
			case 'error_standard_profile_name': return 'Invalid profile name';
			case 'error_standard_profile_name_content': return 'Cannot rename the standard profile.';
			case 'error_ankidroid_api': return 'AnkiDroid error';
			case 'error_ankidroid_api_content': return 'There was an issue communicating with AnkiDroid.\n\nEnsure that the AnkiDroid background service is active and all relevant app permissions are granted in order to continue.';
			case 'info_standard_model': return 'Standard card type added';
			case 'info_standard_model_content': return '『Yomimoto』 has been added to AnkiDroid as a new card type.\n\nSetups making use of a different card type or field order may be used by adding a new export profile.';
			case 'error_model_missing': return 'Missing card type';
			case 'error_model_missing_content': return 'The corresponding card type of the currently selected profile is missing.\n\nThe profile will be deleted, and the standard profile has now been selected in its place.';
			case 'error_model_changed': return 'Card type changed';
			case 'error_model_changed_content': return 'The number of fields of the card type corresponding to the selected profile has changed.\n\nThe fields of the currently selected profile have been reset and will require reconfiguration.';
			case 'creator_exporting_as': return 'Creating card with profile';
			case 'creator_exporting_as_fields_editing': return 'Editing fields for profile';
			case 'creator_exporting_as_enhancements_editing': return 'Editing enhancements for profile';
			case 'creator_export_card': return 'Create Card';
			case 'info_enhancements': return 'Enhancements enable the automation of field editing prior to card creation. Pick a slot on the right of a field to allow use of an enhancement. Up to five right slots may be utilised for each field. The enhancement in the left slot of a field will be automatically applied in instant card creation or upon launch of the Card Creator.';
			case 'info_actions': return 'Quick actions allow for instant card creation and other automations to be used on dictionary search results. Actions can be assigned via the slots below. Up to six slots may be utilised.';
			case 'no_more_available_enhancements': return 'No more available enhancements for this field';
			case 'no_more_available_quick_actions': return 'No more available quick actions';
			case 'assign_auto_enhancement': return 'Assign Auto Enhancement';
			case 'assign_manual_enhancement': return 'Assign Manual Enhancement';
			case 'remove_enhancement': return 'Remove Enhancement';
			case 'copy_of_mapping': return ({required Object name}) => 'Copy of ${name}';
			case 'enter_search_term': return 'Enter a search term...';
			case 'no_search_results': return 'No search results found.';
			case 'edit_actions': return 'Edit Dictionary Quick Actions';
			case 'remove_action': return 'Remove Action';
			case 'assign_action': return 'Assign Action';
			case 'no_sentences_found': return 'No sentences found';
			case 'failed_online_service': return 'Failed to communicate with online service';
			case 'search_label_before': return 'Show all ';
			case 'search_label_after': return 'search results found for';
			case 'clear_dictionary_title': return 'Clear Dictionary Result History';
			case 'clear_dictionary_description': return 'This will clear all dictionary results from history. Are you sure?';
			case 'clear_search_title': return 'Clear Search History';
			case 'clear_search_description': return 'This will clear all search terms for this history. Are you sure?';
			case 'clear_creator_title': return 'Clear Creator';
			case 'clear_creator_description': return 'This will clear all fields. Are you sure?';
			case 'copied_to_clipboard': return 'Copied to clipboard.';
			case 'no_text': return 'No text.';
			case 'info_fields': return 'Fields are pre-filled based on the term selected on instant export or prior to opening the Card Creator. In order to include a field for card export, it must be enabled below as well as mapped in the current selected export profile. Enabled fields may also be collapsed below in order to reduce clutter during editing. Use the Clear button on the top-right of the Card Creator in order to wipe these hidden fields quickly when manually editing a card.';
			case 'edit_fields': return 'Edit and Reorder Fields';
			case 'remove_field': return 'Remove Field';
			case 'add_field': return 'Assign Field';
			case 'add_field_hint': return 'Assign a field to this row';
			case 'no_more_available_fields': return 'No more available fields';
			case 'hidden_fields': return 'Additional fields';
			case 'field_fallback_used': return ({required Object field, required Object secondField}) => 'The ${field} field used ${secondField} as its fallback search term.';
			case 'no_text_to_search': return 'No text to search.';
			case 'image_search_label_before': return 'Selecting image ';
			case 'image_search_label_middle': return 'out of ';
			case 'image_search_label_after': return 'found for';
			case 'image_search_label_none_middle': return 'no image ';
			case 'image_search_label_none_before': return 'Selecting ';
			case 'processing_in_progress': return 'Preparing images';
			case 'searching_in_progress': return 'Searching for ';
			case 'audio_unavailable': return 'No audio could be found.';
			case 'no_audio_enhancements': return 'No audio enhancements are assigned.';
			case 'card_exported': return ({required Object deck}) => 'Card exported to 『${deck}』.';
			case 'exit_media_title': return 'Exit Media';
			case 'exit_media_description': return 'This will return you to the main menu. Are you sure?';
			case 'unimplemented_source': return 'Unimplemented source';
			case 'ttu_no_books_added': return 'No books yet: import EPUB, HTMLZ or TXT files';
			case 'ttu_refresh_library': return 'Refresh library';
			case 'ttu_refreshing': return 'Refreshing library…';
			case 'ttu_operation_failed': return 'Library operation failed';
			case 'ttu_import_books': return 'Import books';
			case 'ttu_importing': return 'Importing books…';
			case 'ttu_unsupported_files': return 'Only EPUB, HTMLZ and TXT files can be imported';
			case 'ttu_delete_book_confirm': return 'Delete this book and its reading position?';
			case 'ttu_deleting': return 'Deleting book…';
			case 'ttu_bridge_mismatch': return 'The reader build does not match this app version';
			case 'stash': return 'Stash';
			case 'stash_added': return 'Added to stash';
			case 'stash_already': return 'Already stashed';
			case 'stash_unavailable': return 'Open a book to stash words';
			case 'stash_jump': return 'Jump to word';
			case 'stash_all_dictionaries': return 'All dictionaries';
			case 'stash_entry_missing': return 'This dictionary entry is no longer installed';
			case 'stash_delete_one': return 'Delete this stashed word?';
			case 'stash_empty': return 'No stashed words yet: use the stash button in the dictionary popup';
			case 'stash_selected': return ({required Object n}) => '${n} selected';
			case 'stash_select_all': return 'Select all';
			case 'stash_delete_confirm': return ({required Object n}) => 'Delete ${n} stashed word(s)?';
			case 'paste': return 'Paste';
			case 'no_recordings_found': return 'No recordings found';
			case 'wrap_image_audio': return 'Include image/audio HTML tags on export';
			case 'text_segmentation': return 'Text Segmentation';
			case 'settings': return 'Settings';
			case 'settings_appearance': return 'Appearance';
			case 'settings_dark_theme': return 'Dark theme';
			case 'settings_about': return 'About';
			case 'volume_button_page_turning': return 'Volume button page turning';
			case 'invert_volume_buttons': return 'Invert volume buttons';
			case 'extend_page_beyond_navbar': return 'Extend page beyond navigation bar';
			case 'unit_milliseconds': return 'ms';
			case 'unit_pixels': return 'px';
			case 'auto_search': return 'Auto search';
			case 'auto_search_debounce_delay': return 'Auto search debounce delay';
			case 'dictionary_font_size': return 'Dictionary font size';
			case 'close_on_export': return 'Close on Export';
			case 'close_on_export_on': return 'The Card Creator will now automatically close upon card export.';
			case 'close_on_export_off': return 'The Card Creator will no longer close upon card export.';
			case 'export_profile_empty': return 'Your export profile has no set fields and requires configuration.';
			case 'error_export_media_ankidroid': return 'There was an error in exporting media to AnkiDroid.';
			case 'error_add_note': return 'There was an error in adding a note to AnkiDroid.';
			case 'maximum_terms': return 'Maximum dictionary headwords in result';
			case 'use_br_tags': return 'Use line break tag instead of newline on export';
			case 'prepend_dictionary_names': return 'Prepend dictionary name in meaning';
			case 'highlight_on_tap': return 'Highlight text on tap';
			case 'no_audio_file': return 'No audio file to save.';
			case 'storage_permissions': return 'Please grant the following permissions for exporting to AnkiDroid.';
			case 'pick_file': return 'Pick File';
			case 'open_url': return 'Open URL';
			case 'catalogs': return 'Catalogs';
			case 'name': return 'Name';
			case 'url': return 'URL';
			case 'duplicate_catalog': return 'A catalog with this URL already exists.';
			case 'no_catalogs_listed': return 'No catalogs listed';
			case 'invalid_mokuro_file': return 'File is not a Mokuro generated HTML file.';
			case 'create_catalog': return 'Create Catalog';
			case 'adapt_ttu_theme': return 'Adapt dictionary popup to theme';
			case 'field_locked': return ({required Object field}) => '${field} locked and will not clear on export while Creator is active.';
			case 'field_unlocked': return ({required Object field}) => '${field} unlocked and will clear on export.';
			case 'field_lock': return 'Lock Field';
			case 'field_unlock': return 'Unlock Field';
			case 'use_dark_theme': return 'Use dark theme';
			case 'saved_tags': return 'Tags saved.';
			case 'cloze': return 'Cloze';
			case 'info_standard_update': return 'New standard profile card type';
			case 'info_standard_update_content': return 'The standard profile now uses the『Yomimoto』 card type.\n\nYour legacy standard profile remains available for backwards compatibility.';
			case 'manage_duplicate_checks': return 'Manage Duplicate Checks';
			default: return null;
		}
	}
}
