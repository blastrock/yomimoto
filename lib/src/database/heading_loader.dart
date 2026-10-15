import 'package:collection/collection.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

/// Load the headings with these [headingIds], fully: entries with their
/// dictionaries and tags, pitches, frequencies, heading tags, and the
/// frequencies given for each term without a reading. Returns them in the
/// order of [headingIds]; ids with no heading are skipped. Usable from any
/// isolate.
Future<List<DictionaryHeading>> loadHeadings(
  AppDatabase database,
  List<int> headingIds,
) async {
  if (headingIds.isEmpty) {
    return [];
  }

  Map<int, Dictionary> dictionariesById = {
    for (Dictionary dictionary in await database.allDictionaries().get())
      dictionary.id: dictionary,
  };

  Map<int, DictionaryHeading> headingsById = {
    for (HeadingRow row in await database.headingsByIds(ids: headingIds).get())
      row.id: DictionaryHeading(
        id: row.id,
        term: row.term,
        reading: row.reading,
      ),
  };
  List<int> ids = headingsById.keys.toList();

  Map<int, DictionaryEntry> entriesById = {};
  for (EntryRow row in await database.entriesByHeadings(ids: ids).get()) {
    DictionaryHeading heading = headingsById[row.headingId]!;
    DictionaryEntry entry = DictionaryEntry(
      id: row.id,
      definitions: row.definitions,
      popularity: row.popularity,
      dictionary: dictionariesById[row.dictionaryId]!,
    )..heading = heading;
    heading.entries.add(entry);
    entriesById[row.id] = entry;
  }

  for (PitchRow row in await database.pitchesByHeadings(ids: ids).get()) {
    headingsById[row.headingId]!.pitches.add(DictionaryPitch(
          id: row.id,
          downstep: row.downstep,
          dictionary: dictionariesById[row.dictionaryId]!,
        ));
  }

  for (FrequencyRow row
      in await database.frequenciesByHeadings(ids: ids).get()) {
    headingsById[row.headingId]!
        .frequencies
        .add(_frequency(row, dictionariesById));
  }

  for (HeadingTagsByHeadingsResult row
      in await database.headingTagsByHeadings(ids: ids).get()) {
    headingsById[row.ownerId]!.tags.add(_tag(row.tag));
  }

  for (EntryTagsByEntriesResult row in await database
      .entryTagsByEntries(ids: entriesById.keys.toList())
      .get()) {
    entriesById[row.ownerId]!.tags.add(_tag(row.tag));
  }

  Map<String, List<DictionaryHeading>> headingsWithReadingByTerm = groupBy(
    headingsById.values.where((heading) => heading.reading.isNotEmpty),
    (heading) => heading.term,
  );
  for (NoReadingFrequenciesResult row in await database
      .noReadingFrequencies(terms: headingsWithReadingByTerm.keys.toList())
      .get()) {
    for (DictionaryHeading heading in headingsWithReadingByTerm[row.term]!) {
      heading.noReadingFrequencies
          .add(_frequency(row.frequency, dictionariesById));
    }
  }

  return headingIds.map((id) => headingsById[id]).nonNulls.toList();
}

DictionaryFrequency _frequency(
  FrequencyRow row,
  Map<int, Dictionary> dictionariesById,
) {
  return DictionaryFrequency(
    id: row.id,
    value: row.value,
    displayValue: row.displayValue,
    dictionary: dictionariesById[row.dictionaryId]!,
  );
}

DictionaryTag _tag(TagRow row) {
  return DictionaryTag(
    id: row.id,
    dictionaryId: row.dictionaryId,
    name: row.name,
    category: row.category,
    sortingOrder: row.sortingOrder,
    notes: row.notes,
    popularity: row.popularity,
  );
}
