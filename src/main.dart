import 'dart:ffi';

import 'package:chalkdart/chalk_x11.dart';
import 'package:openthesaurus/openthesaurus.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'package:chalkdart/chalk.dart';

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
    ..addOption(from,
        help: 'Return substrings with the starting position', abbr: 'f')
    ..addOption(maxResults,
        help: 'Limit the number of substring results', abbr: 'm')
    ..addFlag(baseForm, negatable: false, abbr: 'b');

  ArgResults argResults = parser.parse(args);
  if (argResults.rest.isEmpty) {
    print('Enter a query to retrieve synonyms.');
    exitCode = 1;
    return;
  }
  final query = argResults.rest[0];
  var withSimilar = argResults[similar] as bool;
  var withStart = argResults[start] as bool;
  var withBaseForm = argResults[baseForm] as bool;
  var withSuperSets = argResults[superSet] as bool;
  var withSubSets = argResults[subSet] as bool;
  var withFromOption = argResults[from] as int?;
  var withMaxOption = argResults[maxResults] as int?;

  var ot = OpenThesaurus.create();
  var response = await ot.getWithSubString(query,
      similar: withSimilar,
      startsWith: withStart,
      baseForm: true,
      superSet: withSuperSets,
      subSet: withSubSets,
      from: withFromOption ?? 0,
      max: withMaxOption ?? 10);

  final buffer = StringBuffer();
  buffer.writeln(chalk.bold.saddleBrown(query));
  for (int i = 0; i < query.length; i++) {
    buffer.write(chalk.saddleBrown('='));
  }
  synonyms(buffer, response, query);
  if (withSimilar || withStart) {
    similars(buffer, response, withSimilar, withStart);
  }
  if (withBaseForm && (response.baseForms?.isNotEmpty ?? false)) {
    buffer.writeln('');
    buffer.writeln(chalk.bold.white('Wörter mit gleicher Grundform:'));
    buffer.writeln(response.baseForms?.join(', '));
    // }
  }
  print(buffer.toString());
}

void synonyms(
    StringBuffer buffer, OpenThesaurusResponse response, String query) {
  buffer.writeln('\n${chalk.bold.white('Synonyme')}:');

  var synSet = response.synonymSet!;
  for (var syn in synSet) {
    if (syn.categories?.isNotEmpty ?? false) {
      var label = syn.categories?.length == 1 ? 'Kategorie:' : 'Kategoren:';
      buffer.write(chalk.slateGray(' ['));
      buffer.write(chalk.slateGray(label, syn.categories?.join(', ')));
      buffer.writeln(chalk.slateGray(']'));
    }

    buffer.writeln('${chalk.blue('*')} ${synTerms(syn.terms, query)}');
    if (syn.superSet?.isNotEmpty ?? false) {
      var label = syn.superSet?.length == 1 ? 'Oberbegriff:' : 'Oberbegriffe:';
      buffer.writeln(
          '${blueBullet('*', length: 2)} ${chalk.aliceBlue(label)} ${synTerms(syn.superSet)}');
    }

    if (syn.subSet?.isNotEmpty ?? false) {
      buffer.writeln(
          '${blueBullet('*', length: 2)} ${chalk.aliceBlue('Unterbegriffe:')} ${synTerms(syn.subSet)}');
    }

    buffer.writeln('');
  }
}

void similars(StringBuffer buffer, OpenThesaurusResponse response,
    bool withSimilar, bool withStart) {
  buffer.writeln(
      chalk.bold.white('Teilwort-Treffer und ähnlich geschriebene Wörter:'));
  List<Term> out = [];
  if (withSimilar) {
    var sim = response.similarTerms;
    sim?.sort((t1, t2) => t1.distance?.compareTo(t2.distance!) ?? 0);
    out.addAll(response.similarTerms as List<Term>);
    // buffer.write('* ${terms(sim)}');
  }
  if (withStart) {
    out.addAll(response.startsWithTerms as Iterable<Term>);
  }
  buffer.writeln(terms(out));
}

Object blueBullet(String bullet, {int length = 1}) {
  var a = List.generate(length, (index) => bullet);
  return chalk.blue(a.join());
}

Object synTerms(List<SynonymTerm>? terms, [String query = '']) =>
    terms?.map((term) {
      var out = term.term ?? '';

      if (query == out) {
        out = chalk.italic.onYellow.black(out);
      }
      if (term.level != null) {
        out += chalk.dimGray(' (${term.level?.abbr})');
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
