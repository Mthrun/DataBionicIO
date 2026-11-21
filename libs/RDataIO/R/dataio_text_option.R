# INPUT
# options: named values from ...; name: accepted option; default: omitted value.
# OUTPUT
# One character value. Reject unknown, duplicate, or unnamed options.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
.dataio_text_option = function(options, name, default) {
  if (!length(options)) return(default)
  if (length(options) != 1L || is.null(names(options)) ||
      is.na(names(options)[1L]) || names(options)[1L] != name)
    stop(paste("Use only the exact named option", name, "in ..."), call. = FALSE)
  value = options[[1L]]
  if (!is.character(value) || length(value) != 1L || is.na(value))
    stop(paste(name, "must be one nonmissing character string"), call. = FALSE)
  value
}
