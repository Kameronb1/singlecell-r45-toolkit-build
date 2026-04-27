FROM rocker/r-ver:4.5.2

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# SYSTEM DEPENDENCIES
# Purpose:
#   Provide a stable Ubuntu/R compile/runtime stack for Seurat, Bioconductor,
#   BPCells, qs, ranger, graphics packages, HDF5-backed workflows, and Python.
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    gfortran \
    make \
    cmake \
    git \
    curl \
    wget \
    ca-certificates \
    pkg-config \
    python3 \
    python3-dev \
    python3-venv \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libzstd-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libhdf5-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libglpk-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libcairo2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libxt-dev \
    libgit2-dev \
    libopenblas-dev \
    liblapack-dev \
    libomp-dev \
    libtbb-dev \
    pandoc \
    fonts-dejavu-core \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# PYTHON VENV
# Purpose:
#   Avoid system-pip / externally-managed-environment issues in Ubuntu 24.04.
# -----------------------------------------------------------------------------
ENV VIRTUAL_ENV=/opt/pyenv
RUN python3 -m venv "${VIRTUAL_ENV}"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

RUN pip install --no-cache-dir \
    numpy \
    scipy \
    pandas \
    matplotlib \
    scikit-learn \
    h5py \
    anndata \
    scanpy \
    jupyterlab

# -----------------------------------------------------------------------------
# R BOOTSTRAP
# Purpose:
#   Install package managers used by the rest of the image build.
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
    install.packages(c("remotes", "pak", "BiocManager"), Ncpus = 4L)'

# -----------------------------------------------------------------------------
# CRAN CORE
# Purpose:
#   Install the core CRAN stack, including ranger and pushoverr directly into
#   /usr/local/lib/R/site-library inside the image.
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
    install.packages(c( \
      "Rcpp","RcppEigen","RcppArmadillo","RcppHNSW","RcppAnnoy","RcppParallel", \
      "data.table","future","future.apply","progressr","glue","cli", \
      "rlang","vctrs","generics","lifecycle","magrittr","withr","pkgconfig", \
      "utf8","pillar","tibble","tidyselect","dplyr","purrr","stringr","stringi", \
      "ggplot2","patchwork","cowplot","viridis","viridisLite","scales","ggrastr", \
      "hdf5r","reticulate","R.utils","matrixStats","RSpectra","irlba","RcppML", \
      "sitmo","BH","jsonlite","yaml","htmltools","R6","digest", \
      "globals","listenv","parallelly","sp","spam","dotCall64","maps","fields", \
      "RColorBrewer","here","fs","rappdirs","pkgbuild","pkgload","testthat", \
      "knitr","rmarkdown","sctransform","harmony","xgboost", \
      "ranger","pushoverr", \
      "SeuratObject","Seurat"), \
      Ncpus = 4L)'

# -----------------------------------------------------------------------------
# BIOCONDUCTOR
# Purpose:
#   Bioconductor 3.22 is the correct Bioconductor line for R 4.5.
# -----------------------------------------------------------------------------
RUN Rscript -e 'BiocManager::install(version = "3.22", ask = FALSE, update = TRUE)'

RUN Rscript -e 'BiocManager::install(c( \
      "BiocGenerics","Biobase","S4Vectors","IRanges","GenomeInfoDb","GenomicRanges", \
      "SummarizedExperiment","SingleCellExperiment","DelayedArray","DelayedMatrixStats", \
      "MatrixGenerics","beachmat","BiocParallel","XVector","Rsamtools","rtracklayer", \
      "Biostrings","GenomicAlignments","BiocNeighbors","BiocSingular","bluster", \
      "scuttle","scran","scater","scDblFinder","glmGamPoi"), \
      ask = FALSE, update = TRUE)'

# -----------------------------------------------------------------------------
# qs
# Purpose:
#   qs is archived, so install its CRAN dependencies first, then the archived
#   version known to load correctly in the current image.
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
    install.packages(c("RApiSerialize", "stringfish"), Ncpus = 4L)'

RUN Rscript -e 'remotes::install_url( \
    "https://cran.r-project.org/src/contrib/Archive/qs/qs_0.27.3.tar.gz", \
    repos = c(CRAN = "https://cloud.r-project.org"), \
    type = "source", dependencies = FALSE)'

# -----------------------------------------------------------------------------
# BPCells
# Purpose:
#   Install BPCells from R-universe, not GitHub, to avoid GitHub API rate limits.
# -----------------------------------------------------------------------------
RUN Rscript -e 'install.packages("BPCells", \
    repos = c("https://bnprks.r-universe.dev", "https://cloud.r-project.org"))'

# -----------------------------------------------------------------------------
# SeuratDisk
# Purpose:
#   Optional convenience package. Keep non-load-bearing because availability can
#   vary, and this image should not fail if SeuratDisk is unavailable.
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
    ok <- try(install.packages("SeuratDisk", \
      repos = c("https://almirall-rddatascience.r-universe.dev", \
                "https://cloud.r-project.org")), silent = TRUE); \
    if (inherits(ok, "try-error")) message("SeuratDisk install skipped")'

# -----------------------------------------------------------------------------
# REQUIRED PACKAGE VALIDATION
# Purpose:
#   Prove the image can load the full required stack without using any mounted
#   cluster-side R library path.
# -----------------------------------------------------------------------------
RUN Rscript -e 'suppressPackageStartupMessages({ \
      library(Seurat); \
      library(SeuratObject); \
      library(Matrix); \
      library(qs); \
      library(dplyr); \
      library(ranger); \
      library(pushoverr); \
      library(BPCells); \
      library(hdf5r); \
      library(glmGamPoi); \
      library(harmony); \
      library(sctransform); \
      library(scDblFinder); \
      library(scater); \
      library(scuttle); \
      library(scran); \
      library(bluster); \
    }); \
    cat("R version:", R.version.string, "\n"); \
    cat("Seurat:", as.character(packageVersion("Seurat")), "\n"); \
    cat("qs:", as.character(packageVersion("qs")), "\n"); \
    cat("ranger:", as.character(packageVersion("ranger")), "\n"); \
    cat("pushoverr:", as.character(packageVersion("pushoverr")), "\n"); \
    pkgs <- c("Seurat","SeuratObject","Matrix","qs","dplyr","ranger","pushoverr", \
              "BPCells","hdf5r","glmGamPoi","harmony","sctransform", \
              "scDblFinder","scater","scuttle","scran","bluster"); \
    print(data.frame( \
      package = pkgs, \
      version = sapply(pkgs, function(p) as.character(packageVersion(p))), \
      location = sapply(pkgs, function(p) dirname(dirname(system.file(package = p)))), \
      row.names = NULL \
    )); \
    bad <- pkgs[grepl("/storage1/", sapply(pkgs, function(p) dirname(dirname(system.file(package = p)))) )]; \
    if (length(bad)) stop(paste("Packages unexpectedly resolved from mounted cluster Rlibs:", paste(bad, collapse = ", "))); \
    cat("Required package sanity check passed\n")'

WORKDIR /work

CMD ["/bin/bash"]
