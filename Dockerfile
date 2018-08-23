# Configure the container's basic properties
FROM hgrasland/acts-tests:debug
LABEL Description="openSUSE Tumbleweed with ACTS and Verrou" Version="develop"
CMD bash


# === INSTALL VERROU ===

# Install the development version of verrou
RUN spack install verrou@develop

# Schedule Verrou to be loaded during container startup
RUN echo "spack load verrou" >> ${SETUP_ENV}

# HACK: Use the gold linker, hiding this from Spack to avoid a full rebuild
#
#       This is done in order to work around an incompatibility between Valgrind
#       3.13.0 and binutils 2.31, which causes Valgrind to fail to load
#       debugging symbols and thus Verrou to fail at everything related to them
#       (exclusions, delta-debugging...).
#
#       The problem should be fixed in Valgrind's master, so try to remove this
#       hack once Valgrind 3.14 is out and Verrou has moved to it.
#
RUN zypper in -y binutils-gold && update-alternatives --set ld /usr/bin/ld.gold


# === SETUP AN ACTS DEVELOPMENT ENVIRONMENT ===

# Start working on a development branch of ACTS, uninstalling the system
# version to shrink Docker image size
RUN spack uninstall -y ${ACTS_SPACK_SPEC}                                      \
    && git clone --branch=more-verrou-fixes                                    \
       https://gitlab.cern.ch/hgraslan/acts-core.git                           \
    && spack diy -d acts-core ${ACTS_SPACK_SPEC}

# Keep the location of the ACTS build directory around
ENV ACTS_BUILD_DIR=/root/acts-core/spack-build


# === TEST ACTS USING VERROU'S RANDOM-ROUNDING MODE ===

# Bring in the files needed for verrou-based testing
COPY excludes.ex ${ACTS_BUILD_DIR}/
COPY run.sh cmp.sh ${ACTS_BUILD_DIR}/IntegrationTests/

# Record the part of the verrou command line which we'll use everywhere
ENV VERROU_CMD_BASE="valgrind --tool=verrou                                    \
                              --rounding-mode=random                           \
                              --demangle=no                                    \
                              --exclude=${ACTS_BUILD_DIR}/excludes.ex"

# Run the ACTS test suite inside of Verrou, in verbose and single-thread mode
RUN cd ${ACTS_BUILD_DIR}                                                       \
    && spack load cmake                                                        \
    && ${VERROU_CMD_BASE} --trace-children=yes ctest -V

# Run the integration tests inside of Verrou as well
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests                                      \
    && ${VERROU_CMD_BASE} ./PropagationTests                                   \
    && ${VERROU_CMD_BASE} ./SeedingTest

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
#        To use verrou_dd, one currently needs the following hacks:
#        - Modify hardcoded /usr/bin/python to /usr/bin/env python in verrou
#        - Remove "python" symlink to python3 after verrou installation
#        - Tweak verrou_dd's spack package to require python and add itself
#          to the PYTHONPATH
#        - Symlink the DD.py site package to the regular python lib directory
#
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests                                      \
    && chmod +x run.sh cmp.sh                                                  \
    && verrou_dd run.sh cmp.sh


# === CLEAN UP BEFORE PUSHING ===

# Get rid of the largest delta-debugging artifacts
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests && rm -rf dd.sym

# Discard the ACTS build directory to save space
RUN rm -rf ${ACTS_BUILD_DIR}