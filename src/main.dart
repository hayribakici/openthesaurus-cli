import 'dart:async';

import 'package:openthesaurus/openthesaurus.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'dart:io';

const baseForm = 'baseform';
const similar = 'similar';
const start = 'startswith';
const subSet = 'sub';
const superSet = 'sup';
const from = 'from';
const maxResults = 'maxResults';

void main(List<String> args) async {
  exitCode = 0; // presume success
  final parser = ArgParser()
    ..addFlag(similar,
        negatable: false,
        help: 'Return similar spelled words, helpful for misspellings',
        abbr: 'a')
    ..addFlag(start,
        negatable: false,
        help: 'Return words that have the same starting letters as the query',
        abbr: 's')
    ..addFlag(subSet,
        negatable: false,
        help: 'Return words that are more specific to the query',
        abbr: 'u')
    ..addFlag(superSet,
        negatable: false,
        help: 'Return words that are more generic to the query',
        abbr: 'p')
    ..addFlag(baseForm, negatable: false, abbr: 'b');

  ArgResults argResults = parser.parse(args);
  final query = argResults.rest[0];
  var withSimilar = argResults[similar] as bool;
  var withStart = argResults[start] as bool;
  var withBaseForm = argResults[baseForm] as bool;
  var superSets = argResults[superSet] as bool;
  var subSets = argResults[subSet] as bool;

  var ot = OpenThesaurus.create();
  var response = await ot.getWith(query,
      similar: withSimilar,
      startsWith: withStart,
      baseForm: withBaseForm,
      superSet: superSets,
      subSet: subSets);

  final buffer = StringBuffer();
  buffer.writeln(query);
  for (int i = 0; i < query.length; i++) {
    buffer.write('=');
  }
  synonyms(buffer, response);
  if (withSimilar) {
    similars(buffer, response);
  }
  print(buffer.toString());
}

void synonyms(StringBuffer buffer, OpenThesaurusResponse response) {
  buffer.writeln('\n\nSynoyme:');
  buffer.writeln('');

  var synSet = response.synonymSet!;

  for (var syn in synSet) {
    if (syn.categories?.isNotEmpty ?? false) {
      buffer.writeln('Kategorien: ${syn.categories?.join(', ')}');
    }

    buffer.write('* ');
    buffer.writeln(synTerms(syn.terms));
    if (syn.superSet?.isNotEmpty ?? false) {
      buffer.writeln('** Oberbegriffe: ${synTerms(syn.superSet)}');
    }

    if (syn.subSet?.isNotEmpty ?? false) {
      buffer.writeln('** Unterbegriffe: ${synTerms(syn.subSet)}');
    }

    buffer.writeln('');
  }
}

void similars(StringBuffer buffer, OpenThesaurusResponse response) {
  buffer.writeln('\nÄhnliche Wörter:\n');

  var sim = response.similarTerms;
  buffer.writeln('* ${terms(sim)}');
}

String synTerms(List<SynonymTerm>? terms) =>
    terms?.map((term) {
      var out = '${term.term}';
      if (term.level != null) {
        out += ' (${term.level?.abbr})';
      }
      return out;
    }).join(', ') ??
    '';

String terms(List<Term>? terms) =>
    terms?.map((term) => term.term).join(', ') ?? '';




// class SubStringCommand extends BaseCommand {

//   SubStringBaseCommand() {
//   }: super();

// }
