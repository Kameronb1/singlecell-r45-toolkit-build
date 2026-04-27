#!/usr/bin/env Rscript

cat("============================================================\n")
cat("VALIDATING SINGLE-CELL TOOLKIT IMAGE\n")
cat("============================================================\n")
cat("R version:", R.version.string, "\n")
cat(".libPaths():\n")
print(.libPaths())
cat("\n")

required_pkgs <- c(
  "Seurat",
  "SeuratObject",
  "Matrix",
  "qs",
  "dplyr",
  "ranger",
  "pushoverr",
  "BPCells",
  "hdf5r",
  "glmGamPoi",
  "harmony",
  "sctransform",
  "scDblFinder",
  "scater",
  "scuttle",
  "scran",
  "bluster"
)

validate_one <- function(pkg) {
  out <- list(
    package = pkg,
    ok = FALSE,
    version = NA_character_,
    location = NA_character_,
    error = NA_character_
  )

  tryCatch({
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    out$ok <- TRUE
    out$version <- as.character(packageVersion(pkg))
    out$location <- dirname(dirname(system.file(package = pkg)))
  }, error = function(e) {
    out$error <- conditionMessage(e)
  })

  as.data.frame(out, stringsAsFactors = FALSE)
}

tab <- do.call(rbind, lapply(required_pkgs, validate_one))

cat("PACKAGE VALIDATION TABLE\n")
cat("============================================================\n")
print(tab, row.names = FALSE)
cat("\n")

failed <- tab$package[!tab$ok]
if (length(failed) > 0L) {
  stop("Required packages failed to load: ", paste(failed, collapse = ", "))
}

storage1_pkgs <- tab$package[grepl("^/storage1/", tab$location)]
if (length(storage1_pkgs) > 0L) {
  stop(
    "Packages unexpectedly resolved from mounted cluster Rlibs: ",
    paste(storage1_pkgs, collapse = ", ")
  )
}

cat("VERSION HIGHLIGHTS\n")
cat("============================================================\n")
cat("Seurat:", as.character(packageVersion("Seurat")), "\n")
cat("SeuratObject:", as.character(packageVersion("SeuratObject")), "\n")
cat("Matrix:", as.character(packageVersion("Matrix")), "\n")
cat("qs:", as.character(packageVersion("qs")), "\n")
cat("ranger:", as.character(packageVersion("ranger")), "\n")
cat("pushoverr:", as.character(packageVersion("pushoverr")), "\n")
cat("scDblFinder:", as.character(packageVersion("scDblFinder")), "\n")
cat("\n")

cat("Required package sanity check passed\n")
cat("============================================================\n")
