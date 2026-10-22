import 'dart:convert';
import 'dart:io';

import 'package:async_zip/async_zip.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:list_counter/list_counter.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/utils.dart';

/// A dictionary format for archives following the latest Yomichan bank schema.
/// Example dictionaries for this format may be downloaded from the Yomichan
/// website.
///
/// Details on the format can be found here:
/// https://github.com/FooSoft/yomichan/blob/master/ext/data/schemas/dictionary-term-bank-v3-schema.json
class YomichanFormat extends DictionaryFormat {
  /// Define a format with the given metadata that has its behaviour for
  /// import, search and display defined with af set of top-level helper methods.
  YomichanFormat._privateConstructor()
      : super(
          uniqueKey: 'yomichan',
          name: 'Yomichan Dictionary',
          icon: Icons.auto_stories_rounded,
          allowedExtensions: const ['zip'],
          fileType: FileType.custom,
          prepareDirectory: prepareDirectoryYomichanFormat,
          prepareName: prepareNameYomichanFormat,
          importData: importDataYomichanFormat,
        );

  /// Get the singleton instance of this dictionary format.
  static YomichanFormat get instance => _instance;

  static final YomichanFormat _instance = YomichanFormat._privateConstructor();

  /// If true, uses the [customDefinitionWidget] instead.
  @override
  bool shouldUseCustomDefinitionWidget(String definition) {
    try {
      jsonDecode(definition);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String getCustomDefinitionText(String meaning) {
    final node =
        StructuredContent.processContent(jsonDecode(meaning))?.toNode();
    if (node == null) {
      return '';
    }

    final document = dom.Document.html('');
    document.body?.append(node);
    for (final e in document.querySelectorAll('li')) {
      final css = e.bs4.findParent('ul')?.attributes['style'] ?? '';
      final text = e.text;
      final name = css
              .split(';')
              .firstWhere((e) => e.contains('list-style-type'))
              .split(':')
              .lastOrNull ??
          'square';

      final counterStyle = CounterStyleRegistry.lookup(name);
      final counter = counterStyle.generateMarkerContent(0);
      e.text = '$counter $text';
    }
    document.querySelectorAll('table').map((e) => e.remove());
    final html = document.body?.innerHtml ?? '';

    return BeautifulSoup(html).getText(separator: '\n');
  }

  /// Recursively get HTML for a structured content definition.
  static String getStructuredContentHtml(dynamic content) {
    if (content is Map) {
      return getNodeHtml(
        tag: content['tag'],
        content: getStructuredContentHtml(content['content']),
        style: getStyle(
          content['style'] ?? {},
        ),
      );
    } else if (content is List) {
      return content.map(getStructuredContentHtml).join();
    }

    return content;
  }

  /// Convert style to appropriate format.
  static Map<String, String> getStyle(Map<String, dynamic> styleMap) {
    return Map<String, String>.fromEntries(
      styleMap.entries.map(
        (e) => MapEntry(
          ReCase(e.key).paramCase,
          e.value.toString(),
        ),
      ),
    );
  }

  /// Get the HTML for a certain node.
  static String getNodeHtml({
    required String content,
    String? tag,
    Map<String, String> style = const {},
  }) {
    if (tag == null) {
      return content;
    }

    dom.Element element = dom.Element.tag(tag);
    element.attributes.addAll(style);

    element.innerHtml = content;

    return element.outerHtml;
  }

  /// For [prepareEntriesYomichanFormat].
  static String? processDefinition(dynamic definition) {
    if (definition is String) {
      final plainText = definition;
      return plainText;
    } else if (definition is Map) {
      final type = definition['type'];

      switch (type) {
        case 'text':
          final plainText = definition['text'];
          return plainText;
        case 'structured-content':
        case 'image':
          return jsonEncode(definition['content']);
      }
    }

    return null;
  }
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
Future<void> prepareDirectoryYomichanFormat(
    PrepareDirectoryParams params) async {
  int n = 0;
  extractZipArchiveSync(params.file, params.resourceDirectory,
      callback: (_, _) {
    n++;
    params.send(t.import_extract_count(n: n));
  });
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
Future<String> prepareNameYomichanFormat(PrepareDirectoryParams params) async {
  /// Get the index, which contains the name of the dictionary contained by
  /// the archive.
  String indexFilePath = path.join(params.resourceDirectory.path, 'index.json');
  File indexFile = File(indexFilePath);
  String indexJson = indexFile.readAsStringSync();
  Map<String, dynamic> index = jsonDecode(indexJson);

  String dictionaryName = (index['title'] as String).trim();
  return dictionaryName;
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
void importDataYomichanFormat({
  required PrepareDictionaryParams params,
  required Database database,
  required int dictionaryId,
}) {
  DictionaryImportWriter writer = DictionaryImportWriter(
    database: database,
    dictionaryId: dictionaryId,
  );
  try {
    prepareTagsYomichanFormat(params: params, writer: writer);
    prepareEntriesYomichanFormat(params: params, writer: writer);
    preparePitchesYomichanFormat(params: params, writer: writer);
    prepareFrequenciesYomichanFormat(params: params, writer: writer);
  } finally {
    writer.close();
  }
}

/// Writes the entries of the dictionary through [writer].
void prepareEntriesYomichanFormat({
  required PrepareDictionaryParams params,
  required DictionaryImportWriter writer,
}) {
  final List<FileSystemEntity> entities = params.resourceDirectory.listSync();
  final Iterable<File> files = entities.whereType<File>();

  int n = 0;
  int total = 0;

  for (File file in files) {
    String filename = path.basename(file.path);
    if (filename.startsWith('term_bank') || filename.startsWith('kanji_bank')) {
      String json = file.readAsStringSync();
      List<dynamic> items = jsonDecode(json);
      total += items.length;

      params.send(t.import_found_entry(count: total));
    }
  }

  for (File file in files) {
    String filename = path.basename(file.path);
    if (filename.startsWith('term_bank')) {
      List<dynamic> items = jsonDecode(file.readAsStringSync());

      for (List<dynamic> item in items) {
        final String term = item[0];
        final String reading = item[1];
        final String? spaceSeparatedDefinitionTags = item[2];
        // final String ruleIdentifier = item[3];
        final num rawPopularity = item[4];
        final List<dynamic> rawDefinitions = item[5];
        // final int sequenceNumber = item[6];
        final String spaceSeparatedTermTags = item[7];

        double popularity = rawPopularity.toDouble();
        List<String> entryTagNames =
            spaceSeparatedDefinitionTags?.split(' ') ?? [];
        List<String> headingTagNames = spaceSeparatedTermTags.split(' ');
        final List<String> definitions = rawDefinitions
            .map(YomichanFormat.processDefinition)
            .whereType<String>()
            .toList();

        writer.addEntry(
          headingId: writer.headingId(term: term, reading: reading),
          definitions: definitions,
          popularity: popularity,
          entryTagNames: entryTagNames,
          headingTagNames: headingTagNames,
        );

        n++;
        params.send(t.import_write_entry(
          count: n,
          total: total,
        ));
      }
    } else if (filename.startsWith('kanji_bank')) {
      List<dynamic> items = jsonDecode(file.readAsStringSync());

      for (List<dynamic> item in items) {
        String term = item[0] as String;
        List<String> onyomis = (item[1] as String).split(' ');
        List<String> kunyomis = (item[2] as String).split(' ');
        List<String> headingTagNames = (item[3] as String).split(' ');
        List<String> meanings = List<String>.from(item[4]);

        StringBuffer buffer = StringBuffer();
        if (onyomis.join().trim().isNotEmpty) {
          buffer.write('音読み\n');
          for (String onyomi in onyomis) {
            buffer.write('  • $onyomi\n');
          }
          buffer.write('\n');
        }
        if (kunyomis.join().trim().isNotEmpty) {
          buffer.write('訓読み\n');
          for (String kun in kunyomis) {
            buffer.write('  • $kun\n');
          }
          buffer.write('\n');
        }
        if (meanings.isNotEmpty) {
          buffer.write('意味\n');
          for (String meaning in meanings) {
            buffer.write('  • $meaning\n');
          }
          buffer.write('\n');
        }

        String definition = buffer.toString().trim();

        if (definition.isNotEmpty) {
          writer.addEntry(
            headingId: writer.headingId(term: term, reading: ''),
            definitions: [definition],
            popularity: 0,
            headingTagNames: headingTagNames,
          );

          n++;
          params.send(t.import_write_entry(
            count: n,
            total: total,
          ));
        }
      }
    }
  }
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
void prepareTagsYomichanFormat({
  required PrepareDictionaryParams params,
  required DictionaryImportWriter writer,
}) {
  final List<FileSystemEntity> entities = params.resourceDirectory.listSync();
  final Iterable<File> files = entities.whereType<File>();

  int n = 0;
  int count = 0;

  for (File file in files) {
    String filename = path.basename(file.path);
    if (filename.startsWith('tag_bank')) {
      String json = file.readAsStringSync();
      List<dynamic> items = jsonDecode(json);
      count += items.length;

      params.send(t.import_found_tag(count: count));
    }
  }

  for (File file in files) {
    String filename = path.basename(file.path);
    if (!filename.startsWith('tag_bank')) {
      continue;
    }

    String json = file.readAsStringSync();
    List<dynamic> items = jsonDecode(json);

    for (List<dynamic> item in items) {
      String name = item[0] as String;
      String category = item[1] as String;
      int sortingOrder = item[2] as int;
      String notes = item[3] as String;
      double popularity = (item[4] as num).toDouble();

      writer.addTag(
        name: name,
        category: category,
        sortingOrder: sortingOrder,
        notes: notes,
        popularity: popularity,
      );

      n++;
      params.send(t.import_write_tag(
        count: n,
        total: count,
      ));
    }
  }
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
void preparePitchesYomichanFormat({
  required PrepareDictionaryParams params,
  required DictionaryImportWriter writer,
}) {
  final List<FileSystemEntity> entities = params.resourceDirectory.listSync();
  final Iterable<File> files = entities.whereType<File>();

  int n = 0;
  int count = 0;

  for (File file in files) {
    String filename = path.basename(file.path);
    if (filename.startsWith('term_meta_bank')) {
      String json = file.readAsStringSync();
      List<dynamic> items = jsonDecode(json);
      count += items.length;

      params.send(t.import_found_pitch(count: count));
    }
  }

  for (File file in files) {
    String filename = path.basename(file.path);
    if (!filename.startsWith('term_meta_bank')) {
      continue;
    }

    String json = file.readAsStringSync();
    List<dynamic> items = jsonDecode(json);

    for (List<dynamic> item in items) {
      String term = item[0] as String;
      String type = item[1] as String;

      if (type == 'pitch') {
        Map<String, dynamic> data = Map<String, dynamic>.from(item[2]);
        String reading = data['reading'] ?? '';
        int headingId = writer.headingId(term: term, reading: reading);

        List<Map<String, dynamic>> distinctPitchJsons =
            List<Map<String, dynamic>>.from(data['pitches']);
        for (Map<String, dynamic> distinctPitch in distinctPitchJsons) {
          int downstep = distinctPitch['position'];
          writer.addPitch(headingId: headingId, downstep: downstep);
        }
      } else {
        continue;
      }
    }

    params.send(t.import_write_pitch(count: n, total: count));
  }
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
void prepareFrequenciesYomichanFormat({
  required PrepareDictionaryParams params,
  required DictionaryImportWriter writer,
}) {
  final List<FileSystemEntity> entities = params.resourceDirectory.listSync();
  final Iterable<File> files = entities.whereType<File>();

  int n = 0;
  int count = 0;

  for (File file in files) {
    String filename = path.basename(file.path);
    if (filename.startsWith('term_meta_bank')) {
      String json = file.readAsStringSync();
      List<dynamic> items = jsonDecode(json);
      count += items.length;

      params.send(t.import_found_frequency(count: count));
    }
  }

  for (File file in files) {
    String filename = path.basename(file.path);
    if (!filename.startsWith('term_meta_bank')) {
      continue;
    }

    String json = file.readAsStringSync();
    List<dynamic> items = jsonDecode(json);

    for (List<dynamic> item in items) {
      String term = item[0] as String;
      String type = item[1] as String;

      if (type == 'freq') {
        String? reading;
        late double value;
        late String? displayValue;

        if (item[2] is double) {
          double number = item[2] as double;

          reading = '';
          value = number;
          displayValue =
              (number % 1 == 0) ? number.toInt().toString() : number.toString();
        } else if (item[2] is int) {
          int number = item[2] as int;
          reading = '';
          value = number.toDouble();
          displayValue = number.toString();
        } else if (item[2] is Map) {
          Map<String, dynamic> data = Map<String, dynamic>.from(item[2]);

          if (data['reading'] != null && data['frequency'] is Map) {
            Map<String, dynamic> frequencyData =
                Map<String, dynamic>.from(data['frequency']);

            reading = data['reading'] ?? '';

            num number = frequencyData['value'] ?? 0;

            value = number.toDouble();
            displayValue = frequencyData['displayValue'];
          } else if (data['displayValue'] != null) {
            reading = data['reading'] ?? '';

            num number = data['value'] ?? 0;

            value = number.toDouble();
            displayValue = data['displayValue'];
          } else if (data['value'] != null) {
            reading = data['reading'] ?? '';

            num number = data['value'] ?? 0;

            value = number.toDouble();
            displayValue = number.toInt().toString();
          } else if (data['frequency'] is num) {
            num frequencyValue = data['frequency'];
            reading = data['reading'] ?? '';

            value = frequencyValue.toDouble();
            displayValue = (frequencyValue % 1 == 0)
                ? frequencyValue.toInt().toString()
                : frequencyValue.toDouble().toString();
          }
        } else {
          reading = '';

          value = 0;
          displayValue = item[2].toString();
        }

        if (reading != null) {
          writer.addFrequency(
            headingId: writer.headingId(term: term, reading: reading),
            value: value,
            displayValue: displayValue ?? '',
          );

          n++;
          params.send(t.import_write_frequency(count: n, total: count));
        }
      } else {
        continue;
      }
    }
  }
}
