import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:spaces/spaces.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// A full page listing every app-wide preference, reachable from the home
/// page's app bar. This gathers the options that used to live in the home
/// page's overflow menu together with the dictionary settings and the
/// per-source reader tweaks.
class SettingsPage extends BasePage {
  /// Create an instance of this page.
  const SettingsPage({super.key});

  @override
  BasePageState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends BasePageState<SettingsPage> {
  ReaderTtuSource get ttuSource => ReaderTtuSource.instance;
  ReaderMokuroSource get mokuroSource => ReaderMokuroSource.instance;

  final ScrollController _scrollController = ScrollController();

  late final TextEditingController _fontSizeController;
  late final TextEditingController _maximumTermsController;
  late final TextEditingController _apiKeyController;

  /// Captured in [initState] so [dispose] does not have to reach for a
  /// provider, which is no longer legal at that point.
  late final AppModel _appModel;

  /// The dictionary font size is not read live by the pages showing dictionary
  /// entries, so a change to it only takes effect once this page announces it.
  late final double _initialFontSize;

  @override
  void initState() {
    super.initState();

    _appModel = appModelNoUpdate;
    _initialFontSize =
        _appModel.preferences.get(Preferences.dictionaryFontSize);

    _fontSizeController = TextEditingController(
      text:
          _appModel.preferences.get(Preferences.dictionaryFontSize).toString(),
    );
    _maximumTermsController = TextEditingController(
      text: _appModel.preferences.get(Preferences.maximumTerms).toString(),
    );
    _apiKeyController = TextEditingController(
      text: _appModel.preferences.get(Preferences.explanationApiKey),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fontSizeController.dispose();
    _maximumTermsController.dispose();
    _apiKeyController.dispose();

    if (_appModel.preferences.get(Preferences.dictionaryFontSize) !=
        _initialFontSize) {
      _appModel.refresh();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
        titleSpacing: 8,
      ),
      body: SafeArea(
        child: RawScrollbar(
          thickness: 3,
          thumbVisibility: true,
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: Spacing.of(context).insets.onlyBottom.big,
            children: [
              buildHeader(t.settings_appearance),
              buildChoice<ThemeMode>(
                label: t.settings_theme,
                options: ThemeMode.values,
                value: appModel.themeMode,
                generateLabel: (mode) => switch (mode) {
                  ThemeMode.system => t.theme_system,
                  ThemeMode.light => t.theme_light,
                  ThemeMode.dark => t.theme_dark,
                },
                onChanged: appModel.setThemeMode,
              ),
              buildHeader(t.dictionaries),
              buildAction(
                icon: Icons.auto_stories_rounded,
                label: t.options_dictionaries,
                onTap: appModel.showDictionaryMenu,
              ),
              buildAction(
                icon: Icons.checklist_sharp,
                label: t.manage_duplicate_checks,
                onTap: showDuplicateChecksPage,
              ),
              buildSwitch(
                label: t.auto_search,
                value: appModel.preferences.get(Preferences.autoSearch),
                toggle: () =>
                    appModel.preferences.toggle(Preferences.autoSearch),
              ),
              buildNumberField(
                controller: _fontSizeController,
                label: t.dictionary_font_size,
                suffixText: t.unit_pixels,
                defaultValue:
                    Preferences.dictionaryFontSize.defaultValue.toString(),
                onChanged: (value) {
                  double size = double.tryParse(value) ??
                      Preferences.dictionaryFontSize.defaultValue;
                  if (size.isNegative) {
                    size = Preferences.dictionaryFontSize.defaultValue;
                    _fontSizeController.text = size.toString();
                  }

                  appModel.preferences
                      .set(Preferences.dictionaryFontSize, size);
                },
              ),
              buildNumberField(
                controller: _maximumTermsController,
                label: t.maximum_terms,
                defaultValue:
                    Preferences.maximumTerms.defaultValue.toString(),
                onChanged: (value) {
                  int amount = int.tryParse(value) ??
                      Preferences.maximumTerms.defaultValue;
                  if (amount.isNegative) {
                    amount = Preferences.maximumTerms.defaultValue;
                    _maximumTermsController.text = amount.toString();
                  }

                  appModel.preferences.set(Preferences.maximumTerms, amount);
                  appModel.clearDictionaryResultsCache();
                },
              ),
              buildHeader(t.card_creator),
              buildAction(
                icon: Icons.auto_fix_high,
                label: t.options_enhancements,
                onTap: appModel.openCreatorEnhancementsEditor,
              ),
              buildAction(
                icon: Icons.switch_account,
                label: t.options_profiles,
                onTap: appModel.showProfilesMenu,
              ),
              buildHeader(ttuSource.sourceName),
              buildSwitch(
                label: t.highlight_on_tap,
                value: ttuSource.highlightOnTap,
                toggle: ttuSource.toggleHighlightOnTap,
              ),
              buildSwitch(
                label: t.volume_button_page_turning,
                value: ttuSource.volumePageTurningEnabled,
                toggle: ttuSource.toggleVolumePageTurningEnabled,
              ),
              buildSwitch(
                label: t.invert_volume_buttons,
                value: ttuSource.volumePageTurningInverted,
                toggle: ttuSource.toggleVolumePageTurningInverted,
              ),
              buildSwitch(
                label: t.extend_page_beyond_navbar,
                value: ttuSource.extendPageBeyondNavigationBar,
                toggle: ttuSource.toggleExtendPageBeyondNavigationBar,
              ),
              buildHeader(mokuroSource.sourceName),
              buildSwitch(
                label: t.highlight_on_tap,
                value: mokuroSource.highlightOnTap,
                toggle: mokuroSource.toggleHighlightOnTap,
              ),
              buildSwitch(
                label: t.volume_button_page_turning,
                value: mokuroSource.volumePageTurningEnabled,
                toggle: mokuroSource.toggleVolumePageTurningEnabled,
              ),
              buildSwitch(
                label: t.invert_volume_buttons,
                value: mokuroSource.volumePageTurningInverted,
                toggle: mokuroSource.toggleVolumePageTurningInverted,
              ),
              buildHeader(t.sentence_explanation),
              buildTextField(
                controller: _apiKeyController,
                label: t.explanation_api_key,
                obscureText: true,
                onChanged: (value) => appModel.preferences
                    .set(Preferences.explanationApiKey, value.trim()),
              ),
              buildChoice<ExplanationPreset>(
                label: t.explanation_model,
                options: ExplanationPreset.values,
                value: ExplanationPreset.fromKey(
                    appModel.preferences.get(Preferences.explanationPreset)),
                generateLabel: (preset) => switch (preset) {
                  ExplanationPreset.sonnet => t.explanation_preset_sonnet,
                  ExplanationPreset.haiku => t.explanation_preset_haiku,
                },
                onChanged: (preset) => appModel.preferences
                    .set(Preferences.explanationPreset, preset.name),
              ),
              buildHeader(t.settings_about),
              buildAction(
                icon: Icons.code,
                label: t.options_github,
                onTap: browseToGithub,
              ),
              buildAction(
                icon: Icons.info,
                label: t.options_attribution,
                onTap: navigateToLicensePage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader(String label) {
    return Padding(
      padding: Spacing.of(context).insets.horizontal.normal.copyWith(
            top: Spacing.of(context).spaces.big,
            bottom: Spacing.of(context).spaces.small,
          ),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// [toggle] flips the underlying preference. The preference stores are
  /// updated in-memory before their first suspension point, so reading the
  /// value back on the next build reflects the new state.
  Widget buildSwitch({
    required String label,
    required bool value,
    required Function() toggle,
  }) {
    return SwitchListTile(
      title: Text(label, style: textTheme.bodyMedium),
      value: value,
      onChanged: (_) {
        toggle();
        setState(() {});
      },
      contentPadding: Spacing.of(context).insets.horizontal.normal,
    );
  }

  /// [onChanged] persists the picked option; the dropdown shows it at once.
  Widget buildChoice<T>({
    required String label,
    required List<T> options,
    required T value,
    required String Function(T) generateLabel,
    required Future<void> Function(T) onChanged,
  }) {
    return Padding(
      padding: Spacing.of(context).insets.horizontal.normal.copyWith(
            top: Spacing.of(context).spaces.small,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodyMedium),
          JidoujishoDropdown<T>(
            options: options,
            initialOption: value,
            generateLabel: generateLabel,
            onChanged: (option) => onChanged(option as T),
          ),
        ],
      ),
    );
  }

  Widget buildAction({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: textTheme.bodyLarge?.fontSize),
      title: Text(label, style: textTheme.bodyMedium),
      onTap: onTap,
      contentPadding: Spacing.of(context).insets.horizontal.normal,
    );
  }

  /// The reset button writes [defaultValue] into the field and then routes it
  /// through [onChanged], so a field only has to state how to persist a value
  /// once.
  Widget buildNumberField({
    required TextEditingController controller,
    required String label,
    required String defaultValue,
    required Function(String) onChanged,
    String? suffixText,
  }) {
    return Padding(
      padding: Spacing.of(context).insets.horizontal.normal.copyWith(
            top: Spacing.of(context).spaces.small,
          ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: label,
          suffixText: suffixText,
          suffixIcon: JidoujishoIconButton(
            tooltip: t.reset,
            size: 18,
            icon: Icons.undo,
            onTap: () {
              controller.text = defaultValue;
              onChanged(defaultValue);
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    bool obscureText = false,
  }) {
    return Padding(
      padding: Spacing.of(context).insets.horizontal.normal.copyWith(
            top: Spacing.of(context).spaces.small,
          ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: label,
        ),
      ),
    );
  }

  Future<void> showDuplicateChecksPage() async {
    List<String> duplicateCheckModels =
        appModel.preferences.get(Preferences.duplicateCheckModels);
    List<String> models = await appModel.getModelList();
    Map<String, bool> items = Map<String, bool>.fromEntries(
        models.map((e) => MapEntry(e, duplicateCheckModels.contains(e))));

    if (!mounted) {
      return;
    }

    unawaited(showDialog(
      context: context,
      builder: (context) => SwitchSettingsPage<String>(
        items: items,
        generateLabel: (item) => item,
        onSave: (selection) {
          List<String> newDuplicateCheckModels = selection.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
          appModel.preferences.set(
              Preferences.duplicateCheckModels, newDuplicateCheckModels);

          if (!duplicateCheckModels.equals(newDuplicateCheckModels)) {
            appModel.refresh();
          }
        },
      ),
    ));
  }

  void browseToGithub() {
    launchUrl(
      Uri.parse('https://github.com/blastrock/yomimoto'),
      mode: LaunchMode.externalApplication,
    );
  }

  void navigateToLicensePage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Theme(
          data: theme.copyWith(
            cardColor: theme.colorScheme.surface,
          ),
          child: LicensePage(
            applicationName: appModel.packageInfo.appName,
            applicationVersion: appModel.packageInfo.version,
            applicationLegalese: t.legalese,
            applicationIcon: Padding(
              padding: Spacing.of(context).insets.all.normal,
              child: Image.asset(
                'assets/meta/icon.png',
                height: 128,
                width: 128,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
