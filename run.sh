#!/bin/bash
DIR="$1"
WORKDIR="/root/acts-core/build/IntegrationTests"
valgrind --tool=verrou --rounding-mode=random --demangle=no $WORKDIR/PropagationTests > ${DIR}/results.dat