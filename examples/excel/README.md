# DataBionicIO files in Excel

Excel can open DataBionicIO text files with tab separators.
These files include `.lrn`, `.cls`, `.names`, `.dts`, and `.data`.
This procedure uses the Excel desktop application.
It uses the text file directly and does not need a DataBionicIO add-in.

## Open the file

Keep a copy of the source file.
If Excel is the default application for the file type, double-click the file.
Otherwise, open the file with Excel.

If Excel puts each line in one cell, use this procedure:

1. Select the column that contains the file lines.
2. Make sure that the columns to its right are empty.
3. Select **Data > Text to Columns**.
4. Select **Delimited**.
5. Select **Next**.
6. Select **Tab** as the only delimiter.
7. Clear **Treat consecutive delimiters as one**.
8. Set **Text qualifier** to **{none}**.
9. Select **Next**.
10. Select **Text** for identifier, name, and timestamp columns in the preview.
11. Select **Finish**.

The German menu names are **Daten > Text in Spalten > Getrennt > Tabstopp**.
Microsoft gives the [Text to Columns procedure](https://support.microsoft.com/en-us/excel/get-started/split-text-into-different-columns-with-the-convert-text-to-columns-wizard).

## Column settings

For text inspection, select **Text** for all columns before the conversion.
This setting keeps the original text for identifiers, timestamps, and missing-value tokens.
For numeric analysis, convert only the necessary data columns.
Use a decimal point for numbers from the shared C++ writers.
The **Advanced** settings in the import dialog control the decimal separator.
Microsoft gives the [text import settings](https://support.microsoft.com/en-us/excel/text-import-wizard).

Excel numeric cells have a precision limit of 15 significant digits.
Keep long keys as text, including keys near `-2^53` and `2^53`.
Also keep identifiers with leading zeros as text.
Microsoft gives the [settings for leading zeros and large numbers](https://support.microsoft.com/en-us/excel/keeping-leading-zeros-and-large-numbers).

If Excel already changed a value, a later text format cannot put the original digits back.
Import the original file again with the affected columns set to **Text** before conversion.

Some legacy files use spaces between fields.
Use the file separator for these files.
Do not select **Space** for files with tab separators: names and timestamps can contain spaces.

## Header rows and output

Rows that start with `#` or `%` contain format information, comments, or column labels.
These rows are not observations.
The number of header rows depends on the format and the comments.
The `.data` format also contains column checksums.

For analysis, use a separate worksheet with the observation rows and their column labels.
Keep each key in its data row.
Save the Excel workbook as a separate `.xlsx` file.

An Excel workbook is not an LRN, CLS, NAMES, DATES, or DATA file.
A text export from Excel does not automatically supply DataBionicIO headers, type markers, or DATA checksums.
Use the DataBionicIO writer for the selected format when you need a new DataBionicIO file.
