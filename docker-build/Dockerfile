FROM ubuntu:jammy

RUN apt-get update && apt-get -y upgrade

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"

RUN apt-get install -y git lazarus-ide lcl lcl-gtk2 lcl-nogui lcl-units lcl-utils lazarus lazarus-doc lazarus-src fp-units-misc fp-units-rtl fp-utils fpc fpc-source libssl-dev

RUN mkdir -p /usr/local/cqrlog-alpha /home/cqrlog/build

# Mount point for the git repository:
# -v $(pwd):/home/cqrlog/build
VOLUME ["/home/cqrlog/build"]

# Mount point for the result of the build:
# -v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha
VOLUME ["/usr/local/cqrlog-alpha"]

WORKDIR /home/cqrlog/build

ENTRYPOINT make clean && make DESTDIR=/usr/local/cqrlog-alpha && make DESTDIR=/usr/local/cqrlog-alpha install

