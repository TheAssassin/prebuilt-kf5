#!/bin/bash

log() {
    export TERM=xterm-256color
    tput setaf 3
    tput bold
    time="$(date +%H:%M:%S)"
    echo "=== [$time] $* ==="
    tput sgr0
}

error() { log "$(tput setaf 1)Error: $*"; }

if [[ "$DIST" == "" ]] || [[ "$ARCH" == "" ]]; then
    error "Usage: env DIST=... ARCH=... [BUILD_DIR=...] bash $0"
    exit 2
fi

set -e

env_file=/opt/qt514/bin/qt514-env.sh

# unfortunately, the scripts don't work with set -e, so we have to source them without this flag
[[ ! -f "$env_file" ]] && error "Could not find Qt 5.14 env file -- is the Qt 5.14 PPA installed?" && exit 1
set +e
. "$env_file"
set -e

destdir="$(readlink -f "$(dirname "0")")/out"
KF5_VERSION="${KF5_VERSION:-5.67.0}"
destdir="$(readlink -f "$(dirname "0")")/kf5-$KF5_VERSION-$DIST-$ARCH"

kf5_major_minor_version="$(echo "$KF5_VERSION" | rev | cut -d. -f2- | rev)"

export PATH="$destdir"/usr/bin:"$PATH"
export LD_LIBRARY_PATH="$destdir"/usr/lib:"$destdir"/usr/lib/"$ARCH"-linux-gnu:"$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$destdir"/usr/share:"$XDG_DATA_DIRS"
export PKG_CONFIG_PATH="$destdir"/usr/share/pkg-config:"$destdir"/usr/lib/pkgconfig:"$destdir"/usr/lib/"$ARCH"-linux-gnu/pkgconfig:"$PKG_CONFIG_PATH"

# use RAM disk if possible
if [ -d /dev/shm ] && mount | grep /dev/shm | grep -v -q noexec; then
    temp_base=/dev/shm
elif [ -d /docker-ramdisk ]; then
    temp_base=/docker-ramdisk
else
    temp_base=/tmp
fi

if [[ "$BUILD_DIR" == "" ]]; then
    BUILD_DIR="$(mktemp -d -p "$temp_base" frameworks-build-XXXXXX)"

    log "Building in temporary directory $BUILD_DIR"

    cleanup () {
        if [ -d "$build_dir" ]; then
            rm -rf "$build_dir"
        fi
    }

    trap cleanup EXIT
else
    log "Building in user-specified directory $BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR"

run_command() {
    logfile="$1".log
    (set -x; "$@") &>"$logfile" || (error "$1 failed" && cat "$logfile" && return 1)
    return 0
}

build_framework() {
    framework="$1"
    log "Building $framework"

    dir_name="$framework-$KF5_VERSION"

    log "Downloading $framework"
    url="https://download.kde.org/stable/frameworks/$kf5_major_minor_version/$dir_name.tar.xz"
    run_command wget -N "$url" &> wget-"$dir_name".log

    log "Extracting $framework"
    run_command tar xvf "$dir_name".tar.xz &> tar-"$dir_name".log

    pushd "$dir_name"

        log "Configuring build for $framework"
        mkdir -p build
        cd build

        run_command cmake .. \
            -DCMAKE_PREFIX_PATH="$destdir/usr/share/ECM/cmake;$destdir/usr/lib/x86_64-linux-gnu/cmake" \
            -DCMAKE_INSTALL_PREFIX="/usr" \
            -DCMAKE_BUILD_TYPE=Release \
            -G Ninja

        log "Building and installing $framework"
        [[ "$CI" != "" ]] && jobs="$(nproc)" || jobs="$(nproc --ignore=1)"
        run_command env DESTDIR="$destdir" ninja -v install -j "$jobs"

    popd
}

frameworks=(
    # ECM
    extra-cmake-modules

    # Tier 1 Frameworks
    attica
    kconfig
    #bluez-qt # kinda buggy with install paths
    kapidox
    kdnssd
    kidletime
    kplotting
    #modemmanager-qt # this crashes gcc for some reason...
    #networkmanager-qt # it's been a pain in the ass to get the dependencies to work on travis. Contact me if you want this implemented.
    #kwayland # trusty gives hella old version of this
    prison
    kguiaddons
    ki18n
    kitemviews
    sonnet
    kwidgetsaddons
    kwindowsystem
    kdbusaddons
    karchive
    kcoreaddons
    kcodecs
    solid
    kitemmodels
    threadweaver
    syntax-highlighting
    breeze-icons

    # Tier 2 Frameworks
    kcompletion
    kfilemetadata
    kjobwidgets
    kcrash
    kimageformats
    kunitconversion
    kauth
    knotifications
    kpackage
    kdoctools
    kpty

    # Tier 3 Frameworks
    kservice
    kdesu
    kemoticons
    kpeople
    kconfigwidgets
    kiconthemes
    ktextwidgets
    kglobalaccel
    kxmlgui
    kbookmarks
    kwallet
    kio
    kactivities
    kactivities-stats
    baloo
    # kded # requires a KDE install
    kxmlrpcclient
    kparts
    # kdewebkit  # tarball 404 not found
    # kdesignerplugin  # tarball 404 not found
    knewstuff
    ktexteditor
    kdeclarative
    kirigami2
    plasma-framework
    kcmutils
    knotifyconfig
    krunner
    kinit
    kirigami2
)

# prefer building only the user-specified frameworks
if [[ "$1" != "" ]]; then
    frameworks=("$@")
fi

for framework in "${frameworks[@]}"; do
    build_framework "$framework"
done
