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
    print('Enter a query to retrieve synonums.');
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
      baseForm: withBaseForm,
      superSet: withSuperSets,
      subSet: withSubSets,
      from: withFromOption ?? 0,
      max: withMaxOption ?? 10);

  final buffer = StringBuffer();
  buffer.writeln(chalk.bold.saddleBrown(query));
  for (int i = 0; i < query.length; i++) {
    buffer.write(chalk.saddleBrown('='));
  }
  synonyms(buffer, response);
  if (withSimilar || withStart) {
    buffer.writeln('Teilwort-Treffer und ähnlich geschriebene Wörter:');
    if (withSimilar) {
      similars(buffer, response);
    }
    if (withStart) {
      var start = response.startsWithTerms;
      buffer.writeln(terms(start));
    }
  }
  if (withBaseForm) {
    buffer.writeln('\nWörter mit gleicher Grundform:\n');
  }
  print(buffer.toString());
}

void synonyms(StringBuffer buffer, OpenThesaurusResponse response) {
  // buffer.writeln('\n\nSynoyme:');
  buffer.writeln('\n');

  var synSet = response.synonymSet!;

  for (var syn in synSet) {
    if (syn.categories?.isNotEmpty ?? false) {
      var label = syn.categories?.length == 1 ? 'Kategorie:' : 'Kategoren:';
      buffer.writeln(chalk.slateGray(label, syn.categories?.join(', ')));
    }

    buffer.write(chalk.blue('* '));
    buffer.writeln('${chalk.bold.white('Synonyme:')} ${synTerms(syn.terms)}');
    if (syn.superSet?.isNotEmpty ?? false) {
      buffer.writeln(
          '${chalk.blue('**')} ${chalk.gray('Oberbegriffe:')} ${synTerms(syn.superSet)}');
    }

    if (syn.subSet?.isNotEmpty ?? false) {
      buffer.writeln(
          '${chalk.blue('**')} ${chalk.gray('Unterbegriffe:')} ${synTerms(syn.subSet)}');
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
