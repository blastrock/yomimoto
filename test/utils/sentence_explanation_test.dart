import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:yuuna/utils.dart';

void main() {
  ExplanationRequest novelRequest() => ExplanationRequest(
        title: '最後の魔法',
        sentence: '南雲桜子。',
        kind: ExplanationKind.novel,
        context: ['a', '南(な)雲(ぐも)桜子。'],
      );

  ExplanationRequest mangaRequest() => ExplanationRequest(
        title: 'T',
        sentence: 'S',
        kind: ExplanationKind.manga,
      );

  Map<String, dynamic> response(String text,
          {String stopReason = 'end_turn'}) =>
      {
        'stop_reason': stopReason,
        'content': [
          {'type': 'thinking', 'thinking': ''},
          {'type': 'text', 'text': text},
        ],
      };

  ExplanationFailure failureOf(void Function() parse) {
    try {
      parse();
    } on ExplanationException catch (e) {
      return e.failure;
    }
    throw StateError('no ExplanationException');
  }

  group('ExplanationRequest', () {
    test('user message with context', () {
      expect(
        novelRequest().userMessage,
        'Book: 最後の魔法\n\nContext:\na\n南(な)雲(ぐも)桜子。\n\n'
        'Sentence to explain:\n南雲桜子。',
      );
    });

    test('user message without context omits the Context block', () {
      expect(mangaRequest().userMessage, 'Book: T\n\nSentence to explain:\nS');
    });

    test('sonnet body', () {
      ExplanationRequest request = novelRequest();
      Map<String, dynamic> body = request.bodyFor(ExplanationPreset.sonnet);

      expect(body['model'], 'claude-sonnet-5-5');
      expect(body['max_tokens'], 4000);
      expect(body['system'], novelSystemPrompt);
      expect(body['thinking'], {'type': 'adaptive'});
      expect(body['output_config'], {
        'effort': 'low',
        'format': {'type': 'json_schema', 'schema': explanationSchema},
      });
      expect(body['messages'], [
        {'role': 'user', 'content': request.userMessage},
      ]);
      for (String key in ['temperature', 'top_p', 'top_k', 'fallbacks']) {
        expect(body.containsKey(key), isFalse, reason: key);
      }
    });

    test('haiku body', () {
      Map<String, dynamic> body =
          novelRequest().bodyFor(ExplanationPreset.haiku);

      expect(body['model'], 'claude-haiku-5-5');
      expect(body['thinking'], {'type': 'disabled'});
      expect(body['output_config'], {
        'format': {'type': 'json_schema', 'schema': explanationSchema},
      });
    });

    test('manga request uses the manga prompt', () {
      Map<String, dynamic> body =
          mangaRequest().bodyFor(ExplanationPreset.sonnet);

      expect(body['system'], mangaSystemPrompt);
      expect(
        mangaSystemPrompt,
        contains("# Input\n- The manga's title.\n"
            '- The text of the speech bubble to explain.'),
      );
      expect(mangaSystemPrompt, isNot(contains('Context:')));
    });
  });

  group('limitContext', () {
    test('keeps context that fits', () {
      expect(limitContext(['ab', 'cd'], maxLength: 4), ['ab', 'cd']);
    });

    test('drops the oldest paragraphs first', () {
      expect(limitContext(['ab', 'cd', 'ef'], maxLength: 4), ['cd', 'ef']);
    });

    test('sends no context when the tapped paragraph alone is too long', () {
      expect(limitContext(['ab', 'cdefg'], maxLength: 4), isEmpty);
    });

    test('defaults to 2000 characters', () {
      String long = 'あ' * 1500;

      expect(limitContext([long, long]), [long]);
    });
  });

  group('ExplanationPreset', () {
    test('preset from key', () {
      expect(ExplanationPreset.fromKey('haiku'), ExplanationPreset.haiku);
      expect(ExplanationPreset.fromKey('sonnet'), ExplanationPreset.sonnet);
      expect(ExplanationPreset.fromKey('nonsense'), ExplanationPreset.sonnet);
    });
  });

  group('SentenceExplanation', () {
    test('parses text blocks and skips thinking', () {
      SentenceExplanation explanation =
          SentenceExplanation.fromResponse(response(
        '{"translation": "T", "parts": [{"text": "本当の", '
        '"reading": "ほんとうの", "meaning": "real"}]}',
      ));

      expect(explanation.translation, 'T');
      expect(explanation.parts, hasLength(1));
      expect(explanation.parts.single.text, '本当の');
      expect(explanation.parts.single.reading, 'ほんとうの');
      expect(explanation.parts.single.meaning, 'real');
    });

    test('drops parts with no letters', () {
      SentenceExplanation explanation =
          SentenceExplanation.fromResponse(response(jsonEncode({
        'translation': 'T',
        'parts': [
          {'text': '？', 'reading': '', 'meaning': ''},
          {'text': '──', 'reading': '', 'meaning': ''},
          {'text': '本を', 'reading': 'ほんを', 'meaning': 'the book'},
        ],
      })));

      expect(explanation.parts.map((p) => p.text), ['本を']);
    });

    test('refusal', () {
      expect(
        failureOf(() => SentenceExplanation.fromResponse(
            response('', stopReason: 'refusal'))),
        ExplanationFailure.refusal,
      );
    });

    test('max_tokens', () {
      expect(
        failureOf(() => SentenceExplanation.fromResponse(
            response('{"transl', stopReason: 'max_tokens'))),
        ExplanationFailure.truncated,
      );
    });

    test('unparseable', () {
      expect(
        failureOf(
            () => SentenceExplanation.fromResponse(response('not json'))),
        ExplanationFailure.unparseable,
      );
      expect(
        failureOf(() => SentenceExplanation.fromResponse(
            response('{"translation": "T"}'))),
        ExplanationFailure.unparseable,
      );
    });
  });

  group('ExplanationPart', () {
    ExplanationPart part(String text, [String reading = '']) =>
        ExplanationPart(text: text, reading: reading, meaning: '');

    test('readings only on parts with kanji', () {
      expect(part('本当の').showsReading, isTrue);
      expect(part('ステフと').showsReading, isFalse);
      expect(part('ABC').showsReading, isFalse);
      expect(part('なくしかけた').showsReading, isFalse);
    });

    test('furigana over the kanji only', () {
      List<RubyTextData> furigana = part('本当の', 'ほんとうの').furigana;

      expect(furigana.map((e) => e.text), ['本当', 'の']);
      expect(furigana.map((e) => e.ruby), ['ほんとう', null]);
    });

    test('furigana falls back over the whole part', () {
      expect(part('本当の', 'まったくちがう').furigana, [
        const RubyTextData('本当の', ruby: 'まったくちがう'),
      ]);
    });
  });

  group('ExplanationFailure', () {
    test('retryable failures', () {
      expect(
        ExplanationFailure.values.where((f) => f.retryable),
        [
          ExplanationFailure.network,
          ExplanationFailure.timeout,
          ExplanationFailure.rateLimited,
          ExplanationFailure.server,
          ExplanationFailure.unparseable,
        ],
      );
    });
  });

  group('ExplanationException.displayMessage', () {
    test('adds the API message when it explains more', () {
      expect(
        ExplanationException(ExplanationFailure.badKey, 'invalid x-api-key')
            .displayMessage,
        'The API key was rejected\n\ninvalid x-api-key',
      );
      expect(
        ExplanationException(ExplanationFailure.request).displayMessage,
        'The API rejected the request',
      );
    });

    test('leaves out a network error detail', () {
      expect(
        ExplanationException(ExplanationFailure.network, 'down')
            .displayMessage,
        'Could not reach the API',
      );
    });
  });
}
