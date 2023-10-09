# Set base image to Ubuntu 22.04 LTS Jammy, as fpc fails on Focal
FROM ubuntu:jammy

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/London"
ENV DESTDIR=/usr/local/cqrlog-alpha

# create the volume folders
RUN mkdir -p /usr/local/cqrlog-alpha /home/cqrlog/build

# update the system
RUN apt-get update

# install lazarus
RUN apt-get install -y \
        git \
        lazarus-ide \
        lcl lcl-gtk2 \
        lcl-nogui \
        lcl-units \
        lcl-utils \
        lazarus \
        lazarus-doc \
        lazarus-src \
        fp-units-misc \
        fp-units-rtl \
        fp-utils \
        fpc \
        fpc-source

# Install runtime deps and packing tools
RUN apt-get install -y \
        libssl-dev \
        mariadb-client \
        libhamlib-utils \
        libqt5pas1

# Install packing deps and tools
RUN apt-get install -y \
        fuse3 \
        libfuse2 \
        libsquashfuse0 \
        wget

# Install mariadb-server
RUN apt-get install -y \
        mariadb-server

# Mount point for the git repository:
# -v $(pwd):/home/cqrlog/build
VOLUME ["/home/cqrlog/build"]

# Mount point for the result of the build:
# -v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha
VOLUME ["/usr/local/cqrlog-alpha"]

# Set the working directory
WORKDIR /home/cqrlog/build

CMD ["bash"]
