#!/usr/bin/env Rscript
# =============================================================================
# validate_required_packages.R
# =============================================================================
# Purpose:
#   Verbose final validation for the custom single-cell toolkit image.
#   This replaces a fragile inline Dockerfile Rscript command so GitHub Actions
#   logs show the exact package that fails, its version, and its library path.
# =============================================================================

cat(sprintf("[%s] Starting final required-package validation\n", Sys.time()))
cat("R version: ", R.version.string, "\n", sep = "")
cat("Platform: ", R.version$platform, "\n", sep = "")
cat(".libPaths():\n")
print(.libPaths())

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

results <- lapply(required_pkgs, function(pkg) {
  cat("\n------------------------------------------------------------\n")
  cat(sprintf("[%s] VALIDATING PACKAGE: %s\n", Sys.time(), pkg))
  cat("------------------------------------------------------------\n")

  out <- data.frame(
    package = pkg,
    ok = FALSE,
    version = NA_character_,
    location = NA_character_,
    error = NA_character_,
    stringsAsFactors = FALSE
  )

  loc <- system.file(package = pkg)
  out$location <- if (nzchar(loc)) dirname(dirname(loc)) else NA_character_

  res <- tryCatch({
    suppressPackageStartupMessages(
      library(pkg, character.only = TRUE)
    )
    TRUE
  }, error = function(e) {
    out$error <<- conditionMessage(e)
    FALSE
  }, warning = function(w) {
    cat(sprintf("[%s] WARNING while loading %s: %s\n", Sys.time(), pkg, conditionMessage(w)))
    invokeRestart("muffleWarning")
  })

  out$ok <- isTRUE(res)

  if (out$ok) {
    out$version <- as.character(packageVersion(pkg))
    out$location <- dirname(dirname(system.file(package = pkg)))
    cat(sprintf("[%s] OK: %s %s\n", Sys.time(), pkg, out$version))
    cat(sprintf("[%s] Location: %s\n", Sys.time(), out$location))
  } else {
    cat(sprintf("[%s] FAILED: %s\n", Sys.time(), pkg))
    cat(sprintf("[%s] Error: %s\n", Sys.time(), out$error))
  }

  out
})

df <- do.call(rbind, results)

cat("\n============================================================\n")
cat("PACKAGE VALIDATION TABLE\n")
cat("============================================================\n")
print(df, row.names = FALSE)

failed <- df$package[!df$ok]
if (length(failed) > 0L) {
  stop(sprintf("Required packages failed to load: %s", paste(failed, collapse = ", ")))
}

bad_storage <- df$package[grepl("^/storage1/", df$location)]
if (length(bad_storage) > 0L) {
  stop(sprintf(
    "Packages unexpectedly resolved from mounted cluster Rlibs: %s",
    paste(bad_storage, collapse = ", ")
  ))
}

cat("\n============================================================\n")
cat("KEY VERSION SUMMARY\n")
cat("============================================================\n")
cat("R version:", R.version.string, "\n")
cat("Seurat:", as.character(packageVersion("Seurat")), "\n")
cat("qs:", as.character(packageVersion("qs")), "\n")
cat("ranger:", as.character(packageVersion("ranger")), "\n")
cat("pushoverr:", as.character(packageVersion("pushoverr")), "\n")

cat("\nRequired package sanity check passed\n")
cat(sprintf("[%s] Final required-package validation complete\n", Sys.time()))
