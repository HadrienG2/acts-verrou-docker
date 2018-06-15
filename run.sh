#!/bin/bash
DIR="$1"
WORKDIR="/root/acts-core/build/IntegrationTests"
valgrind --tool=verrou --rounding-mode=random --demangle=no --exclude="$WORKDIR/libm.ex" $WORKDIR/PropagationTests > ${DIR}/results.dat