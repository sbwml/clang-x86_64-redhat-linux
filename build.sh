#!/bin/bash

script_action=${1}

setup() {
	# Setting up the environment
 	curl -s https://repo.cooluc.com/mailbox.repo > /etc/yum.repos.d/mailbox.repo
	yum install -y centos-release-scl-rh centos-release-scl epel-release
	yum install -y libedit-devel libxml2-devel python3 python3-devel ncurses-devel git2 zlib-devel libffi-devel libxml2-devel zstd libzstd-devel xz xz-devel
	yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils-devel devtoolset-11-runtime devtoolset-11-libstdc++-devel

	# cmake
	git clone https://android.googlesource.com/platform/prebuilts/cmake/linux-x86 cmake-x86 --depth=1

	# ninja
	git clone https://android.googlesource.com/platform/prebuilts/ninja/linux-x86 ninja
	cp -a ninja/ninja /usr/bin
}

build_llvm() {
	source /opt/rh/devtoolset-11/enable
	export PATH="/cmake-x86/bin:$PATH"
	# Configure LLVM host tools
	cmake -G Ninja -S llvm-project/llvm -B llvm-host \
		-DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
		-DCMAKE_BUILD_TYPE=Release -Wno-dev

	# Build LLVM host tools
	cmake --build llvm-host \
		--target llvm-tblgen clang-tblgen llvm-config clang-tidy-confusable-chars-gen clang-pseudo-gen
	export HOSTBIN_PATH="/llvm-host/bin"
	export LLVM_NATIVE_TOOL_DIR="$HOSTBIN_PATH"
	export LLVM_TABLEGEN="$HOSTBIN_PATH/llvm-tblgen"
	export CLANG_TABLEGEN="$HOSTBIN_PATH/clang-tblgen"
	export LLVM_CONFIG_PATH="$HOSTBIN_PATH/llvm-config"
	export LLVM_VERSION="$1"

	# Configure LLVM
	CMAKE_TOOLCHAIN_FILE="/cmake/x86_64-redhat-linux.cmake"
	CMAKE_INITIAL_CACHE="/cmake/llvm-distribution.cmake"
	cmake -G Ninja -S llvm-project/llvm -B llvm-build \
		-DCMAKE_INSTALL_PREFIX=llvm-install \
		-DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
		-C $CMAKE_INITIAL_CACHE -Wno-dev

	# Build LLVM
	cmake --build llvm-build

	# Install LLVM
	cmake --build llvm-build --target install-distribution
}

case $script_action in
	"setup")
		setup
	;;
	"build")
		build_llvm "$2"
	;;
	*)
		exit 0
	;;
esac
