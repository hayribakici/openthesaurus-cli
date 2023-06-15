import 'package:openthesaurus/openthesaurus.dart';
import 'package:args/args.dart';
import 'dart:io';

const baseform = 'baseform';
const similar = 'similar';
const start = 'startswith';

void main(List<String> args) async {
  exitCode = 0; // presume success
  final parser = ArgParser()
    ..addFlag(similar,
        negatable: false,
        help: 'Return similar spelled words, helpful for misspellings',
        abbr: 's')
    ..addFlag(start,
        negatable: false,
        help: 'Return words that have the same starting letters as the query',
        abbr: 'w')
    ..addFlag(baseform, negatable: false, abbr: 'b');

  if (args.isEmpty) {
    print(parser.usage);
    return;
  }
  ArgResults argResults = parser.parse(args);
  final query = argResults.rest[0];
  var withSimilar = argResults[similar] as bool;
  var withStart = argResults[start] as bool;
  var withBaseForm = argResults[baseform] as bool;

  var ot = OpenThesaurus.create();
  var response = await ot.getWith(
    query,
    similar: withSimilar,
    startsWith: withStart,
    baseForm: withBaseForm
  );

  for (var syn in response.synonymSet!) {
    print(syn.terms?.map((e) => e.term).toList());
  }

  for (var syn in response.similarTerms!) {
    print('${syn.term}:${syn.distance}');
  }
}
