WriteQS = function(FileName, Data, Names=NULL, OutDirectory=getwd(), NThreads=1,
                   Preset="high", Algorithm="zstd", Compress_level=4L,
                   Shuffle_control=15L, Check_hash=TRUE){
  # WriteQS(FileName, Data)
  # Compatibility entry point: writes qs2 files using the existing argument names.
  #
  # INPUT
  # FileName        Output name; .qs is replaced by .qs2.
  # Data            Numeric matrix or list, as in the original WriteQS interface.
  # OPTIONAL
  # Names           Optional unique list names; generated if the list has no names.
  # OutDirectory    Output directory; default is getwd().
  # NThreads        Writer threads; default is 1.
  # Preset          fast, balanced, high, archive, uncompressed or custom.
  # Algorithm       Legacy option; qs2 always uses Zstandard.
  # Compress_level  Compression level used with Preset="custom"; default is 4L.
  # Shuffle_control 0 disables shuffling; 15 enables it. Other masks warn.
  # Check_hash      Legacy option; qs2 always stores a checksum.
  # OUTPUT
  # FilePath        Saved .qs2 path, invisibly.
  # DETAILS
  # Prefer WriteQS2() for new code. Preset levels: fast=1, balanced=3, high=4,
  # archive=19. Uncompressed has no equivalent and warns before using level -5.
  # Author: QMS 2022; qs2 migration 2026-10-18
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.

  if(!is.matrix(Data) && !is.list(Data)) stop("Parameter Data must be a matrix or a list")
  if(is.matrix(Data) && !is.numeric(Data)) stop("Parameter Data must be a numeric matrix")
  if(is.list(Data) && is.null(Names)) {
    Names = names(Data)
    if(is.null(Names)) Names = as.character(seq_along(Data))
  }
  Preset = match.arg(Preset, c("fast", "balanced", "high", "archive", "uncompressed", "custom"))
  if(Preset != "custom") Compress_level = c(fast=1L, balanced=3L, high=4L, archive=19L, uncompressed=-5L)[[Preset]]
  if(Preset == "uncompressed") warning("qs2 has no uncompressed preset; using Zstandard level -5", call.=FALSE)
  if(Preset == "custom" && Algorithm != "zstd") warning("qs2 always uses Zstandard; ignoring Algorithm", call.=FALSE)
  if(!Shuffle_control %in% c(0L, 15L)) warning("qs2 has a single shuffle switch; enabling all byte shuffling", call.=FALSE)
  if(!isTRUE(Check_hash)) warning("qs2 always stores a checksum; ignoring Check_hash=FALSE", call.=FALSE)
  WriteQS2(FileName, Data, Names, OutDirectory, NThreads, Compress_level, Shuffle_control != 0L)
}
