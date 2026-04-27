# syntax=docker/dockerfile:1.7

# =============================================================================
# singlecell-r45-toolkit extension image
# =============================================================================
# PURPOSE:
#   Extend the already-working GHCR image rather than rebuilding the full
#   Seurat/Bioconductor stack from scratch.
#
# BASE IMAGE KNOWN GOOD FROM CLUSTER PREFLIGHT:
#   ghcr.io/kameronb1/singlecell-r45-toolkit:bioc322-r452-20260406
#
# KNOWN GOOD STACK IN BASE:
#   R 4.5.2
#   Ubuntu 24.04.4 LTS
#   Seurat 5.4.0
#   SeuratObject 5.3.0 / 5.4.0 depending image layer
#   Matrix 1.7.4
#   qs 0.27.3
#   dplyr 1.2.1
#   BPCells
#   hdf5r
#   glmGamPoi
#   harmony
#   sctransform
#   scDblFinder
#   scater
#   scuttle
#   scran
#   bluster
#
# PATCH:
#   Add ranger and pushoverr into the image default R library.
# =============================================================================

FROM ghcr.io/kameronb1/singlecell-r45-toolkit:bioc322-r452-20260406

USER root
SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

# Keep compiled-package toolchain available inside the image.
# ranger has compiled C++ code and must be compiled/linked against this image's
# Ubuntu/R runtime, not the cluster-side /storage1 Rlibs runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    cmake \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install only the missing packages. Do not reinstall the working stack.
RUN Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org")); \
    install.packages( \
      c("ranger", "pushoverr"), \
      type = "source", \
      dependencies = c("Depends", "Imports", "LinkingTo"), \
      Ncpus = max(1L, parallel::detectCores(logical = FALSE)) \
    ); \
    required <- c("ranger", "pushoverr"); \
    missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]; \
    if (length(missing)) stop("Failed to install required packages: ", paste(missing, collapse = ", ")); \
    cat("Patch package install passed\n"); \
    cat("ranger: ", as.character(packageVersion("ranger")), "\n", sep = ""); \
    cat("pushoverr: ", as.character(packageVersion("pushoverr")), "\n", sep = "") \
  '

COPY docker/singlecell_r45_toolkit/validate_required_packages.R /opt/validate_required_packages.R

RUN Rscript /opt/validate_required_packages.R

CMD ["R"]
