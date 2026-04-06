FROM rocker/r-ver:4.5.2

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# SYSTEM DEPENDENCIES
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    gcc \
    gfortran \
    make \
    cmake \
    git \
    curl \
    wget \
    ca-certificates \
    pkg-config \
    python3 \
    python3-pip \
    python3-dev \
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
    libsqlite3-dev \
    libgit2-dev \
    libopenblas-dev \
    liblapack-dev \
    libomp-dev \
    pandoc \
    fonts-dejavu-core \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# PYTHON BASICS
# -----------------------------------------------------------------------------
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel
RUN python3 -m pip install --no-cache-dir \
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
# R BASICS
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
                install.packages(c("remotes","pak","BiocManager"), Ncpus = 4L)'

# -----------------------------------------------------------------------------
# CRAN PACKAGES
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
                install.packages(c( \
                  "Rcpp","RcppEigen","RcppArmadillo","RcppHNSW","RcppAnnoy","RcppParallel", \
                  "Matrix","data.table","future","future.apply","progressr","glue","cli", \
                  "rlang","vctrs","generics","lifecycle","magrittr","withr","pkgconfig", \
                  "utf8","pillar","tibble","tidyselect","dplyr","purrr","stringr","stringi", \
                  "ggplot2","patchwork","cowplot","viridis","viridisLite","scales","ggrastr", \
                  "hdf5r","reticulate","R.utils","matrixStats","RSpectra","irlba","RcppML", \
                  "sitmo","BH","RcppAnnoy","jsonlite","yaml","htmltools","R6","digest", \
                  "globals","listenv","parallelly","sp","spam","dotCall64","maps","fields", \
                  "RColorBrewer","here","fs","rappdirs","pkgbuild","pkgload","testthat", \
                  "knitr","rmarkdown","sctransform","harmony"), \
                  Ncpus = 4L)'

# -----------------------------------------------------------------------------
# BIOCONDUCTOR CORE + SINGLE-CELL STACK
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
# SEURAT
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
                install.packages(c("SeuratObject","Seurat"), Ncpus = 4L)'

# -----------------------------------------------------------------------------
# qs + dependencies
# qs is archived, so install its required CRAN deps first, then archived qs
# -----------------------------------------------------------------------------
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); \
                install.packages(c("RApiSerialize","stringfish"), Ncpus = 4L)'

RUN Rscript -e 'remotes::install_url( \
                  "https://cran.r-project.org/src/contrib/Archive/qs/qs_0.27.3.tar.gz", \
                  repos = c(CRAN = "https://cloud.r-project.org"), \
                  type = "source", dependencies = FALSE)'

# -----------------------------------------------------------------------------
# BPCells
# Avoid GitHub API rate limits by installing from release tarball, then subdir /r
# -----------------------------------------------------------------------------
RUN cd /tmp && \
    curl -L https://github.com/bnprks/BPCells/archive/refs/tags/v0.3.1.tar.gz -o BPCells_v0.3.1.tar.gz && \
    tar -xzf BPCells_v0.3.1.tar.gz && \
    Rscript -e 'remotes::install_local("/tmp/BPCells-0.3.1/r", upgrade = "never", dependencies = TRUE)' && \
    rm -rf /tmp/BPCells_v0.3.1.tar.gz /tmp/BPCells-0.3.1

# -----------------------------------------------------------------------------
# OPTIONAL BUT USEFUL
# -----------------------------------------------------------------------------
RUN Rscript -e 'remotes::install_github("mojaveazure/seurat-disk", upgrade = "never")'

# -----------------------------------------------------------------------------
# SANITY CHECK
# -----------------------------------------------------------------------------
RUN Rscript -e 'cat("R version: ", R.version.string, "\n", sep=""); \
                pkgs <- c("Seurat","SeuratObject","BPCells","scDblFinder","scater","scuttle","scran","bluster","glmGamPoi","hdf5r","qs","reticulate","sctransform","harmony"); \
                miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; \
                if (length(miss)) stop(paste("Missing R packages:", paste(miss, collapse=", "))); \
                cat("R package sanity check passed\n")'

WORKDIR /work
CMD ["/bin/bash"]
