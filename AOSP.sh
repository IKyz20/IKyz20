#!/bin/bash
#
# Script For Building Android arm64 Kernel
#
# Copyright (C) 2021-2023 RooGhz720 <rooghz720@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

export CHATID API_BOT TYPE_KERNEL

# Kernel build config
TYPE="[AOSP]"
KERNEL_NAME="IKyz-Kernel"
DEVICE="Poco M3/Redmi 9T (Chime/Juice)"
DEFCONFIG="vendor/chime_defconfig"
AnyKernel="https://github.com/IKyz20/Anykernel3"
AnyKernelbranch="main"
HOSST="IKyz@MyLabs"
USEER="MasIKyz"
MESIN="Git Workflows"

# clang config
REMOTE="https://gitlab.com"
TARGET="GhostMaster69-dev"
REPO="cosmic-clang"
BRANCH="master"

# setup telegram env
export WAKTU=$(date +"%T")
export TGL=$(date +"%d-%m-%Y")
export BOT_MSG_URL="https://api.telegram.org/bot$API_BOT/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$API_BOT/sendDocument"


tg_sticker() {
   curl -s -X POST "https://api.telegram.org/bot$API_BOT/sendSticker" \
        -d sticker="$1" \
        -d chat_id=$CHATID
}

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
        -d "parse_mode=markdown" \
        -d text="$1"
}

tg_post_build() {
        #Post MD5Checksum alongwith for easeness
        MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

        #Show the Checksum alongwith caption
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=markdown" \
        -F caption="$3 MD5 \`$MD5CHECK\`"
}

tg_error() {
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3Failed to build , check <code>error.log</code>"
}

# clang stuff
		echo -e "$green << cloning clang >> \n $white"
		git clone --depth=1 -b "$BRANCH" "$REMOTE"/"$TARGET"/"$REPO" "$HOME"/clang
		# git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git "$HOME"/clang/aarch64-linux-android-4.9
		# git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git "$HOME"/clang/arm-linux-androideabi-4.9

	export PATH="$HOME/clang/bin:$PATH"
	export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')

# Setup build process

build_kernel() {
Start=$(date +"%s")

    make O=out CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 -j$(nproc)  2>&1 | tee error.log

End=$(date +"%s")
Diff=$(($End - $Start))
}

# Let's start
echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"

mkdir -p out

make O=out clean && make O=out mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)
KOMIT=$(git log --pretty=format:'"%h : %s"' -1)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

export IMG="$MY_DIR"/out/arch/arm64/boot/Image

        if [ -f "$IMG" ]; then
                echo -e "$green << selesai dalam $(($Diff / 60)) menit and $(($Diff % 60)) detik >> \n $white"
        else
                echo -e "$red << Gagal dalam membangun kernel!!! , cek kembali kode anda >>$white"
                tg_post_msg "GAGAL!!! uploading log"
                tg_error "error.log" "$CHATID"
                tg_post_msg "done" "$CHATID"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                exit 1
        fi

TEXT1="
*Build Completed Successfully*
━━━━━━━━━ஜ۩۞۩ஜ━━━━━━━━
* Device* : \`$DEVICE\`
* Code name* : \`Chime | Juice\`
* Variant Build* : \`$TYPE\`
* Time Build* : \`$(($Diff / 60)) menit\`
* Branch Build* : \`$BRANCH\`
* System Build* : \`$MESIN\`
* Date Build* : \`$TGL\` \`$WAKTU\`
* Last Commit* : \`$KOMIT\`
* Author* : @Z200AZ
━━━━━━━━━ஜ۩۞۩ஜ━━━━━━━━
"

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone --depth=1 "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                cd zip
                export ZIP="$KERNEL_NAME"-"$TYPE"-"$TGL"
                zip -r9 "$ZIP" * -x .git README.md LICENSE *placeholder
                curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
                java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
                tg_sticker "CAACAgUAAxkBAAGLlS1jnv1FJAsPoU7-iyZf75TIIbD0MQACYQIAAvlQCFTxT3DFijW-FSwE"
                tg_post_msg "$TEXT1" "$CHATID"
                tg_post_build "$ZIP"-signed.zip "$CHATID"
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
                exit
        fi

