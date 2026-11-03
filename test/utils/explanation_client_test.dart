import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yuuna/utils.dart';

void main() {
  ExplanationRequest request() => ExplanationRequest(
        title: 'T',
        sentence: '本を読む。',
        kind: ExplanationKind.novel,
      );

  String answer = jsonEncode({
    'translation': 'I read a book.',
    'parts': [
      {'text': '本を', 'reading': 'ほんを', 'meaning': 'a book'},
    ],
  });

  String validResponse = jsonEncode({
    'stop_reason': 'end_turn',
    'content': [
      {'type': 'text', 'text': answer},
    ],
  });

  Future<ExplanationFailure> failureOf(Future<void> Function() call) async {
    try {
      await call();
    } on ExplanationException catch (e) {
      return e.failure;
    }
    throw StateError('no ExplanationException');
  }

  Future<ExplanationException> exceptionFor(int status, String body) async {
    try {
      await explainSentence(
        apiKey: 'k',
        preset: ExplanationPreset.sonnet,
        request: request(),
        client: MockClient((_) async => http.Response(body, status)),
      );
    } on ExplanationException catch (e) {
      return e;
    }
    throw StateError('no ExplanationException');
  }

  test('sends the request', () async {
    late http.Request sent;
    ExplanationRequest explained = request();

    SentenceExplanation explanation = await explainSentence(
      apiKey: 'k',
      preset: ExplanationPreset.haiku,
      request: explained,
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          validResponse,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], 'k');
    expect(sent.headers['anthropic-version'], '2026-10-21');
    expect(sent.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), explained.bodyFor(ExplanationPreset.haiku));
    expect(explanation.translation, 'I read a book.');
    expect(explanation.parts.single.text, '本を');
  });

  test('empty key', () async {
    bool called = false;

    ExplanationFailure failure = await failureOf(() => explainSentence(
          apiKey: '  ',
          preset: ExplanationPreset.sonnet,
          request: request(),
          client: MockClient((_) async {
            called = true;
            return http.Response(validResponse, 200);
          }),
        ));

    expect(failure, ExplanationFailure.noApiKey);
    expect(called, isFalse);
  });

  test('maps HTTP errors with the API message', () async {
    String body = jsonEncode({
      'type': 'error',
      'error': {'type': 'x', 'message': 'boom'},
    });
    Map<int, ExplanationFailure> expected = {
      401: ExplanationFailure.badKey,
      403: ExplanationFailure.badKey,
      429: ExplanationFailure.rateLimited,
      500: ExplanationFailure.server,
      529: ExplanationFailure.server,
      400: ExplanationFailure.request,
    };

    for (MapEntry<int, ExplanationFailure> entry in expected.entries) {
      ExplanationException exception = await exceptionFor(entry.key, body);

      expect(exception.failure, entry.value, reason: '${entry.key}');
      expect(exception.message, 'boom', reason: '${entry.key}');
    }
  });

  test('maps HTTP errors without a JSON body', () async {
    ExplanationException exception =
        await exceptionFor(503, '<html>unavailable</html>');

    expect(exception.failure, ExplanationFailure.server);
    expect(exception.message, isNull);
  });

  test('network error', () async {
    for (Exception error in [
      http.ClientException('down'),
      const SocketException('down'),
    ]) {
      ExplanationFailure failure = await failureOf(() => explainSentence(
            apiKey: 'k',
            preset: ExplanationPreset.sonnet,
            request: request(),
            client: MockClient((_) async => throw error),
          ));

      expect(failure, ExplanationFailure.network, reason: '$error');
    }
  });

  test('timeout', () async {
    ExplanationFailure failure = await failureOf(() => explainSentence(
          apiKey: 'k',
          preset: ExplanationPreset.sonnet,
          request: request(),
          timeout: const Duration(milliseconds: 10),
          client: MockClient((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return http.Response(validResponse, 200);
          }),
        ));

    expect(failure, ExplanationFailure.timeout);
  });

  test('decodes UTF-8', () async {
    SentenceExplanation explanation = await explainSentence(
      apiKey: 'k',
      preset: ExplanationPreset.sonnet,
      request: request(),
      client: MockClient((_) async => http.Response.bytes(
            utf8.encode(validResponse),
            200,
            headers: {'content-type': 'application/json'},
          )),
    );

    expect(explanation.parts.single.reading, 'ほんを');
  });

  group('testApiKey', () {
    test('sends a one-token request to the preset model', () async {
      late http.Request sent;

      await testApiKey(
        apiKey: ' k ',
        preset: ExplanationPreset.haiku,
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'stop_reason': 'max_tokens',
              'content': [
                {'type': 'text', 'text': 'Hello'},
              ],
            }),
            200,
          );
        }),
      );

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent.headers['x-api-key'], 'k');
      expect(sent.headers['anthropic-version'], '2026-10-21');
      expect(jsonDecode(sent.body), {
        'model': 'claude-haiku-5-5',
        'max_tokens': 1,
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
      });
    });

    test('empty key', () async {
      bool called = false;

      ExplanationFailure failure = await failureOf(() => testApiKey(
            apiKey: '  ',
            preset: ExplanationPreset.sonnet,
            client: MockClient((_) async {
              called = true;
              return http.Response('{}', 200);
            }),
          ));

      expect(failure, ExplanationFailure.noApiKey);
      expect(called, isFalse);
    });

    test('maps HTTP errors with the API message', () async {
      Future<ExplanationException> exceptionFor(int status) async {
        try {
          await testApiKey(
            apiKey: 'k',
            preset: ExplanationPreset.sonnet,
            client: MockClient((_) async => http.Response(
                  jsonEncode({
                    'type': 'error',
                    'error': {'type': 'x', 'message': 'no credit'},
                  }),
                  status,
                )),
          );
        } on ExplanationException catch (e) {
          return e;
        }
        throw StateError('no ExplanationException');
      }

      Map<int, ExplanationFailure> expected = {
        401: ExplanationFailure.badKey,
        400: ExplanationFailure.request,
        402: ExplanationFailure.request,
        404: ExplanationFailure.request,
      };

      for (MapEntry<int, ExplanationFailure> entry in expected.entries) {
        ExplanationException exception = await exceptionFor(entry.key);

        expect(exception.failure, entry.value, reason: '${entry.key}');
        expect(exception.message, 'no credit', reason: '${entry.key}');
      }
    });

    test('network error', () async {
      ExplanationFailure failure = await failureOf(() => testApiKey(
            apiKey: 'k',
            preset: ExplanationPreset.sonnet,
            client: MockClient((_) async => throw http.ClientException('down')),
          ));

      expect(failure, ExplanationFailure.network);
    });
  });
}
