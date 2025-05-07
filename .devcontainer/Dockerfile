
# Runtime image is smaller than the devel/build image
FROM ubuntu:22.04
LABEL authors="Hovakim Grabski" \
        description="Docker image containing all software requirements for the nf-core/quickflow pipeline development"


# Set up environment variables
ENV MAMBA_ROOT_PREFIX="/opt/micromamba/"
ENV MAMBA="${MAMBA_ROOT_PREFIX}/bin/micromamba"
ENV ENV_NAME="quick"
ENV LC_ALL="C"
ENV PATH="/opt/micromamba/envs/quick/bin:${PATH}"
ENV LC_ALL="C"
ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -y \
    && apt-get install -y \
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    graphviz \
    curl \
    git \
    bzip2 \
    mlocate \
    locate \
    bash \
    gawk \
    sed \
    nano \
    vim


#-- * Install mamba
RUN mkdir -p ${MAMBA_ROOT_PREFIX}
WORKDIR ${MAMBA_ROOT_PREFIX}

RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest  | tar -xvj bin/micromamba
# RUN source ${HOME}/.bashrc


#-- * chown so user can make use of it
RUN chmod 777 -R /opt/

#-- * activate mamba environment
RUN updatedb
# RUN /bin/bash -c "source /opt/micromamba/etc/profile.d/mamba.sh && micromamba activate ${ENV_NAME}"
# RUN echo "source activate ${ENV_NAME}" > ~/.bashrc

# Manually run steps from quick.rc
# ENV QUICK_INSTALL /src/QUICK/install
# ENV QUICK_BASIS $QUICK_INSTALL/basis
# ENV PATH $PATH:$QUICK_INSTALL/bin

# -- * Create a new user
RUN useradd -ms /bin/bash vscode

# -- * Switch to the new user
USER vscode


# RUN /bin/bash -c "source /opt/micromamba/etc/profile.d/mamba.sh && micromamba activate ${ENV_NAME}"
# RUN echo "source activate ${ENV_NAME}" > ~/.bashrc




RUN $MAMBA create -n $ENV_NAME -c conda-forge --yes \
    'python==3.11' \
    'pip' \
    'uv' \
    'numba' \
    'click' \
    'tqdm' \
    'loguru' \
    'python-graphviz' \
    'pandas' \
    'matplotlib' \
    'h5py' \
    'Pillow' \
    'ipywidgets' \
    'scikit-image' \
    'scikit-learn' \
    'astropy' \
    'black' \
    'pytables' \
    'xarray' \
    'netcdf4' \
    'mdtraj' \
    'nglview' \
    'rdkit' \
    'openbabel' \
    'polars' \
    'sqlite' \
    'psycopg' \
    'sqlalchemy'  && \
    "${MAMBA}" clean --all -f -y


RUN    $MAMBA  run -n $ENV_NAME  $MAMBA install bioconda::nextflow
RUN    $MAMBA  run -n $ENV_NAME uv pip install click nf-core


# RUN $MAMBA shell

RUN  $MAMBA shell init --shell bash --root-prefix=$MAMBA_ROOT_PREFIX

ENV ENV_NAME="quick"
ENV LC_ALL="C"
ENV PATH="/opt/micromamba/envs/quick/bin:${PATH}"
ENV LC_ALL="C"


RUN echo "micromamba activate ${ENV_NAME}" >> ~/.bashrc


# /opt/micromamba//bin/micromamba

# # Copy the compiled quick runtimes, leaving behind extra build dependencies & reducing image size
# COPY --from=base-mpi-cuda-12.0.1 /src /src

# WORKDIR /src/QUICK/install


# test nfcore lint  nf-core pipelines lint
