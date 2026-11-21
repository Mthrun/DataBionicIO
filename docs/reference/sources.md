# Data sources and attribution

## Hepta

Hepta is part of the Fundamental Clustering Problems Suite (FCPS).
The tutorial contains 212 observations, three measurements, and seven classes.
The study preparation program supplied keys 1 thru 212 and names `Hepta_001` thru `Hepta_212`.
These names are example labels from that program.

Thrun MC, Ultsch A. Clustering benchmark datasets exploiting the fundamental clustering problems.
*Data in Brief* 30 (2020), 105501.
[Article](https://doi.org/10.1016/j.dib.2020.105501).

The three text files are the fixed Hepta fixtures from this repository.
The study deposit also contains the files used for the Excel examples.

## Firebrowse

The tutorial uses the four small annotation files from
[Zenodo record 21849070](https://doi.org/10.5281/zenodo.21849070).
The deposit identifies Michael Thrun and Julian Märte as creators.
Its metadata gives CC BY 4.0 as the dataset license.
The tutorial annotation files are copies with the same bytes as the source files.

The expression matrix has 10,446 cases and 19,637 gene columns.
The gene NAMES file connects NCBI identifiers to matrix column names.
The CLS file connects cases to 33 diagnosis classes.
The tutorial does not download the 1.4 GB expression matrix.

## Flow cytometry

The input is `DresdenData/01SampleDresdenD10n440K.lrn` from
[Mendeley Data, version 5](https://doi.org/10.17632/jk4dt6wprv.5).
The dataset uses CC BY 4.0.
The source contributors are Michael Thrun, Jörg Hoffmann, Maximilian Röhnert, Malte von Bonin,
Uta Oelschlägel, Cornelia Brendel, and Alfred Ultsch.

Thrun MC et al. Flow cytometry datasets consisting of peripheral blood and bone marrow samples
for the evaluation of explainable artificial intelligence methods.
*Data in Brief* (2022), 108382.
[Article](https://doi.org/10.1016/j.dib.2022.108382).

The tutorial selects input rows for a file-exchange example.
It does not make clinical predictions or give a classification result.

## Hydrology

`HydrologyDaily2013_2014.dts` contains 351 calendar dates and 14 measurement columns.
The file contains 196 missing numeric measurements.
The source is archived daily means in
[Zenodo record 4498241](https://doi.org/10.5281/zenodo.4498241).
The preparation program kept the calendar dates.

Thrun MC, Ultsch A, Breuer L. Explainable AI framework for multivariate hydrochemical time series.
*Machine Learning and Knowledge Extraction* 3 (2021), 170–204.
[Article](https://doi.org/10.3390/make3010009).

The [DataBionicIO study deposit](https://doi.org/10.5281/zenodo.24335147)
contains the derived DTS file in Supplementary Data S2.
The archive also contains its preparation program and data provenance.
The tutorial copy keeps the published DTS bytes.

## Example provenance

The tutorial data manifest records filenames, source identifiers, sizes, and SHA-256 digests.
Use the manifest to identify the input version.
An output filename does not identify the input version.
Dataset terms and the software license are different.
