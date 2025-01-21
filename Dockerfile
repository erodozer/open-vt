FROM debian:12

RUN apt update
RUN apt install -y \
        make \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        curl \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        zip \
        git \
        rust


# install pyenv and poetry for building godot extensions
ENV HOME="/root"
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"

RUN pyenv install 3.13.0
RUN pyenv local 3.13.0
RUN pip install pipx poetry scons

WORKDIR /app
RUN git config --global --add safe.directory /app

CMD ["/app/build_dependencies.sh"]

