# === DOCKER-SPECIFIC HACKERY ===

FROM hgrasland/acts-tests
LABEL Description="openSUSE Tumbleweed with ACTS and Verrou" Version="0.1"
CMD bash


# === SYSTEM SETUP ===

# Update the host system
RUN zypper ref && zypper dup -y

# Install valgrind's run-time prerequisites (hack? what hack?)
RUN zypper in -y valgrind valgrind-devel && zypper rm -y valgrind valgrind-devel

# Install valgrind's additional build prerequisites
RUN zypper in -y subversion automake which

# Install verrou's additional build prerequisites
RUN zypper in -y patch


# === INSTALL VERROU ===

# Download the valgrind source code (currently using v3.13.0)
RUN svn co --quiet svn://svn.valgrind.org/valgrind/tags/VALGRIND_3_13_0 valgrind

# Download verrou (currently using v1.1.0) and patch valgrind
RUN cd valgrind                                                                \
    && git clone --branch=v1.1.0 --depth 1                                     \
                 https://github.com/edf-hpc/verrou.git verrou                  \
    && patch -p0 < verrou/valgrind.diff

# Configure valgrind
#
# NOTE: You may need to remove the --enable-verrou-fma switch if you are using
#       an old CPU or virtual machine
#
RUN cd valgrind                                                                \
    && ./autogen.sh                                                            \
    && ./configure --enable-only64bit --enable-verrou-fma=yes

# Build and install valgrind
RUN cd valgrind                                                                \
    && make -j8                                                                \
    && make install

# Run the verrou test suite to check that everything is fine
RUN cd valgrind                                                                \
    && make -C tests check                                                     \
    && make -C verrou check                                                    \
    && perl tests/vg_regtest verrou                                            \
    && make -C verrou/unitTest

# Clean up after ourselves
RUN rm -rf valgrind


# === FINAL CLEAN UP ===

# Discard the system package cache to save up space
RUN zypper clean