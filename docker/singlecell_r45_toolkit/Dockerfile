FROM bioconductor/bioconductor_docker:RELEASE_3_21

# =============================================================================
# PURPOSE
#   Robust single-cell toolkit image for Seurat v5 / Bioconductor / scDblFinder
#   plus a clean Python virtualenv for future interoperability.
#
# DESIGN
#   - Base on Bioconductor 3.21 / R 4.5 to avoid old-R package dead ends
#   - Install broad OS deps needed for graphics / HDF5 / compilation
#   - Never mutate distro-managed Python with pip; use /opt/pyenv instead
#   - Install core CRAN + Bioconductor single-cell packages
#   - Pin Seurat to 5.4.0
# =============================================================================

USER root

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PIP_ROOT_USER_ACTION=ignore
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# -----------------------------------------------------------------------------
# SECTION 1  OS-LEVEL DEPENDENCIES
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    git \
    git-lfs \
    unzip \
    zip \
    nano \
    vim \
    less \
    htop \
    jq \
    locales \
    tzdata \
    build-essential \
    gfortran \
    make \
    cmake \
    pkg-config \
    software-properties-common \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libfftw3-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libgit2-dev \
    libglpk-dev \
    libgsl-dev \
    libharfbuzz-dev \
    libhdf5-dev \
    libjpeg-dev \
    liblzma-dev \
    libmagick++-dev \
    libpng-dev \
    libproj-dev \
    libreadline-dev \
    libsodium-dev \
    libsqlite3-dev \
    libssl-dev \
    libtiff5-dev \
    libudunits2-dev \
    libxml2-dev \
    libxt-dev \
    zlib1g-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# SECTION 2  PYTHON VIRTUALENV
# -----------------------------------------------------------------------------
RUN python3 -m venv /opt/pyenv
ENV PATH="/opt/pyenv/bin:${PATH}"

RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Keep Python basics modest but useful for future tasks
RUN python -m pip install --no-cache-dir \
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
# SECTION 3  R ENVIRONMENT DEFAULTS
# -----------------------------------------------------------------------------
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo 'Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS = "true")' >> /usr/local/lib/R/etc/Rprofile.site

ENV MAKEFLAGS="-j4"

# -----------------------------------------------------------------------------
# SECTION 4  R PACKAGE INSTALLATION HELPERS
# -----------------------------------------------------------------------------
RUN Rscript -e 'install.packages(c("remotes","BiocManager"), Ncpus = 4L)'

# -----------------------------------------------------------------------------
# SECTION 5  CRAN PACKAGES
# -----------------------------------------------------------------------------
RUN Rscript -e 'install.packages(c( \
    "data.table", \
    "dplyr", \
    "tibble", \
    "stringr", \
    "glue", \
    "cli", \
    "fs", \
    "here", \
    "jsonlite", \
    "yaml", \
    "future", \
    "future.apply", \
    "patchwork", \
    "cowplot", \
    "ggplot2", \
    "viridis", \
    "RColorBrewer", \
    "ggrastr", \
    "hdf5r", \
    "reticulate", \
    "Rcpp", \
    "RcppArmadillo", \
    "RcppHNSW", \
    "irlba", \
    "uwot", \
    "sctransform", \
    "harmony", \
    "clustree", \
    "igraph", \
    "devtools", \
    "sessioninfo" \
  ), Ncpus = 4L)'

# -----------------------------------------------------------------------------
# SECTION 6  BIOCONDUCTOR SINGLE-CELL STACK
# -----------------------------------------------------------------------------
RUN Rscript -e 'BiocManager::install(c( \
    "SingleCellExperiment", \
    "SummarizedExperiment", \
    "S4Vectors", \
    "IRanges", \
    "GenomicRanges", \
    "BiocGenerics", \
    "BiocParallel", \
    "DelayedArray", \
    "DelayedMatrixStats", \
    "MatrixGenerics", \
    "DropletUtils", \
    "scater", \
    "scuttle", \
    "scran", \
    "bluster", \
    "batchelor", \
    "glmGamPoi", \
    "scDblFinder" \
  ), ask = FALSE, update = FALSE, Ncpus = 4L)'

# -----------------------------------------------------------------------------
# SECTION 7  SEURAT / RELATED
# -----------------------------------------------------------------------------
RUN Rscript -e 'remotes::install_version("SeuratObject", version = "5.0.2", repos = "https://cloud.r-project.org", upgrade = "never")'
RUN Rscript -e 'remotes::install_version("Seurat", version = "5.4.0", repos = "https://cloud.r-project.org", upgrade = "never")'

# Optional but commonly useful for your workflows
RUN Rscript -e 'remotes::install_url("https://cran.r-project.org/src/contrib/Archive/qs/qs_0.27.3.tar.gz", repos = NULL, type = "source", dependencies = TRUE)'
RUN Rscript -e 'remotes::install_github("bnprks/BPCells/r", upgrade = "never", dependencies = TRUE)'
RUN Rscript -e 'remotes::install_github("mojaveazure/seurat-disk", upgrade = "never")'

# -----------------------------------------------------------------------------
# SECTION 8  SANITY CHECKS
# -----------------------------------------------------------------------------
RUN Rscript -e 'cat("R version: ", R.version.string, "\n", sep=""); \
                pkgs <- c("Seurat","SeuratObject","BPCells","scDblFinder","scater","scuttle","scran","bluster","glmGamPoi","hdf5r","qs","reticulate","sctransform","harmony"); \
                miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; \
                if (length(miss)) stop(paste("Missing R packages:", paste(miss, collapse=", "))); \
                cat("R package sanity check passed\n")'

RUN python - <<'PYEOF'
import sys
mods = ["numpy", "scipy", "pandas", "h5py", "anndata", "scanpy", "sklearn"]
missing = []
for m in mods:
    try:
        __import__(m)
    except Exception:
        missing.append(m)
if missing:
    raise SystemExit("Missing Python modules: " + ", ".join(missing))
print("Python sanity check passed")
print(sys.version)
PYEOF

# -----------------------------------------------------------------------------
# SECTION 9  DEFAULT WORKDIR
# -----------------------------------------------------------------------------
WORKDIR /workspace

CMD ["/bin/bash"]
