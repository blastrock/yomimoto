import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// Asks the model to translate the reader's current sentence and split it
/// into parts with their readings and meanings.
class ExplainSentenceAction extends QuickAction {
  /// Initialise this action with the hardset parameters.
  ExplainSentenceAction()
      : super(
          uniqueKey: key,
          label: 'Explain Sentence',
          description: 'Translate the sentence around the word and split it'
              ' into parts with their readings and meanings.',
          icon: Icons.translate,
          closesPopup: true,
        );

  /// Used to identify this action.
  static const String key = 'explain_sentence';

  /// Whether a sentence of this [kind] of source can be explained: only in a
  /// reader, and only when it recorded a sentence.
  static bool canExplain({
    required ExplanationKind? kind,
    required String sentence,
  }) {
    return kind != null && sentence.trim().isNotEmpty;
  }

  @override
  Future<void> executeAction({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
    required CreatorModel creatorModel,
    required DictionaryHeading heading,
    required DictionaryEntry? selectedEntry,
  }) async {
    MediaItem? mediaItem = appModel.getCurrentMediaItem();
    MediaSource? mediaSource = mediaItem?.getMediaSource(appModel: appModel);
    String sentence = mediaSource?.currentSentence.text ?? '';
    ExplanationKind? kind = mediaSource?.explanationKind;

    if (mediaItem == null ||
        mediaSource == null ||
        kind == null ||
        !canExplain(kind: kind, sentence: sentence)) {
      showToast(
        msg: t.explain_unavailable,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    List<String> paragraphs = const [];
    try {
      paragraphs = await mediaSource.explanationContext?.call() ?? const [];
    } on TtuBridgeException catch (e) {
      debugPrint('Explain sentence: no context, $e');
    }

    ExplanationRequest request = ExplanationRequest(
      title: mediaItem.overrideTitle ?? mediaItem.title,
      sentence: sentence.trim(),
      kind: kind,
      context: paragraphs,
    );

    if (!context.mounted) {
      return;
    }

    // Not awaited: the popup closes once this returns, under the dialog.
    unawaited(showDialog(
      context: context,
      builder: (context) => SentenceExplanationDialogPage(request: request),
    ));
  }
}
