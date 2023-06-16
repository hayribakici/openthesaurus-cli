# openthesaurus-cli

This is a cross platform command line application for accessing the API of [openthesaurus](https://openthesaurus.de).

## Usage

### dart

Run program with dart

```
dart run src/ot.dart <query>
```

### binary (macOS, linux)

```terminal
./ot <query>
```

### Options

Run openthesaurus with the following options

```
ot [options] <query>

Options:
-a, --similar       Return similar spelled words, helpful for misspellings
-b, --sub           Return words that are more specific to the query
-p, --sup           Return words that are more generic to the query
-s, --startswith    Return words that have the same starting letters as the query
-f, --from          Return substrings with the starting position
-m, --maxResults    Limit the number of substring results
-e, --baseform      Return the base form of the queried word
```
