# Set base image to Ubuntu 22.04 LTS Jammy, as fpc fails on Focal
FROM ubuntu:jammy

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Europe/London"
ENV DESTDIR=/usr/local/cqrlog-alpha

# create the volume folders
RUN mkdir -p /usr/local/cqrlog-alpha /cqrlog/build

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
        libfl-dev \
        libqt5pas1 \
        libqt5pas-dev \
        libfuse2 \
        libsquashfuse0 \
        wget \
        devscripts \
        qt5-qmake-bin \
        qtchooser \
        mariadb-server \
        mariadb-client \
        sudo

# Install latest hamlib
RUN cd /tmp && \
        git clone https://github.com/Hamlib/Hamlib.git && \
        cd Hamlib && \
        git checkout 4.5.5 && \
        ./bootstrap && \
        ./configure && \
        make -j4 && \
        env DESTDIR= make install && \
        cp /usr/local/lib/libhamlib* /lib/ && \
        make clean

# Mount point for the git repository:
# -v $(pwd):/cqrlog
VOLUME ["/cqrlog"]

# Mount point for the result of the build:
# -v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha
VOLUME ["/usr/local/cqrlog-alpha"]

# Set the working directory
WORKDIR /cqrlog

CMD ["bash"]
