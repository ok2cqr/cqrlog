# RPM spec for CQRLOG (Qt6 widget set). Built by tools/makerpm.sh, which
# passes the version (from src/uVersion.pas) and the source tarball:
#   make rpm
# Fedora ships a prebuilt Qt6 LCL (lazarus-lcl-qt6), so unlike the deb no
# Lazarus sources are needed.

# The fallback only lets `dnf builddep` parse the spec without the define.
%{!?cqr_version: %global cqr_version 0}

# lazbuild output is stripped by the Makefile and FPC emits no DWARF the
# debuginfo extractor understands, so there is nothing to split out.
%global debug_package %{nil}

Name:           cqrlog
Version:        %{cqr_version}
Release:        1%{?dist}
Summary:        Advanced logging program for hamradio operators
License:        GPL-2.0-only
URL:            https://www.cqrlog.com
Source0:        %{name}-%{version}.tar.gz

ExclusiveArch:  x86_64 aarch64

BuildRequires:  make
BuildRequires:  gzip
BuildRequires:  fpc
BuildRequires:  lazarus-tools
BuildRequires:  lazarus-lcl-qt6
BuildRequires:  qt6pas-devel

# Both are dlopen()ed, so rpm's automatic dependency scan misses them.
# FPC's mysql57dyn loads the unversioned libmysqlclient.so, which on Fedora
# comes only with mariadb-connector-c-devel (Debian needs libmariadb-dev too).
Requires:       mariadb-connector-c-devel
Requires:       openssl-libs
Requires:       mariadb-server
Requires:       mariadb
Requires:       hamlib

%description
CQRLOG is an advanced ham radio logger based on MySQL embedded database.
Provides radio control based on hamlib libraries (currently support of 140+
radio types and models), DX cluster connection, HamQTH/QRZ callbook
(XML access), a grayliner, internal QSL manager database support and a most
accurate country resolution algorithm based on country tables developed by
OK1RR. CQRLOG is intended for daily general logging of HF, CW & SSB contacts
and strongly focused on easy operation and maintenance.

%prep
%autosetup

%build
make cqrlog WS=qt6 LAZBUILD=lazbuild

%install
# The Makefile treats DESTDIR as the install prefix (datadir = $(DESTDIR)/share/cqrlog)
make install DESTDIR=%{buildroot}%{_prefix}
# Fedora uses SELinux, not AppArmor
rm -f %{buildroot}%{_datadir}/cqrlog/cqrlog-apparmor-fix

%files
%license COPYING
%doc AUTHORS CHANGELOG README.md
%{_bindir}/cqrlog
%{_datadir}/cqrlog/
%{_datadir}/applications/cqrlog.desktop
%{_datadir}/metainfo/com.cqrlog.cqrlog.appdata.xml
%{_datadir}/icons/hicolor/*/apps/cqrlog.png
%{_mandir}/man1/cqrlog.1*
