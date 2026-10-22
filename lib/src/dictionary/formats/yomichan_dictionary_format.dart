import 'dart:convert';
import 'dart:io';

import 'package:async_zip/async_zip.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  /// import, search and display defined with a set of top-level helper methods.
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
}

/// Extracts the archive's resources in an isolate of its own, through
/// `compute`: call it from the main isolate, not from inside `compute`. See
/// [DictionaryFormat] for details.
Future<void> prepareDirectoryYomichanFormat(
        PrepareDirectoryParams params) =>
    compute(extractYomichanResources, params);

/// Reads the dictionary's name in an isolate of its own, through `compute`:
/// call it from the main isolate, not from inside `compute`. See
/// [DictionaryFormat] for details.
Future<String> prepareNameYomichanFormat(PrepareDirectoryParams params) =>
    compute(readYomichanTitle, params.file.path);

/// Whether [entryName] is a JSON bank file at the root of the archive that the
/// import does not read, such as `kanji_meta_bank_1.json`.
bool _isRootBankFile(String entryName) =>
    !entryName.contains('/') &&
    entryName.contains('_bank_') &&
    entryName.endsWith('.json');

/// Where to extract the archive entry [entryName] below [resourceDirectory],
/// or null if it must not be extracted: the index and the bank files at the
/// root (read from the archive itself, or not read at all) are not resources,
/// directories are created as needed, and a name that is absolute or leads
/// outside [resourceDirectory] is refused.
String? yomichanResourcePath(String resourceDirectory, String entryName) {
  if (entryName == 'index.json' ||
      entryName.endsWith('/') ||
      isYomichanBank(entryName) ||
      _isRootBankFile(entryName)) {
    return null;
  }
  String target = path.join(resourceDirectory, entryName);
  if (path.isAbsolute(entryName) ||
      !path.isWithin(resourceDirectory, target)) {
    return null;
  }
  return target;
}

/// Top-level function for use in compute. Reads the trimmed title from the
/// `index.json` of the archive at [archivePath].
String readYomichanTitle(String archivePath) {
  ZipFileReaderSync reader = ZipFileReaderSync()..open(File(archivePath));
  try {
    Map<String, dynamic> index =
        jsonDecode(utf8.decode(reader.read('index.json')));
    return (index['title'] as String).trim();
  } finally {
    reader.close();
  }
}

/// Top-level function for use in compute. Extracts the files of the archive
/// that are not read from it directly (see [yomichanResourcePath]), which are
/// the resources definitions refer to, such as images and stylesheets.
void extractYomichanResources(PrepareDirectoryParams params) {
  ZipFileReaderSync reader = ZipFileReaderSync()..open(params.file);
  try {
    int n = 0;
    for (ZipEntry entry in reader.entries()) {
      String? target =
          yomichanResourcePath(params.resourceDirectory.path, entry.name);
      if (target == null) {
        continue;
      }
      File file = File(target);
      file.parent.createSync(recursive: true);
      reader.readToFile(entry.name, file);
      n++;
      params.send(t.import_extract_count(n: n));
    }
  } finally {
    reader.close();
  }
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
void importDataYomichanFormat({
  required PrepareDictionaryParams params,
  required Database database,
  required int dictionaryId,
}) {
  ZipFileReaderSync reader = ZipFileReaderSync()..open(params.file);
  try {
    importYomichanBanks(
      database: database,
      dictionaryId: dictionaryId,
      banks: [
        for (ZipEntry entry in reader.entries())
          if (!entry.isDir && isYomichanBank(entry.name))
            (
              name: entry.name,
              size: entry.size,
              read: () => reader.read(entry.name),
            ),
      ],
      onProgress: params.send,
    );
  } finally {
    reader.close();
  }
}
