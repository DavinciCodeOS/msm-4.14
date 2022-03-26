FROM fedora-minimal:35

# Install all dependencies
RUN microdnf install -y git-core findutils glibc-headers-x86 glibc-devel openssl-devel which bc bash perl

# Make Docker use bash (requires --format docker in podman)
SHELL ["/bin/bash", "-c"]

# Install a clang/LLVM toolchain from Google
RUN git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --single-branch -b ndk-r25-beta1 --depth 1 /tmp/toolchain && \
    git clone https://android.googlesource.com/platform/prebuilts/misc --single-branch -o aosp --depth 1 /tmp/misc && \
    rm -rf /tmp/toolchain/.git && \
    mv /tmp/toolchain/clang-r437112b /toolchain && \
    mv /tmp/misc/linux-x86/libufdt/mkdtimg /toolchain/bin/ && \
    rm -rf /tmp/toolchain && \
    rm -rf /tmp/misc

# Copy Kernel sources (current working directory) to /src
WORKDIR /src
COPY . .

# Set up environment variables for Kbuild
ENV KBUILD_BUILD_USER=adrian
ENV KBUILD_BUILD_HOST=lillia
ENV PATH="/toolchain/bin:$PATH"

# Cleanup remains of old builds
RUN make mrproper LLVM=1 LLVM_IAS=1 && rm -rf out/

# Fetch wireguard sources
RUN ./scripts/fetch-latest-wireguard.sh

# Make the config
RUN make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 davinci_defconfig

# Set the build parameters
ENV KBUILD_BUILD_USER=adrian
ENV KBUILD_BUILD_HOST=lillia

# Compile the Kernel
RUN make -j$(nproc) \
        O=out \
        ARCH=arm64 \
        LLVM=1 \
        LLVM_IAS=1 \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-

# Prepare a zip
RUN cd / && \
    git clone --single-branch -b main --depth 1 https://github.com/DavinciCodeOS/AnyKernel3.git && \
    cd AnyKernel3 && \
    rm -rf .git README.md && \
    cp /src/out/arch/arm64/boot/Image.gz-dtb . && \
    cp /src/out/arch/arm64/boot/dtbo.img . && \
    zip -r9 kernel.zip ./ && \
    mv kernel.zip /

WORKDIR /
