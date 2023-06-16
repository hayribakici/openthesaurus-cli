# openthesaurus-cli

This is a cross platform command line application for accessing the API of [openthesaurus](https://openthesaurus.de).

## Usage

### dart

Run program with dart

```bash
dart run src/main.dart <query>
```

### Run as binary

* macOS, linux: `./ot.exe <query>`
* windows : `ot.exe <query>`

### Options

Run openthesaurus with the following options

```bash
ot [options] <query>

Options:
-a, --similar                Return similar spelled words, helpful for misspellings
-b, --sub                    Return words that are more specific to the query
-e, --baseform               Return the base form of the queried word
-f, --from=<NUMBER>          Return substrings with the starting position. Can only be used with '--start' flag
-m, --maxResults=<NUMBER>    Limit the number of substring results. Can only be used with '--start' flag
-p, --sup                    Return words that are more generic to the query
-s, --startswith             Return words that have the same starting letters as the query
```
