# Stage 1: Build                                                 (1)
FROM ubuntu:24.04 AS builder

# Update package lists and install build dependencies           (2)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
       git cmake g++ ninja-build openmpi-bin libopenmpi-dev \
       python3 python3-pip python3-dev \
       libboost-test-dev libboost-serialization-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the application source code into the builder stage         (3)
COPY . /workspaces/mpihelloworld

# Set the working directory for the build                           (4)
WORKDIR /workspaces/mpihelloworld

# Set environment variables to allow MPI to run as root             (5)
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Configure, build, test, and install the application using CMake presets (6)
RUN cmake --preset default      \
    && cmake --build --preset default                  \
    && ctest --preset default                          \
    && cmake --build --preset default -t install        \
    && rm -rf build

# Stage 2: Runtime                                                 (7)
FROM ubuntu:24.04 AS runtime

# Install runtime dependencies (only what is needed to run the application) (8)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends           \
       openmpi-bin libopenmpi3t64                           \
       libboost-test1.83.0 libboost-serialization1.83.0     \
       python3 python3-pip python3-dev                      \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the installed application from the builder stage             (9)
COPY --from=builder /usr/local /usr/local

# Optionally, copy additional runtime files if needed                 (10)
# COPY --from=builder /workspaces/mpihelloworld/config /config

# Set the working directory (if needed)                              (11)
WORKDIR /workspaces/mpihelloworld

# Set the runtime environment variables for MPI                       (12)
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1