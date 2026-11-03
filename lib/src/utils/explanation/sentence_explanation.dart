import 'dart:convert';

import 'package:ruby_text/ruby_text.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/utils.dart';

/// What kind of text a sentence comes from, which decides the system prompt
/// and whether context is sent.
enum ExplanationKind {
  /// A sentence from a novel, sent with the paragraphs before it.
  novel,

  /// The text of one manga speech bubble, sent alone.
  manga,
}

/// A model and the request settings that suit it. Stored by [name].
enum ExplanationPreset {
  /// Better on context and names; the default.
  sonnet(
    model: 'claude-sonnet-5-5',
    thinking: {'type': 'adaptive'},
    effort: 'low',
  ),

  /// About twenty times cheaper and faster, weaker on context.
  haiku(
    model: 'claude-haiku-5-5',
    thinking: {'type': 'disabled'},
  );

  const ExplanationPreset({
    required this.model,
    required this.thinking,
    this.effort,
  });

  /// The Anthropic model id.
  final String model;

  /// The request's `thinking` setting.
  final Map<String, dynamic> thinking;

  /// The request's `output_config.effort`, or null to send none.
  final String? effort;

  /// The preset stored under [key], or [sonnet] for an unknown key.
  static ExplanationPreset fromKey(String key) {
    return values.firstWhere(
      (preset) => preset.name == key,
      orElse: () => sonnet,
    );
  }
}

/// Why an explanation could not be shown.
enum ExplanationFailure {
  /// No API key is set.
  noApiKey(retryable: false),

  /// The API could not be reached.
  network(retryable: true),

  /// The API did not answer in time.
  timeout(retryable: true),

  /// HTTP 429.
  rateLimited(retryable: true),

  /// HTTP 5xx, including 529 (overloaded).
  server(retryable: true),

  /// HTTP 401 or 403.
  badKey(retryable: false),

  /// Any other HTTP 4xx.
  request(retryable: false),

  /// The model declined (`stop_reason: refusal`).
  refusal(retryable: false),

  /// The answer hit `max_tokens`.
  truncated(retryable: false),

  /// The answer was not the expected JSON.
  unparseable(retryable: true);

  const ExplanationFailure({required this.retryable});

  /// Whether the same request may succeed if sent again.
  final bool retryable;
}

/// An explanation failed; [failure] says why.
class ExplanationException implements Exception {
  /// Create the exception, with the API's own [message] when it gave one.
  ExplanationException(this.failure, [this.message]);

  /// Why the explanation failed.
  final ExplanationFailure failure;

  /// The API's error message, if any.
  final String? message;

  /// What went wrong, for the user, with the API's own message when it
  /// explains more.
  String get displayMessage {
    String text = switch (failure) {
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
    String? detail = switch (failure) {
      ExplanationFailure.badKey ||
      ExplanationFailure.request ||
      ExplanationFailure.server =>
        message,
      _ => null,
    };

    return detail == null ? text : '$text\n\n$detail';
  }

  @override
  String toString() => 'ExplanationException(${failure.name}): $message';
}

/// Bound the context sent with a sentence to [maxLength] characters, so that
/// a book whose paragraphs are not marked up (a whole section in one block)
/// does not send its whole chapter. Drops the oldest paragraphs first; when
/// the last one, the paragraph of the sentence, is too long on its own, sends
/// no context at all.
List<String> limitContext(List<String> paragraphs, {int maxLength = 2000}) {
  List<String> kept = [];
  int length = 0;
  for (String paragraph in paragraphs.reversed) {
    length += paragraph.length;
    if (length > maxLength) {
      break;
    }
    kept.insert(0, paragraph);
  }

  return kept;
}

/// A sentence to explain, with what the model needs to know around it.
class ExplanationRequest {
  /// Create a request. [context] holds paragraphs with furigana written
  /// `kanji(reading)`; it stays empty for manga.
  ExplanationRequest({
    required this.title,
    required this.sentence,
    required this.kind,
    this.context = const [],
  });

  /// The book or manga title.
  final String title;

  /// The sentence to explain, without furigana.
  final String sentence;

  /// What kind of text the sentence comes from.
  final ExplanationKind kind;

  /// The paragraphs before the sentence, then the one containing it.
  final List<String> context;

  /// The `max_tokens` of every request.
  static const int maxTokens = 4000;

  /// The user turn of the request.
  String get userMessage {
    StringBuffer buffer = StringBuffer('Book: $title\n\n');
    if (context.isNotEmpty) {
      buffer.write('Context:\n${context.join('\n')}\n\n');
    }
    buffer.write('Sentence to explain:\n$sentence');

    return buffer.toString();
  }

  /// The Messages API request body for [preset].
  Map<String, dynamic> bodyFor(ExplanationPreset preset) {
    return {
      'model': preset.model,
      'max_tokens': maxTokens,
      'system': switch (kind) {
        ExplanationKind.novel => novelSystemPrompt,
        ExplanationKind.manga => mangaSystemPrompt,
      },
      'messages': [
        {'role': 'user', 'content': userMessage},
      ],
      'thinking': preset.thinking,
      'output_config': {
        'effort': ?preset.effort,
        'format': {'type': 'json_schema', 'schema': explanationSchema},
      },
    };
  }
}

/// One part of an explained sentence.
class ExplanationPart {
  /// Create a part.
  ExplanationPart({
    required this.text,
    required this.reading,
    required this.meaning,
  });

  /// The part's characters, as in the sentence.
  final String text;

  /// The reading of the whole [text], in kana.
  final String reading;

  /// What the part means in the sentence.
  final String meaning;

  static final RegExp _kanji =
      RegExp('[㐀-䶿一-鿿豈-﫿々]');

  static final RegExp _noLetters =
      RegExp(r'^[\p{P}\p{S}\s]*$', unicode: true);

  /// Whether a reading is worth showing: only when [text] has kanji.
  bool get showsReading => _kanji.hasMatch(text);

  /// Whether [text] is only punctuation, symbols or spaces.
  bool get hasNoLetters => _noLetters.hasMatch(text);

  /// [text] with [reading] distributed over its kanji, or over the whole
  /// part when it cannot be distributed.
  late final List<RubyTextData> furigana = LanguageUtils.distributeFurigana(
    heading: DictionaryHeading(term: text, reading: reading),
  );
}

/// The model's answer: a translation and the sentence split into parts.
class SentenceExplanation {
  /// Create an explanation.
  SentenceExplanation({required this.translation, required this.parts});

  /// Parse a Messages API response. Throws [ExplanationException] for a
  /// refusal, a truncated answer or an answer that is not the expected JSON.
  factory SentenceExplanation.fromResponse(Map<String, dynamic> response) {
    switch (response['stop_reason']) {
      case 'refusal':
        throw ExplanationException(ExplanationFailure.refusal);
      case 'max_tokens':
        throw ExplanationException(ExplanationFailure.truncated);
    }

    try {
      String text = (response['content'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String)
          .join();
      Map<String, dynamic> json = jsonDecode(text) as Map<String, dynamic>;

      List<ExplanationPart> parts = (json['parts'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((part) => ExplanationPart(
                text: part['text'] as String,
                reading: part['reading'] as String,
                meaning: part['meaning'] as String,
              ))
          .where((part) => !part.hasNoLetters)
          .toList();

      return SentenceExplanation(
        translation: json['translation'] as String,
        parts: parts,
      );
    } on FormatException {
      throw ExplanationException(ExplanationFailure.unparseable);
    } on TypeError {
      throw ExplanationException(ExplanationFailure.unparseable);
    }
  }

  /// The English translation of the sentence.
  final String translation;

  /// The sentence's parts, in order.
  final List<ExplanationPart> parts;
}
