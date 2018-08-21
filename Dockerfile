# Configure the container's basic properties
FROM hgrasland/acts-tests:debug
LABEL Description="openSUSE Tumbleweed with ACTS and Verrou" Version="develop"
CMD bash

# Install the development version of verrou
RUN spack install verrou@develop

# Schedule Verrou to be loaded during container startup
RUN echo "spack load verrou" >> ${SETUP_ENV}

# Bring back the ACTS build environment
RUN spack uninstall -y ${ACTS_SPACK_SPEC} && spack build ${ACTS_SPACK_SPEC}

# Cache the location of the ACTS build directory (it takes a while to compute)
RUN export ACTS_SOURCE_DIR=`spack location --build-dir ${ACTS_SPACK_SPEC}`     \
    && echo "export ACTS_SOURCE_DIR=${ACTS_SOURCE_DIR}" >> ${SETUP_ENV}        \
    && echo "export ACTS_BUILD_DIR=${ACTS_SOURCE_DIR}/spack-build"             \
            >> ${SETUP_ENV}

# Bring the files needed for verrou-based testing, fixing absolute file paths
COPY run.sh cmp.sh excludes.ex /root
RUN sed s#/root/acts-core/build#${ACTS_BUILD_DIR}#g excludes.ex                \
        > ${ACTS_BUILD_DIR}/excludes.ex                                        \
    && rm excludes.ex                                                          \
    && mv run.sh cmp.sh ${ACTS_BUILD_DIR}/IntegrationTests

# Record the part of the verrou command line which we'll use everywhere
RUN echo "export VERROU_CMD_BASE=\"                                            \
                     valgrind --tool=verrou                                    \
                              --rounding-mode=random                           \
                              --demangle=no                                    \
                              --exclude=${ACTS_BUILD_DIR}/excludes.ex\""       \
         >> ${SETUP_ENV}

# Run the ACTS test suite inside of Verrou, in verbose and single-thread mode
#
# FIXME: There are new failures here, likely caused by the enormous recent
#        extrapolation merge request.
#
RUN cd ${ACTS_BUILD_DIR}                                                       \
    && spack env acts-core ${VERROU_CMD_BASE} --trace-children=yes ctest -V

# Run the integration tests inside of Verrou as well
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests                                      \
    && spack env acts-core ${VERROU_CMD_BASE} ./PropagationTests               \
    && spack env acts-core ${VERROU_CMD_BASE} ./SeedingTest

# Delta-debug the ACTS propagation to find its numerical instability regions.
# This is how the libm exclusion file was generated.
#
# NOTE: In principle, delta-debugging should go down to the granularity of
#       individual source lines, but this currently fails. I think that is
#       because the instabilities are in the libm and I do not have debugging
#       symbols for that. But since we already know that the libm trigonometric
#       function instabilities are a false alarm, this is not a big deal.
#
# FIXME: This is currently broken because verrou_dd has a hardcoded dependency
#        on /usr/bin/python3.
#
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests                                      \
    && chmod +x run.sh cmp.sh                                                  \
    && spack env acts-core verrou_dd run.sh cmp.sh

# Get rid of the largest delta-debugging artifacts
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests && rm -rf dd.sym

# Discard the ACTS build directory and the associated environment setup
RUN spack clean ${ACTS_SPACK_SPEC}                                             \
    && mv ${SETUP_ENV} ${SETUP_ENV}.old                                        \
    && grep -E --invert-match "ACTS_(SOURCE|BUILD)_DIR" ${SETUP_ENV}.old       \
            >> ${SETUP_ENV}                                                    \
    && rm ${SETUP_ENV}.old