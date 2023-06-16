// Copyright (c) 2023, hayribakici. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

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
            'Return substrings with the starting position. Can only be used with \'--start\' flag',
        abbr: 'f',
        valueHelp: 'NUMBER')
    ..addOption(maxResults,
        help:
            'Limit the number of substring results. Can only be used with \'--start\' flag',
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
    ..addCommand('help');

  ArgResults argResults = parser.parse(args);
  ArgResults? help = argResults.command;
  if (help != null) {
    print(chalk.bold.white('ot [options] <query>'));
    print('\nOptions:');
    print(parser.usage);
    return;
  }
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
  var withFromOption = int.tryParse(argResults[from] ?? '');
  var withMaxOption = int.tryParse(argResults[maxResults] ?? '');

  if ((withFromOption != null || withMaxOption != null) && !withStart) {
    print('Use options \'from\' and \'maxResults\' with \'--start\' (-s) flag.');
    exitCode = 1;
    return;
  }

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
  synonyms(buffer, response, query);
  if (withSimilar || withStart) {
    similars(buffer, response, withSimilar, withStart);
  }
  if (withBaseForm && (response.baseForms?.isNotEmpty ?? false)) {
    buffer.writeln('');
    buffer.writeln(chalk.bold.white('Wörter mit gleicher Grundform:'));
    buffer.writeln(response.baseForms?.join(', '));
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
