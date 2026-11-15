# OUTPUT
# The configured R library receives lubridate and qs2.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

install.packages("lubridate", repos = "http://cran.us.r-project.org")
install.packages("qs2", repos = "https://cloud.r-project.org")
# qslegacy is supplied in libs/qslegacy. Install it with R CMD INSTALL libs/qslegacy,
# or install its prepared binary/source archive with repos=NULL.
