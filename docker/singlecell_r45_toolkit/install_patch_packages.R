#!/usr/bin/env Rscript
# =============================================================================
# install_patch_packages.R
# =============================================================================
# Purpose:
#   Final hardening install step for the custom single-cell toolkit image.
#   Installs packages that must be baked into the image default R library,
#   especially compiled packages that should link against the image's own
#   Ubuntu/R C++ runtime.
# =============================================================================

cat(sprintf("[%s] Starting ranger/pushoverr hardening install\n", Sys.time()))

site_lib <- "/usr/local/lib/R/site-library"
dir.create(site_lib, showWarnings = FALSE, recursive = TRUE)
.libPaths(c(site_lib, setdiff(.libPaths(), site_lib)))

cat(sprintf("[%s] R version: %s\n", Sys.time(), R.version.string))
cat(sprintf("[%s] .libPaths():\n", Sys.time()))
print(.libPaths())

options(
  repos = c(
    ranger_universe = "https://imbs-hl.r-universe.dev",
    CRAN = "https://cloud.r-project.org"
  ),
  timeout = 900,
  Ncpus = 2
)

Sys.setenv(
  MAKEFLAGS = "-j2",
  R_REMOTES_NO_ERRORS_FROM_WARNINGS = "true"
)

install_or_die <- function(pkgs) {
  for (pkg in pkgs) {
    cat(sprintf("[%s] Installing/checking package: %s\n", Sys.time(), pkg))
    install.packages(
      pkg,
      lib = site_lib,
      type = "source",
      dependencies = c("Depends", "Imports", "LinkingTo")
    )

    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf("Package did not install/load via requireNamespace(): %s", pkg))
    }

    cat(sprintf(
      "[%s] OK: %s %s at %s\n",
      Sys.time(),
      pkg,
      as.character(packageVersion(pkg)),
      dirname(dirname(system.file(package = pkg)))
    ))
  }
}

# Minimal dependency set for pushoverr plus compiled ranger dependencies.
# Do not use dependencies=TRUE globally; that pulls Suggests and creates avoidable
# failure cascades.
cran_support <- c(
  "Rcpp",
  "RcppEigen",
  "checkmate",
  "cli",
  "glue",
  "httr",
  "rlang",
  "curl",
  "jsonlite"
)

install_or_die(cran_support)
install_or_die(c("ranger", "pushoverr"))

cat(sprintf("[%s] ranger/pushoverr hardening install complete\n", Sys.time()))
