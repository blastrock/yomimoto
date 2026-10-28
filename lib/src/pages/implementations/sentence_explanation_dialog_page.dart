import 'package:flutter/material.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:spaces/spaces.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// Asks the model to explain a sentence and shows its translation and parts.
class SentenceExplanationDialogPage extends BasePage {
  /// Create the dialog for [request]. The request starts when it opens.
  const SentenceExplanationDialogPage({
    required this.request,
    super.key,
  });

  /// The sentence to explain, with its context.
  final ExplanationRequest request;

  @override
  BasePageState createState() => _SentenceExplanationDialogPageState();
}

class _SentenceExplanationDialogPageState
    extends BasePageState<SentenceExplanationDialogPage> {
  /// The request in flight or its result. Replaced on Retry; a result that
  /// arrives after the dialog closed is dropped with the [FutureBuilder].
  late Future<SentenceExplanation> _explanation;

  @override
  void initState() {
    super.initState();
    _explanation = _explain();
  }

  Future<SentenceExplanation> _explain() {
    PreferenceStore preferences = appModelNoUpdate.preferences;

    return explainSentence(
      apiKey: preferences.get(Preferences.explanationApiKey),
      preset: ExplanationPreset.fromKey(
          preferences.get(Preferences.explanationPreset)),
      request: widget.request,
    );
  }

  void _retry() {
    setState(() {
      _explanation = _explain();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SentenceExplanation>(
      future: _explanation,
      builder: (context, snapshot) {
        ExplanationException? failure = switch (snapshot.error) {
          null => null,
          ExplanationException e => e,
          _ => ExplanationException(ExplanationFailure.unparseable),
        };
        bool waiting = snapshot.connectionState != ConnectionState.done;

        return AlertDialog(
          contentPadding: Spacing.of(context).insets.all.big,
          content: SizedBox(
            width: double.maxFinite,
            child: waiting
                ? Padding(
                    padding: Spacing.of(context).insets.vertical.big,
                    child: buildLoading(),
                  )
                : failure != null
                    ? buildFailure(failure)
                    : buildExplanation(snapshot.requireData),
          ),
          actions: [
            if (!waiting && failure != null && failure.failure.retryable)
              TextButton(
                onPressed: _retry,
                child: Text(t.dialog_retry),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.dialog_close),
            ),
          ],
        );
      },
    );
  }

  /// The translation, then one row per part.
  Widget buildExplanation(SentenceExplanation explanation) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(explanation.translation, style: textTheme.bodyLarge),
          const JidoujishoDivider(),
          ...explanation.parts.map(buildPart),
        ],
      ),
    );
  }

  /// A part with furigana over its kanji, and its meaning beside it.
  Widget buildPart(ExplanationPart part) {
    TextStyle? style = textTheme.titleMedium;

    return Padding(
      padding: Spacing.of(context).insets.vertical.extraSmall,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: part.showsReading
                ? RubyText(
                    part.furigana,
                    style: style,
                    rubyStyle: textTheme.labelSmall,
                  )
                : Text(part.text, style: style),
          ),
          const Space.normal(),
          Expanded(
            flex: 3,
            child: Text(part.meaning, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  /// What went wrong, with the API's own message when it explains more.
  Widget buildFailure(ExplanationException exception) {
    String message = switch (exception.failure) {
      ExplanationFailure.noApiKey => t.explanation_no_api_key,
      ExplanationFailure.network => t.explanation_network,
      ExplanationFailure.timeout => t.explanation_timeout,
      ExplanationFailure.rateLimited => t.explanation_rate_limited,
      ExplanationFailure.server => t.explanation_server,
      ExplanationFailure.badKey => t.explanation_bad_key,
      ExplanationFailure.request => t.explanation_request,
      ExplanationFailure.refusal => t.explanation_refusal,
      ExplanationFailure.truncated => t.explanation_truncated,
      ExplanationFailure.unparseable => t.explanation_unparseable,
    };
    String? detail = switch (exception.failure) {
      ExplanationFailure.badKey ||
      ExplanationFailure.request ||
      ExplanationFailure.server =>
        exception.message,
      _ => null,
    };

    return JidoujishoPlaceholderMessage(
      icon: Icons.error_outline,
      message: detail == null ? message : '$message\n\n$detail',
    );
  }
}
