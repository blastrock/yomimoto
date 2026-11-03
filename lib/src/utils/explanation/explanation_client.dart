import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yuuna/utils.dart';

/// The Messages API endpoint.
final Uri explanationEndpoint =
    Uri.parse('https://api.anthropic.com/v1/messages');

/// The API version sent with every request. Nothing this request sends is
/// affected by what `2026-10-21` changed from `2023-06-01`.
const String explanationApiVersion = '2026-10-21';

/// Ask the model to explain [request] with [preset], using [apiKey]. Throws
/// only [ExplanationException]. [client] is for tests; without one, a client
/// is created and closed for this call.
Future<SentenceExplanation> explainSentence({
  required String apiKey,
  required ExplanationPreset preset,
  required ExplanationRequest request,
  http.Client? client,
  Duration timeout = const Duration(seconds: 20),
}) async {
  String body = await _post(
    apiKey: apiKey,
    body: request.bodyFor(preset),
    client: client,
    timeout: timeout,
  );

  Map<String, dynamic> json;
  try {
    json = jsonDecode(body) as Map<String, dynamic>;
  } on FormatException {
    throw ExplanationException(ExplanationFailure.unparseable);
  } on TypeError {
    throw ExplanationException(ExplanationFailure.unparseable);
  }

  return SentenceExplanation.fromResponse(json);
}

/// Check that [apiKey] can use [preset]'s model, with a one-token request:
/// unlike listing models, it also fails when the account cannot pay. Throws
/// only [ExplanationException]. [client] is for tests.
Future<void> testApiKey({
  required String apiKey,
  required ExplanationPreset preset,
  http.Client? client,
  Duration timeout = const Duration(seconds: 20),
}) async {
  await _post(
    apiKey: apiKey,
    body: {
      'model': preset.model,
      'max_tokens': 1,
      'messages': [
        {'role': 'user', 'content': 'Hi'},
      ],
    },
    client: client,
    timeout: timeout,
  );
}

/// Send [body] to the Messages API with [apiKey] and return the body of a
/// 200 answer. Throws only [ExplanationException].
Future<String> _post({
  required String apiKey,
  required Map<String, dynamic> body,
  required http.Client? client,
  required Duration timeout,
}) async {
  String key = apiKey.trim();
  if (key.isEmpty) {
    throw ExplanationException(ExplanationFailure.noApiKey);
  }

  http.Client httpClient = client ?? http.Client();
  late http.Response response;
  try {
    response = await httpClient
        .post(
          explanationEndpoint,
          headers: {
            'content-type': 'application/json',
            'x-api-key': key,
            'anthropic-version': explanationApiVersion,
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
  } on TimeoutException {
    throw ExplanationException(ExplanationFailure.timeout);
  } on http.ClientException catch (e) {
    throw ExplanationException(ExplanationFailure.network, e.message);
  } on IOException catch (e) {
    throw ExplanationException(ExplanationFailure.network, '$e');
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }

  String text = utf8.decode(response.bodyBytes, allowMalformed: true);
  int status = response.statusCode;
  if (status != 200) {
    throw ExplanationException(_failureFor(status), _errorMessage(text));
  }

  return text;
}

ExplanationFailure _failureFor(int status) {
  if (status == 401 || status == 403) {
    return ExplanationFailure.badKey;
  }
  if (status == 429) {
    return ExplanationFailure.rateLimited;
  }
  if (status >= 500) {
    return ExplanationFailure.server;
  }

  return ExplanationFailure.request;
}

/// The `error.message` of an API error body, or null when there is none.
String? _errorMessage(String body) {
  try {
    Object? json = jsonDecode(body);
    if (json is Map && json['error'] is Map) {
      Object? message = (json['error'] as Map)['message'];
      return message is String ? message : null;
    }
  } on FormatException {
    return null;
  }

  return null;
}
