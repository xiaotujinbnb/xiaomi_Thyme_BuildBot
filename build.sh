#!/bin/bash
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

# 内核工作目录
export KERNEL_DIR=$(pwd)
# 内核 defconfig 文件
export KERNEL_DEFCONFIG=vendor/umi_defconfig
# export KERNEL_DEFCONFIG=vendor/umi_defconfig

# 压缩包名字
ZIP_NAME="umi"

# 编译临时目录，避免污染根目录
export OUT=out

# 设置编译目录
ANYKERNEL_DIR=/home/tuzi/AnyKernel3

#环境配置
export CLANG_PATH=/home/tuzi/proton-clang
export GCC64_PATH=/home/tuzi/aarch64-linux-android-4.9
export GCC32_PATH=/home/tuzi/arm-linux-androideabi-4.9

export PATH=${CLANG_PATH}/bin:${GCC64_PATH}/bin:${GCC32_PATH}/bin:${PATH}

# arch平台
export ARCH=arm64
export SUBARCH=arm64

# 只使用clang编译需要配置
export LLVM=1
export BUILD_INITRAMFS=1

# 编译时线程指定，默认单线程，可以通过参数指定，比如8线程编译
# ./build.sh 4 
TH_COUNT=20
if [[ "" != "$1" ]]; then
    TH_NUM=$1
fi

# 编译参数#aarch64-linux-gnu-   aarch64-linux-android-
export DEF_ARGS="O=${OUT} \
ARCH=${ARCH} \
CROSS_COMPILE=${GCC64_PATH}/bin/aarch64-linux-android- \
CLANG_TRIPLE=${GCC64_PATH}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${GCC32_PATH}/bin/arm-linux-androideabi- \
CC=${CLANG_PATH}/bin/clang \
AR=${CLANG_PATH}/bin/llvm-ar \
NM=${CLANG_PATH}/bin/llvm-nm \
LD=${CLANG_PATH}/bin/ld.lld \
HOSTCC=${CLANG_PATH}/bin/clang \
HOSTCXX=${CLANG_PATH}/bin/clang++ \
OBJCOPY=${CLANG_PATH}/bin/llvm-objcopy \
OBJDUMP=${CLANG_PATH}/bin/llvm-objdump \
READELF=${CLANG_PATH}/bin/llvm-readelf \
OBJSIZE=${CLANG_PATH}/bin/llvm-size \
STRIP=${CLANG_PATH}/bin/llvm-strip \
LLVM_IAS=1 \
LLVM=1"

export BUILD_ARGS="-j${TH_COUNT} ${DEF_ARGS}"   


# 构建AnyKernel3包
buildAnyKernel() {
	echo "------------------------------"
	echo "    Build flashable zip       "
	echo "------------------------------"


	cp -rf $OUT/arch/arm64/boot/Image.gz $ANYKERNEL_DIR/Image.gz
	#cp -rf $OUT/arch/arm64/boot/dtb $ANYKERNEL_DIR/dtb;
	#cp -rf $OUT/arch/arm64/boot/dtbo.img $ANYKERNEL_DIR/dtbo.img;
	cd $ANYKERNEL_DIR
	OUTPUT_FILE=${ZIP_NAME}-tuzi-$(date +"%y.%m.%d").zip
	zip -r $OUTPUT_FILE *
	mv $OUTPUT_FILE $KERNEL_DIR/$OUTPUT_FILE
	rm -rf $OUTPUT_FILE

	echo "The output is $OUTPUT_FILE"
	cd $KERNEL_DIR
}


# 清除以往的构建
clean() {
	echo "------------------------------"
	echo "      Clean old builds        "
	echo "------------------------------"

	# 清楚以往的刷机包
	cd $KERNEL_DIR
	rm -rf $KERNEL_DIR/*.zip

	# 清楚以往的构建文件
	echo "Clean source tree and build files..."
	make mrproper -j$TH_COUNT
	make clean -j$TH_COUNT
	rm -rf $OUT
	
}

#选择配置文件
make_defconfig() {
        echo "------------------------------"
	echo "      Make defconfig        "
	echo "------------------------------"
        # make defconfig
        make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
        # 如果命令没有出错，继续执行，否则退出编译
        if [[ "0" != "$?" ]]; then
                echo -e ">>> ${R}make defconfig error, cuowu!"
                exit 1
        fi
}

# 选择配置文件
make_defconfig() {
        echo "------------------------------"
	echo "      Make defconfig        "
	echo "------------------------------"
        # make defconfig
        make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
        # 如果命令没有出错，继续执行，否则退出编译
        if [[ "0" != "$?" ]]; then
                echo -e ">>> ${R}make defconfig error, cuowu!"
                exit 1
        fi
}

# ui配置文件
make_menuconfig() {
        echo "------------------------------"
	echo "      Make menuconfig        "
	echo "------------------------------"
        # make defconfig
        make ${DEF_ARGS} menuconfig
        # 如果命令没有出错，继续执行，否则退出编译
        if [[ "0" != "$?" ]]; then
                echo -e ">>> ${R}make defconfig error, cuowu!"
                exit 1
        fi
}

#开始构建内核
build_kernel(){
        echo "------------------------------"
	echo "      Make Kernel        "
	echo "------------------------------"

        # make ${BUILD_ARGS} modules_prepare 
        make ${BUILD_ARGS} 
        # make ${BUILD_ARGS} menuconfig
        #make ${BUILD_ARGS} savedefconfig
        # make ${BUILD_ARGS} #modules_prepare
        if [[ "0" != "$?" ]]; then
                echo ">>> ${R}build kernel error, build stop!"
                exit 1
        fi
        echo ">>> ${G}build Kernel"
}

main(){
        make_defconfig && \
        build_kernel && \
        buildAnyKernel
}


#main 2>&1 | tee "$KERNEL_DIR/build_kernel.log"

main



