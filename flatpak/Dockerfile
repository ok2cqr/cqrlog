# Build environment for producing the CQRLOG Flatpak bundle.
#
# This image only ships flatpak + flatpak-builder. The KDE runtime/SDK and all
# build modules (FPC, Lazarus, hamlib, mariadb-connector-c, libQt6Pas) are
# downloaded and built by `make flatpak` at *run* time, because flatpak-builder
# needs the container to run privileged (bubblewrap / user namespaces).
#
# Usage (from the repo root):
#   make docker-flatpak
# which is equivalent to:
#   docker build -t cqrlog-flatpak-build flatpak/
#   docker run --rm --privileged -v $(pwd):/build -w /build cqrlog-flatpak-build make flatpak
#
# On an Apple-Silicon Mac this produces an aarch64 bundle (a manifest smoke
# test). The installable x86_64 bundle is produced by CI (.github/workflows/04-flatpak.yml).
FROM fedora:41

RUN dnf -y install \
        flatpak \
        flatpak-builder \
        make \
        git \
        xz \
        ca-certificates \
    && dnf clean all

WORKDIR /build
