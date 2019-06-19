#!/usr/bin/env bash
# Copyright 2019 Google Inc.
# All Rights Reserved.
#
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

VER=2.17

wget http://distfiles.gentoo.org/distfiles/sandbox-${VER}.tar.xz
tar -xvf sandbox-${VER}.tar.xz
pushd sandbox-${VER} && ./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc && make && sudo make install && popd

set -evx

. ci/get-nprocessors.sh

# if possible, ask for the precise number of processors,
# otherwise take 2 processors as reasonable default; see
# https://docs.travis-ci.com/user/speeding-up-the-build/#Makefile-optimization
if [ -x /usr/bin/getconf ]; then
    NPROCESSORS=$(/usr/bin/getconf _NPROCESSORS_ONLN)
else
    NPROCESSORS=2
fi
# as of 2017-09-04 Travis CI reports 32 processors, but GCC build
# crashes if parallelized too much (maybe memory consumption problem),
# so limit to 4 processors for the time being.
if [ $NPROCESSORS -gt 4 ] ; then
	echo "$0:Note: Limiting processors to use by make from $NPROCESSORS to 4."
	NPROCESSORS=4
fi
# Tell make to use the processors. No preceding '-' required.
MAKEFLAGS="j${NPROCESSORS}"
export MAKEFLAGS

env | sort

# Set default values to OFF for these variables if not specified.
: "${NO_EXCEPTION:=OFF}"
: "${NO_RTTI:=OFF}"
: "${COMPILER_IS_GNUCXX:=OFF}"

mkdir build || true
cd build
sandbox
cmake -Dgtest_build_samples=ON \
      -Dgtest_build_tests=ON \
      -Dgmock_build_tests=ON \
      -Dcxx_no_exception=$NO_EXCEPTION \
      -Dcxx_no_rtti=$NO_RTTI \
      -DCMAKE_COMPILER_IS_GNUCXX=$COMPILER_IS_GNUCXX \
      -DCMAKE_CXX_FLAGS=$CXX_FLAGS \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      ..
make
CTEST_OUTPUT_ON_FAILURE=1 make test
