// Copyright (c) 2023, hayribakici. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:chalkdart/chalk.dart';
import 'package:openthesaurus/openthesaurus.dart';
import 'package:args/args.dart';
import 'dart:io';

const baseForm = 'baseform';
const similar = 'similar';
const start = 'startswith';
const subSet = 'sub';
const superSet = 'sup';
const from = 'from';
const maxResults = 'maxResults';
const _helpCommand = 'help';
const _infoCommand = 'info';

void main(List<String> args) async {
  exitCode = 0; // presume success
  final parser = createAndSetupArgParser();

  ArgResults argResults = parser.parse(args);
  if (_commandHandled(argResults.command, parser.usage)) {
    return;
  }
  if (argResults.rest.isEmpty) {
    print(chalk.red('Enter a query to retrieve synonyms.'));
    exitCode = 1;
    return;
  }
  final query = argResults.rest[0];
  var withStart = argResults[start] as bool;
  var withBaseForm = argResults[baseForm] as bool;
  var withSuperSets = argResults[superSet] as bool;
  var withSubSets = argResults[subSet] as bool;
  var withFromOption = int.tryParse(argResults[from] ?? '');
  var withMaxOption = int.tryParse(argResults[maxResults] ?? '');

  if ((withFromOption != null || withMaxOption != null) && !withStart) {
    print(
        'Use options \'from\' and \'maxResults\' with \'--startWith\' (-s) flag.');
    exitCode = 1;
    return;
  }

  var ot = OpenThesaurus.create();
  var response = await ot.getWithSubString(query,
      similar: true,
      startsWith: withStart,
      baseForm: withBaseForm,
      superSet: withSuperSets,
      subSet: withSubSets,
      from: withFromOption ?? 0,
      max: withMaxOption ?? 10);

  if (response.isEmpty) {
    print(chalk.red('Keine Synonyme für \'$query\' gefunden.'));
    exitCode = 1;
    return;
  }

  final buffer = StringBuffer();
  titleHeader(buffer, query);
  if (hasSynonyms(response)) {
    synonyms(buffer, response, query);
  } else {
    buffer.writeln(chalk.red('Keine Synoyme für \'$query\' gefunden.'));
    buffer.writeln();
    buffer.writeln(chalk.yellowGreen('Aber dafür ähnliche Wörter:'));
    buffer.writeln();
  }
  if (hasSimilars(response)) {
    similars(buffer, response, withStart);
  }
  if (withBaseForm && (response.baseForms?.isNotEmpty ?? false)) {
    buffer.writeln();
    buffer.writeln(chalk.bold.white('Wörter mit gleicher Grundform:'));
    buffer.writeln(response.baseForms?.join(', '));
  }
  print(buffer.toString());
}

bool _commandHandled(ArgResults? command, String usage) {
  switch (command?.name) {
    case _helpCommand:
      print(chalk.bold.white('OpenThesaurus Command Line Interface (ot)'));
      print('');
      print(chalk.white(
          'Query synonyms with ', chalk.bold.white('ot [options] <query>')));
      print('');
      print(chalk.white('Options:'));
      print(chalk.white(usage));
      return true;
    case _infoCommand:
      print(chalk.bold.white('OpenThesaurus Command Line Interface (ot)'));
      print(
          chalk.bold.white('https://github.com/hayribakici/openthesaurus-cli'));
      return true;
    default:
      return false;
  }
}

ArgParser createAndSetupArgParser() => ArgParser()
  ..addFlag(subSet,
      negatable: false,
      help: 'Return words that are more specific to the query',
      abbr: 'b')
  ..addFlag(baseForm,
      negatable: false,
      help: 'Return the base form of the queried word',
      abbr: 'e')
  ..addOption(from,
      help:
          'Return substrings with the starting position. Can only be used with \'--startWith\' flag',
      abbr: 'f',
      valueHelp: 'NUMBER')
  ..addOption(maxResults,
      help:
          'Limit the number of substring results. Can only be used with \'--startWith\' flag',
      abbr: 'm',
      valueHelp: 'NUMBER')
  ..addFlag(superSet,
      negatable: false,
      help: 'Return words that are more generic to the query',
      abbr: 'p')
  ..addFlag(start,
      negatable: false,
      help: 'Return words that have the same starting letters as the query',
      abbr: 's')
  ..addCommand(_helpCommand)
  ..addCommand(_infoCommand);

void synonyms(
    StringBuffer buffer, OpenThesaurusResponse response, String query) {
  if (response.synonymSet == null) {
    return;
  }
  buffer.writeln('${chalk.bold.white('Synonyme')}:');

  var synSet = response.synonymSet!;
  for (var syn in synSet) {
    if (syn.categories?.isNotEmpty ?? false) {
      var label = syn.categories?.length == 1 ? 'Kategorie:' : 'Kategorien:';
      buffer.write(chalk.slateGray('['));
      buffer.write(chalk.slateGray(label, syn.categories?.join(', ')));
      buffer.writeln(chalk.slateGray(']'));
    }

    buffer.writeln('${blueBullet('*')} ${synTerms(syn.terms, query)}');
    if (syn.superSet?.isNotEmpty ?? false) {
      var label = syn.superSet?.length == 1 ? 'Oberbegriff:' : 'Oberbegriffe:';
      buffer.writeln(
          '${blueBullet('  *')} ${chalk.aliceBlue(label)} ${synTerms(syn.superSet)}');
    }

    if (syn.subSet?.isNotEmpty ?? false) {
      var label =
          syn.superSet?.length == 1 ? 'Unterbegriff:' : 'Unterbegriffe:';
      buffer.writeln(
          '${blueBullet('  *')} ${chalk.aliceBlue(label)} ${synTerms(syn.subSet)}');
    }

    buffer.writeln('');
  }
}

void similars(
    StringBuffer buffer, OpenThesaurusResponse response, bool withStart) {
  List<Term> out = [];
  var sim = response.similarTerms;
  sim?.sort((t1, t2) => t1.distance?.compareTo(t2.distance!) ?? 0);
  if (sim != null) {
    out.addAll(sim);
  }
  if (withStart) {
    out.addAll(response.startsWithTerms as Iterable<Term>);
  }
  if (out.isNotEmpty) {
    buffer.writeln(
        chalk.bold.white('Teilwort-Treffer und ähnlich geschriebene Wörter:'));
    buffer.writeln(terms(out));
  }
}

void titleHeader(StringBuffer buffer, String query) {
  buffer.writeln();
  buffer.writeln(chalk.bold.saddleBrown(query));
  buffer.writeln(
      chalk.bold.saddleBrown(List.generate(query.length, (i) => '=').join()));
}

Object blueBullet(String bullet, {int length = 1}) {
  var a = List.generate(length, (index) => bullet);
  return chalk.blue(a.join());
}

Object synTerms(List<SynonymTerm>? terms, [String query = '']) =>
    terms?.map((term) {
      var out = term.term ?? '';

      if (query.toLowerCase() == out.toLowerCase()) {
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

bool hasEmptyResponse(OpenThesaurusResponse response) =>
    !hasSynonyms(response) &&
    response.baseForms == null &&
    response.similarTerms == null &&
    response.startsWithTerms == null &&
    response.subStringTerms == null;

bool hasSynonyms(OpenThesaurusResponse response) =>
    response.synonymSet?.isNotEmpty ?? false;

bool hasSimilars(OpenThesaurusResponse response) =>
    response.similarTerms?.isNotEmpty ?? false;
