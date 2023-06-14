import 'package:openthesaurus/openthesaurus.dart';
import 'package:args/args.dart';
import 'dart:io';

const baseform = 'baseform';
const similar = 'similar';
const start = 'startswith';

void main(List<String> args) async {
  exitCode = 0; // presume success
  final parser = ArgParser()
    ..addFlag(similar, negatable: true, abbr: 's')
    ..addFlag(start, negatable: true, abbr: 'w')
    ..addFlag(baseform, negatable: true, abbr: 'b');

  ArgResults argResults = parser.parse(args);
  final query = argResults.rest[0];

  var ot = OpenThesaurus.create();
  var response = await ot.getWith(query,
      similar: argResults[similar] as bool,
      startsWith: argResults[start] as bool,);
  for (var syn in response.synonymSet!) {
    print(syn.terms?.map((e) => e.term).toList());
  }

  for (var syn in response.similarTerms!) {
    print('${syn.term}:${syn.distance}');
  }
}
