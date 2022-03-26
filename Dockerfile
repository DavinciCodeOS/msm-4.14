FROM registry.fedoraproject.org/fedora-minimal:rawhide

# Install all dependencies
RUN microdnf install -y git-core diffutils findutils glibc-headers-x86 glibc-devel openssl-devel which bc bash perl python3

# Install a clang/LLVM toolchain from Google
RUN git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --single-branch -b ndk-r25-beta1 --depth 1 /tmp/toolchain && \
    rm -rf /tmp/toolchain/.git && \
    mv /tmp/toolchain/clang-r437112b /toolchain && \
    rm -rf /tmp/toolchain

# Copy Kernel sources (current working directory) to /src
WORKDIR /src
COPY . .

# Set up environment variables for Kbuild
ENV KBUILD_BUILD_USER=adrian
ENV KBUILD_BUILD_HOST=lillia
ENV PATH="/toolchain/bin:$PATH"

# Cleanup remains of old builds
RUN make mrproper LLVM=1 LLVM_IAS=1 && rm -rf out/

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
    cp /src/out/arch/arm64/boot/Image.gz . && \
    cp /src/out/arch/arm64/boot/dtbo.img . && \
    zip -r9 kernel.zip ./ && \
    mv kernel.zip /

WORKDIR /
