
FROM ubuntu:20.04

# Set arguments with default values
ARG TOOL_PATH=/opt
ARG ARM_VERSION=12.3.rel1
ARG ESP8266_RTOS_SDK_VERSION=3.4
ARG CMAKE_VERSION=3.28.6-0kitware1ubuntu20.04.1
ARG CPPCHECK_VERSION=2.15.0
ARG VOL_PATH=/usr/src

# Set timezone
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install prerequisite packages
RUN apt-get update && apt-get install -y \
    build-essential wget curl ca-certificates gpg git python3 python3-pygments \
    gcc make libncurses-dev flex bison gperf python3-serial python3-pip

# Download & extract the ARM GNU toolchain, and add to PATH
WORKDIR ${TOOL_PATH}
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_VERSION}/binrel/arm-gnu-toolchain-${ARM_VERSION}-x86_64-arm-none-eabi.tar.xz | tar xvJ
ENV PATH=$PATH:${TOOL_PATH}/arm-gnu-toolchain-${ARM_VERSION}-x86_64-arm-none-eabi/bin

# Download & extract the ESP8266 toolchain
RUN wget -qO- https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz | tar xvz && \
    wget -qO- https://github.com/espressif/ESP8266_RTOS_SDK/archive/refs/tags/v${ESP8266_RTOS_SDK_VERSION}.tar.gz | tar xvz && \
    python3 -m pip install --user -r ${TOOL_PATH}/ESP8266_RTOS_SDK-${ESP8266_RTOS_SDK_VERSION}/requirements.txt
ENV PATH=$PATH:${TOOL_PATH}/xtensa-lx106-elf/bin
ENV IDF_PATH=${TOOL_PATH}/ESP8266_RTOS_SDK-${ESP8266_RTOS_SDK_VERSION}

# Build CMake from source
RUN test -f /usr/share/doc/kitware-archive-keyring/copyright || wget -qO- https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    test -f /usr/share/doc/kitware-archive-keyring/copyright || rm /usr/share/keyrings/kitware-archive-keyring.gpg && \
    apt-get install -y kitware-archive-keyring cmake-data=${CMAKE_VERSION} cmake=${CMAKE_VERSION}

# Build CppCheck from source
RUN wget -qO- https://github.com/danmar/cppcheck/archive/refs/tags/${CPPCHECK_VERSION}.tar.gz | tar xvz && \
    cd cppcheck-${CPPCHECK_VERSION} && \
    mkdir build_RelWithDebInfo && \
    cd build_RelWithDebInfo && \
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_MATCHCOMPILER=ON .. && \
    cmake --build . --config RelWithDebInfo
ENV PATH=$PATH:${TOOL_PATH}/cppcheck-${CPPCHECK_VERSION}/build_RelWithDebInfo/bin:${TOOL_PATH}/cppcheck-${CPPCHECK_VERSION}/htmlreport

# Prepare mount point for source files. Using volume for persistant storage to access the build outputs.
VOLUME ${VOL_PATH}

# Set the working directory source file volume path, set shell, run the build commands
WORKDIR ${VOL_PATH}
ENTRYPOINT [ "/bin/bash" ]
