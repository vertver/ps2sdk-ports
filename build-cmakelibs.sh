#!/bin/bash

## Determine the maximum number of processes that Make can work with.
## Also make preparations for different toolchains
PROC_NR=$(getconf _NPROCESSORS_ONLN)
XTRA_OPTS=""
MAKECMD=make
OSVER=$(uname)
if [ ${OSVER:0:5} == MINGW ]; then
  XTRA_OPTS=(. -G"MinGW Makefiles")
  MAKECMD=${OSVER:0:7}-make
else
  XTRA_OPTS=(. -G"Unix Makefiles")
fi

CMAKE_OPTIONS="-Wno-dev -DCMAKE_TOOLCHAIN_FILE=$PS2SDK/ps2dev.cmake -DCMAKE_INSTALL_PREFIX=$PS2SDK/ports -DBUILD_SHARED_LIBS=OFF "
#CMAKE_OPTIONS+="-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON "

function build {
    cd $1
    mkdir -p build
    cd build
    cmake $CMAKE_OPTIONS $2 "${XTRA_OPTS[@]}" .. || { exit 1; }
    ${MAKECMD} --quiet -j $PROC_NR clean all install || { exit 1; }
    cd ../..
}

## Add ps2dev.cmake
cp ps2dev.cmake $PS2SDK/ || { exit 1; }

##
## Remove build folder
##
rm -rf build
mkdir build
cd build

##
## Clone repos
##
git clone --depth 1 -b v1.2.12 https://github.com/madler/zlib || { exit 1; }
git clone --depth 1 -b v1.6.37 https://github.com/glennrp/libpng || { exit 1; }
git clone --depth 1 -b VER-2-10-4 https://github.com/freetype/freetype || { exit 1; }
git clone --depth 1 -b 0.2.5 https://github.com/yaml/libyaml || { exit 1; }
git clone --depth 1 -b 2.1.0 https://github.com/libjpeg-turbo/libjpeg-turbo || { exit 1; }
git clone --depth 1 -b v1.3.5 https://github.com/xiph/ogg.git || { exit 1; }
git clone --depth 1 -b v1.3.7 https://github.com/xiph/vorbis.git || { exit 1; }
git clone --depth 1 -b curl-7_84_0 https://github.com/curl/curl.git || { exit 1; }
# We need to clone the whole repo and point to the specific hash for now, 
# till they release a new version with cmake compatibility
git clone https://github.com/libxmp/libxmp.git || { exit 1; } 
(cd libxmp && git checkout b0769774109d338554d534d9c122439d61d2bdd1 && cd -) || { exit 1; }
# We need to clone the whole repo and point to the specific hash for now, 
# till they release a new version with cmake compatibility
git clone https://github.com/xiph/opus.git || { exit 1; } 
(cd opus && git checkout ab04fbb1b7d0b727636d28fc2cadb5df9febe515 && cd -) || { exit 1; }
# We need to clone the whole repo and point to the specific hash for now, 
# till they release a new version with cmake compatibility
git clone https://github.com/xiph/opusfile.git || { exit 1; } 
(cd opusfile && git checkout cf218fb54929a1f54e30e2cb208a22d08b08c889 && cd -) || { exit 1; }
# We need to clone the whole repo and point to the specific hash for now, 
# till they release a new version with cmake compatibility
git clone https://github.com/Konstanty/libmodplug.git || { exit 1; } 
(cd libmodplug && git checkout d1b97ed0020bc620a059d3675d1854b40bd2608d && cd -) || { exit 1; }
# We need to clone the whole repo and point to the specific hash for now, 
# till they release a new version with cmake compatibility
git clone https://git.code.sf.net/p/mikmod/mikmod mikmod-mikmod || { exit 1; } 
(cd mikmod-mikmod && git checkout 187e55986a5888a8ead767a38fc29a8fc0ec5bbe && cd -) || { exit 1; }

git clone --depth 1 -b release-2.24.0 https://github.com/libsdl-org/SDL.git || { exit 1; }
git clone --depth 1 -b release-2.6.2 https://github.com/libsdl-org/SDL_mixer.git || { exit 1; }
git clone --depth 1 -b release-2.6.2 https://github.com/libsdl-org/SDL_image.git || { exit 1; }
git clone --depth 1 -b release-2.20.1 https://github.com/libsdl-org/SDL_ttf.git || { exit 1; }

##
## Build cmake projects
##
PROC_NR=1 build zlib "-DUNIX:BOOL=ON" # Forcing to compile with -j1 because there is a race condition in zlib
build libpng "-DPNG_SHARED=OFF -DPNG_STATIC=ON"
build freetype
build libyaml
build libjpeg-turbo "-DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=FALSE -DWITH_SIMD=0"
build ogg
build vorbis
build curl "-DENABLE_THREADED_RESOLVER=OFF -DCURL_USE_OPENSSL=OFF -DCURL_USE_MBEDTLS=OFF -DCURL_DISABLE_SOCKETPAIR=ON -DHAVE_BASENAME=NO"
build libxmp "-DBUILD_SHARED=OFF"
build opus
build opusfile "-DOP_DISABLE_HTTP=ON -DOP_DISABLE_DOCS=ON -DOP_DISABLE_EXAMPLES=ON"
build libmodplug
build mikmod-mikmod/libmikmod "-DENABLE_SHARED=0"
#we need an additional cd .. because previous library goes one sub-level more
cd ..

build SDL
build SDL_mixer "-DCMAKE_POSITION_INDEPENDENT_CODE=OFF -DDSDL2MIXER_DEPS_SHARED=OFF -DSDL2MIXER_OPUS=OFF -DSDL2MIXER_MIDI=OFF -DSDL2MIXER_FLAC=OFF -DSDL2MIXER_MOD=ON -DSDL2MIXER_SAMPLES=OFF"
build SDL_image "-DCMAKE_POSITION_INDEPENDENT_CODE=OFF -DBUILD_SHARED_LIBS=OFF"
build SDL_ttf "-DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=OFF -DSDL2TTF_SAMPLES=OFF"

# Finish
cd ..
