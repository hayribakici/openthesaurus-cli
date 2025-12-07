# openthesaurus-cli

This is a cross platform command line application for accessing the API of [openthesaurus](https://openthesaurus.de).

## Usage

### dart

Run program with dart

```bash
dart run src/main.dart <query>
```

### Run as binary

* macOS, linux: `./ot <query>`
* windows : `ot.exe <query>`

### Build yourself

You can also build it yourself with

```bash
dart compile exe bin/ot.dart -o ot
```

which creates a binary file `ot` and which you can add into your `~/bin` folder. 

### Options

Run openthesaurus with the following options

```bash
Query synonyms with  ot [options] <query>

Options:
-a, --all                    Turn on all flags
-b, --sub                    Return words that are more specific to the query
-e, --baseform               Return the base form of the queried word
-f, --from=<NUMBER>          Return substrings with the starting position. Can only be used with '--startWith' flag
-m, --maxResults=<NUMBER>    Limit the number of substring results. Can only be used with '--startWith' flag
-p, --sup                    Return words that are more generic to the query
-s, --startswith             Return words that have the same starting letters as the query
```

### Acknowledgements

This program has been inspired by [radomirbosak/duden](https://github.com/radomirbosak/duden).
