import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/models.dart';

/// An entity that executes an action when its icon is tapped on a dictionary
/// result, either on the heading ([AppModel.headingQuickActions]) or on each
/// of its definitions ([AppModel.entryQuickActions]). An action is initialised
/// at runtime in the initialisation step.
abstract class QuickAction {
  /// Initialise this action with the predetermined and hardset values.
  QuickAction({
    required this.uniqueKey,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// A unique name that allows distinguishing this type from others,
  /// particularly for the purposes of differentiating between persistent
  /// settings keys.
  final String uniqueKey;

  /// Name of the action that very shortly describes what it does.
  final String label;

  /// A longer description of what the action can do, or details left
  /// by or regarding the developer.
  final String description;

  /// An icon that will show the action if activated by the user in the
  /// quick menu.
  final IconData icon;

  /// Whether or not [initialise] has been called for this action.
  bool _initialised = false;

  /// This function is run at startup or when changing languages. It is not
  /// called again if already run.
  Future<void> initialise() async {
    if (_initialised) {
      return;
    } else {
      await prepareResources();
      _initialised = true;
    }
  }

  /// If an enhancement requires resources to function, they can be prepared
  /// here and this function will be run once only at runtime during the
  /// initialisation step.
  Future<void> prepareResources() async {}

  /// If non-null, sets a custom enabled color that this action should have for
  /// a certain condition in the application. By default, this is the
  /// foreground color.
  Future<Color?> getIconColor({
    required AppModel appModel,
    required DictionaryHeading heading,
  }) async {
    return null;
  }

  /// Execute the functionality of this action. [selectedEntry] is the single
  /// entry the action was invoked on, or null when it applies to the whole
  /// [heading].
  Future<void> executeAction({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
    required CreatorModel creatorModel,
    required DictionaryHeading heading,
    required DictionaryEntry? selectedEntry,
  });
}
