#!/bin/bash
## From: https://trac.ffmpeg.org/wiki/CompilationGuide/Centos

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/opc/ffmpeg-build.log 2>&1

ffmpeg_sources='/home/opc/ffmpeg_sources'

timestamp(){
  date +"%c"
}

createDirectory(){
  echo "Creating ${ffmpeg_sources}..."
  mkdir ${ffmpeg_sources}
}

installDependencies(){
  echo "Installing dependencies..."
  sudo yum install -y autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel
}

installNASM(){
  echo "Installing NASM assembler..."
  cd ${ffmpeg_sources}
  curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
  tar xjvf nasm-2.15.05.tar.bz2
  cd nasm-2.15.05
  ./autogen.sh
  ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
  make
  make install
}

installYasm(){
  echo "Installing Yasm assembler..."
  cd ${ffmpeg_sources}
  curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
  tar xzvf yasm-1.3.0.tar.gz
  cd yasm-1.3.0
  ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
  make
  make install
}

installlibx264(){
  echo "Installing H.264 video encoder..."
  cd ${ffmpeg_sources}
  git clone --branch stable --depth 1 https://code.videolan.org/videolan/x264.git
  cd x264
  export PATH="$PATH:$HOME/bin" # Found no assembler error when running script during Packer build.
  PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
  make
  make install
}

installlibx265(){
  echo "Installing H.265/HEVC video encoder..."
  cd ${ffmpeg_sources}
  git clone --branch stable --depth 2 https://bitbucket.org/multicoreware/x265_git
  cd ${ffmpeg_sources}/x265_git/build/linux
  cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
  make
  make install
}

installlibfdkaac(){
  echo "Installing AAC audio encoder..."
  cd ${ffmpeg_sources}
  git clone --depth 1 https://github.com/mstorsjo/fdk-aac
  cd fdk-aac
  autoreconf -fiv
  ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
  make
  make install
}

installlibmp3lame(){
  echo "Installing MP3 audio encoder..."
  cd ${ffmpeg_sources}
  curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
  tar xzvf lame-3.100.tar.gz
  cd lame-3.100
  ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm
  make
  make install
}

installlibopus(){
  echo "Installing Opus audio decoder and encoder..."
  cd ${ffmpeg_sources}
  curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz
  tar xzvf opus-1.3.1.tar.gz
  cd opus-1.3.1
  ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
  make
  make install
}

installlibvpx(){
  echo "Installing VP8/VP9 video encoder and decoder..."
  cd ${ffmpeg_sources}
  git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
  cd libvpx
  ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
  make
  make install
}

installFFmpeg(){
  echo "Installing FFmpeg..."
  cd ${ffmpeg_sources}
  curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
  tar xjvf ffmpeg-snapshot.tar.bz2
  cd ffmpeg
  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
    --prefix="$HOME/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$HOME/ffmpeg_build/include" \
    --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
    --extra-libs=-lpthread \
    --extra-libs=-lm \
    --bindir="$HOME/bin" \
    --enable-gpl \
    --enable-libfreetype \
    --enable-nonfree \
    --enable-libx264 \
    --enable-libfdk_aac
    #--enable-libx265 \
    #--enable-libmp3lame \
    #--enable-libopus \
    #--enable-libvpx
  make
  make install
  hash -d ffmpeg
}

timestamp
echo "FFmpeg build script starting."

createDirectory
installDependencies
installNASM
installYasm
installlibx264
installlibfdkaac
#installlibx265
#installlibmp3lame
#installlibopus
#installlibvpx
installFFmpeg

timestamp
echo "FFmpeg build script complete."