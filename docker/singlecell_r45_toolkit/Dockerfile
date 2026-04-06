FROM bioconductor/bioconductor_docker:3.21-r-4.5.2

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# -----------------------------------------------------------------------------
# OS-level build and runtime dependencies for robust single-cell R workflows
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    cmake \
    make \
    pkg-config \
    git \
    curl \
    wget \
    ca-certificates \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libhdf5-dev \
    libcairo2-dev \
    libxt-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff5-dev \
    libgit2-dev \
    libglpk-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Python basics kept minimal on purpose; this is an R-first toolkit image
# -----------------------------------------------------------------------------
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# CRAN packages used repeatedly in this project and nearby future work
# -----------------------------------------------------------------------------
RUN R -q -e "options(repos = c(CRAN='https://cloud.r-project.org'), Ncpus = max(1L, parallel::detectCores() - 1L)); install.packages(c( \
    'Seurat', \
    'SeuratObject', \
    'BPCells', \
    'harmony', \
    'qs', \
    'data.table', \
    'future', \
    'future.apply', \
    'patchwork', \
    'cowplot', \
    'ggplot2', \
    'ggrepel', \
    'RColorBrewer', \
    'viridis', \
    'pheatmap', \
    'clustree', \
    'glmGamPoi', \
    'remotes', \
    'devtools', \
    'hdf5r', \
    'igraph', \
    'uwot', \
    'pushoverr' \
  ))"

# -----------------------------------------------------------------------------
# Bioconductor packages for QC, doublets, matrix backends, and SCE workflows
# -----------------------------------------------------------------------------
RUN R -q -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos='https://cloud.r-project.org'); BiocManager::install(version='3.21', ask=FALSE, update=FALSE); BiocManager::install(c( \
    'SingleCellExperiment', \
    'scater', \
    'scuttle', \
    'scran', \
    'scDblFinder', \
    'bluster', \
    'batchelor', \
    'BiocParallel', \
    'DropletUtils', \
    'DelayedArray', \
    'HDF5Array', \
    'BiocSingular', \
    'SummarizedExperiment', \
    'GenomicRanges', \
    'GenomeInfoDb', \
    'IRanges' \
  ), ask=FALSE, update=FALSE)"

# -----------------------------------------------------------------------------
# Build-time smoke test so the image fails early if the stack is broken
# -----------------------------------------------------------------------------
RUN R -q -e "pkgs <- c( \
    'Seurat','SeuratObject','BPCells','harmony','qs','data.table','glmGamPoi', \
    'SingleCellExperiment','scater','scuttle','scran','scDblFinder','bluster', \
    'batchelor','DropletUtils','DelayedArray','HDF5Array','BiocParallel', \
    'hdf5r','pushoverr' \
  ); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly=TRUE)]; if (length(missing)) stop(sprintf('Missing packages: %s', paste(missing, collapse=', '))); cat('All required packages loadable.\\n'); sessionInfo()"

WORKDIR /workspace
