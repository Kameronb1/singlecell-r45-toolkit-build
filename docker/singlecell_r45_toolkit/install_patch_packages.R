#!/usr/bin/env Rscript
# =============================================================================
# install_patch_packages.R
# =============================================================================
# Purpose:
#   Final hardening install step for the custom single-cell toolkit image.
#
#   This script explicitly installs and validates packages that must be baked
#   into the image default R library:
#
#     - qs
#     - Seurat
#     - ranger
#     - pushoverr
#
#   Why this exists:
#     Some install.packages/remotes calls can emit installation failures while
#     the Docker layer still exits successfully unless we explicitly check with
#     requireNamespace(). This script makes those failures fatal immediately.
#
#   Important:
#     This installs into /usr/local/lib/R/site-library inside the image.
#     It does not use the mounted cluster-side /storage1/.../Rlibs path.
# =============================================================================

cat(sprintf("[%s] Starting final hardening install for Seurat/qs/ranger/pushoverr\n", Sys.time()))

site_lib <- "/usr/local/lib/R/site-library"
dir.create(site_lib, showWarnings = FALSE, recursive = TRUE)

.libPaths(c(site_lib, setdiff(.libPaths(), site_lib)))

cat(sprintf("[%s] R version: %s\n", Sys.time(), R.version.string))
cat(sprintf("[%s] .libPaths():\n", Sys.time()))
print(.libPaths())

options(
  repos = c(
    satijalab = "https://satijalab.r-universe.dev",
    ranger_universe = "https://imbs-hl.r-universe.dev",
    CRAN = "https://cloud.r-project.org"
  ),
  timeout = 1200,
  Ncpus = 2
)

Sys.setenv(
  MAKEFLAGS = "-j2",
  R_REMOTES_NO_ERRORS_FROM_WARNINGS = "true"
)

assert_loadable <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package is not loadable after install attempt: %s", pkg))
  }

  loc <- dirname(dirname(system.file(package = pkg)))
  ver <- as.character(packageVersion(pkg))

  cat(sprintf(
    "[%s] OK: %s %s at %s\n",
    Sys.time(), pkg, ver, loc
  ))

  invisible(TRUE)
}

install_cran_pkg <- function(pkg, dependencies = c("Depends", "Imports", "LinkingTo")) {
  cat(sprintf("[%s] Installing CRAN/R-universe package: %s\n", Sys.time(), pkg))

  install.packages(
    pkg,
    lib = site_lib,
    type = "source",
    dependencies = dependencies
  )

  assert_loadable(pkg)
}

install_url_pkg <- function(url, pkg) {
  cat(sprintf("[%s] Installing source URL package: %s\n", Sys.time(), pkg))
  cat(sprintf("[%s] URL: %s\n", Sys.time(), url))

  install.packages(
    url,
    lib = site_lib,
    repos = NULL,
    type = "source"
  )

  assert_loadable(pkg)
}

# -----------------------------------------------------------------------------
# Section 1: qs dependencies
# -----------------------------------------------------------------------------
# qs 0.27.3 needs RApiSerialize and stringfish. These must be installed before
# the archived qs tarball, otherwise qs can print a failed install while the
# Docker layer continues if not explicitly checked.
# -----------------------------------------------------------------------------

qs_deps <- c(
  "Rcpp",
  "BH",
  "RApiSerialize",
  "stringfish"
)

for (pkg in qs_deps) {
  install_cran_pkg(pkg)
}

install_url_pkg(
  url = "https://cran.r-project.org/src/contrib/Archive/qs/qs_0.27.3.tar.gz",
  pkg = "qs"
)

# -----------------------------------------------------------------------------
# Section 2: Seurat
# -----------------------------------------------------------------------------
# Prefer Satija R-universe first, then CRAN. This is intended to preserve the
# Seurat v5 stack used by the image while making the final package state explicit.
# -----------------------------------------------------------------------------

install_cran_pkg("Seurat")

seurat_ver <- packageVersion("Seurat")
if (seurat_ver < "5.0.0") {
  stop(sprintf("Unexpectedly old Seurat version installed: %s", as.character(seurat_ver)))
}

# -----------------------------------------------------------------------------
# Section 3: ranger + pushoverr
# -----------------------------------------------------------------------------
# ranger is compiled inside the image so it links against the image's own C++
# runtime. pushoverr is needed for LSF job notifications.
# -----------------------------------------------------------------------------

support_pkgs <- c(
  "RcppEigen",
  "checkmate",
  "cli",
  "glue",
  "httr",
  "rlang",
  "curl",
  "jsonlite"
)

for (pkg in support_pkgs) {
  install_cran_pkg(pkg)
}

install_cran_pkg("ranger")
install_cran_pkg("pushoverr")

# -----------------------------------------------------------------------------
# Section 4: Final hardening check
# -----------------------------------------------------------------------------

final_pkgs <- c(
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

cat("\n============================================================\n")
cat("FINAL HARDENING PACKAGE CHECK\n")
cat("============================================================\n")

for (pkg in final_pkgs) {
  assert_loadable(pkg)
}

cat("\nFinal hardening install complete\n")
cat(sprintf("[%s] Seurat version: %s\n", Sys.time(), as.character(packageVersion("Seurat"))))
cat(sprintf("[%s] qs version: %s\n", Sys.time(), as.character(packageVersion("qs"))))
cat(sprintf("[%s] ranger version: %s\n", Sys.time(), as.character(packageVersion("ranger"))))
cat(sprintf("[%s] pushoverr version: %s\n", Sys.time(), as.character(packageVersion("pushoverr"))))
