#!/bin/bash

########## LICENCE ##########
# Copyright (c) 2022 Genome Research Ltd
# 
# Author: CASM/Cancer IT <cgphelp@sanger.ac.uk>
# 
# This file is part of NanoSeq.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 
# 1. The usage of a range of years within a copyright statement contained within
# this distribution should be interpreted as being equivalent to a list of years
# including the first and last year specified and all consecutive years between
# them. For example, a copyright statement that reads ‘Copyright (c) 2005, 2007-
# 2009, 2011-2012’ should be interpreted as being identical to a statement that
# reads ‘Copyright (c) 2005, 2007, 2008, 2009, 2011, 2012’ and a copyright
# statement that reads ‘Copyright (c) 2005-2012’ should be interpreted as being
# identical to a statement that reads ‘Copyright (c) 2005, 2006, 2007, 2008,
# 2009, 2010, 2011, 2012’.
###########################


get_distro () {
  EXT=""
  if [[ $2 == *.tar.bz2* ]] ; then
    EXT="tar.bz2"
  elif [[ $2 == *.zip* ]] ; then
    EXT="zip"
  elif [[ $2 == *.tar.gz* ]] ; then
    EXT="tar.gz"
  elif [[ $2 == *.tgz* ]] ; then
    EXT="tgz"
  else
    echo "I don't understand the file type for $1"
    exit 1
  fi
  rm -f $1.$EXT
  if hash curl 2>/dev/null; then
    curl --retry 10 -sS -o $1.$EXT -L $2
  else
    wget --tries=10 -nv -O $1.$EXT $2
  fi
}

get_file () {
# output, source
  if hash curl 2>/dev/null; then
    curl -sS -o $1 -L $2
  else
    wget -nv -O $1 $2
  fi
}

if [ "$#" -ne "1" ] ; then
  echo "Please provide an installation path  such as /opt/ICGC"
  exit 0
fi

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

INST_PATH=$1

# get current directory
INIT_DIR=`pwd`

set -e
# cleanup inst_path
mkdir -p $INST_PATH
cd $INST_PATH
INST_PATH=`pwd`
mkdir -p $INST_PATH/bin
cd $INIT_DIR

export PATH="$INST_PATH/bin:$PATH"

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

echo -n "Building libdeflate ..."
if [ -e $SETUP_DIR/libdeflate.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  mkdir -p libdeflate
  get_distro "libdeflate" "https://github.com/ebiggers/libdeflate/archive/${VER_LIBDEFLATE}.tar.gz"
  tar --strip-components 1 -C libdeflate -zxf libdeflate.tar.gz
  cd libdeflate
  cmake -B build -DCMAKE_INSTALL_PREFIX:PATH=$INST_PATH && cmake --build build --target install
  cd $SETUP_DIR
  rm -r libdeflate.tar.gz
  touch $SETUP_DIR/libdeflate.success
fi

echo -n "Building isa-l ..."
if [ -e $SETUP_DIR/isa-l.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  mkdir -p isa-l
  get_distro "isa-l" "https://github.com/intel/isa-l/archive/refs/tags/${VER_ISAL}.tar.gz"
  tar --strip-components 1 -C isa-l -zxf isa-l.tar.gz
  cd isa-l
  ./autogen.sh
  ./configure --prefix=$INST_PATH --libdir=$INST_PATH/lib
  make
  make install
  cd $SETUP_DIR
  rm -r isa-l.tar.gz
  touch $SETUP_DIR/libdeflate.success
fi

echo -n "Building fastp ..."
if [ -e $SETUP_DIR/fastp.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  mkdir -p fastp
  get_distro "fastp" "https://github.com/OpenGene/fastp/archive/refs/tags/$VER_FASTP.tar.gz"
  tar --strip-components 1 -C fastp -zxf fastp.tar.gz
  cd fastp
  export LD_FLAGS=-L$LD_LIBRARY_PATH
  export PREFIX=$INST_PATH
  make -j $CPU
  make install
  cd $SETUP_DIR
  rm -r fastp.tar.gz
  touch $SETUP_DIR/libdeflate.success
fi