# Text encoding and missing text

## Text exchange

Use UTF-8 for data exchange.
Tabs divide fields.
Spaces can occur in NAMES text fields.
Quotation marks do not escape tabs or line breaks.

The reader returns missing text for `NA` and for an empty text field.
It also returns missing text for a literal `NA` string.
After a write operation and a read operation, an empty string becomes missing text.

| Language | Reader output for missing NAMES text |
| --- | --- |
| R | `NA` |
| Python | `None` |
| MATLAB | Text marker `NA` |
| Julia | `missing` |

## Source version 1.0.2

Version 1.0.2 is necessary for the options in this section.
Do not pass them to a 1.0.1 package.

Readers select the encoding from a byte order mark (BOM).
Without a BOM, they use UTF-8.
A BOM is necessary for UTF-16 and UTF-32 input.
An `Encoding` value that does not agree with the BOM causes an error.
Text with encoding errors also causes a reader error.

For a known legacy encoding, supply `Encoding`:

```python
x = io.ReadNAMES("names", InDirectory=directory, Encoding="Windows-1252")
```

The permitted `Encoding` values are `UTF-8`, `Windows-1252`, and `ISO-8859-1`.
`Latin-1` is an alias for `ISO-8859-1`.
Legacy decoding gives one warning.
An initial UTF-8 BOM does not cause a warning.
Writers use UTF-8 without a BOM.
They do not normalize Unicode sequences.

## Characters in text fields

In version 1.0.2, `WriteNAMES` replaces each TAB, LF, CR, or NUL character with an underscore.
The optional `TextReplacement` argument selects a different replacement string.
This string cannot be empty.
The replacement string cannot contain these four characters.
The writer does not change spaces or literal backslash sequences.
A CR followed by LF gives two replacements.

```python
io.WriteNAMES("names", ["first\tsecond"], Key=[101],
              OutDirectory=directory, TextReplacement=" ")
```

The writer gives one warning with character and field counts.
The writer also gives that warning when `Verbose=False`.
The writer does not change the caller's input values.

## Argument syntax

In R, the argument names in `...` must agree with the specified names.
Python and Julia use keyword arguments.
MATLAB uses trailing name-value pairs after the positional arguments in the common interface.
For default values of MATLAB positional arguments before the pair, supply `[]`.
Unknown or duplicate advanced options cause errors.

Refer to the [common interface](../reference/api.md) for the argument order.
