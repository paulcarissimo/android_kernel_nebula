# nebula kernel compilation script


# Confirm 'make clean'
clear
echo "Compiling nebula kernel..."
echo -e "\n\nDo you want to make clean? \n"
echo -e "1. Yes"
echo -e "2. No"
read askclean


# Export paths and variables in shell
export PATH=$PATH:~/kernel/toolchains/arm-eabi-4.6/bin
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-


# Specify colors for shell
red='tput setaf 1'
green='tput setaf 2'
yellow='tput setaf 3'
blue='tput setaf 4'
violet='tput setaf 5'
cyan='tput setaf 6'
white='tput setaf 7'
normal='tput sgr0'
bold='setterm -bold'
date="date"


# Kernel compilation specific details
KERNEL_BUILD="nebula-v1.2-xenon92-`date '+%Y%m%d-%H%M'`"
TOOLCHAIN=~/kernel/toolchains/arm-eabi-4.6/bin/arm-eabi


# Variables
MODULES=./output/flashablezip/system/lib/modules


# Cleaning files from previous build
$cyan
if [ "$askclean" == "1" ]
then
        echo -e "\n\nCleaning... \n\n"
        make clean mrproper
fi

rm -rf arch/arm/boot/boot.img-zImage
rm -rf output/bootimg_processing
rm -rf output/flashablezip/system
rm -rf output/boot.img
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Copy prebuilt drivers
cp ../drivers/voicesolution/VoiceSolution.ko drivers/voicesolution/

# Making config for nebula kernel
$violet
echo "Making config for nebula kernel..."
make nebula_i9082_defconfig
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Compiling kernel
$red
echo "Compiling kernel..."
make -j4
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Processing boot.img
$yellow
echo "Processing boot.img..."
mkdir output/bootimg_processing
cp bootimg/stockbootimg/boot.img output/bootimg_processing/boot.img
cd output/bootimg_processing
rm -rf unpack
rm -rf output
rm -rf boot
mkdir unpack
mkdir outputbootimg
mkdir boot
cd unpack

echo "Extracting boot.img..."
../../../processing_tools/bootimg_tools/unmkbootimg -i ../boot.img
cd ../boot
gzip -dc ../unpack/ramdisk.cpio.gz | cpio -i
cd ../../../
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Copying the required files to make final boot.img
$green
echo "Copying output files to make the final boot.img..."
cp arch/arm/boot/zImage arch/arm/boot/boot.img-zImage
rm output/bootimg_processing/bootimage/unpack/boot.img-zImage
cp arch/arm/boot/boot.img-zImage output/bootimg_processing/unpack/boot.img-zImage	
rm boot.img-zImage
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Processing modules to be packed along with final boot.img
cd output/flashablezip
mkdir system
mkdir system/lib
mkdir system/lib/modules
cd ../../

find -name '*.ko' -exec cp -av {} $MODULES/ \;

$red
echo "Stripping Modules..."
cd $MODULES
for m in $(find . | grep .ko | grep './')
do echo $m
$TOOLCHAIN-strip --strip-unneeded $m
done
cd ../../../../../
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Making final boot.img
$blue
echo "Making output boot.img..."
cd output/bootimg_processing/outputbootimg

../../../processing_tools/bootimg_tools/mkbootfs ../boot | gzip > ../unpack/boot.img-ramdisk-new.gz

rm -rf ../../output/bootimg_processing/boot.img
cd ../../../

processing_tools/bootimg_tools/mkbootimg --kernel output/bootimg_processing/unpack/boot.img-zImage --ramdisk output/bootimg_processing/unpack/boot.img-ramdisk-new.gz -o output/bootimg_processing/outputbootimg/boot.img --base 0 --pagesize 4096 --kernel_offset 0xa2008000 --ramdisk_offset 0xa3000000 --second_offset 0xa2f00000 --tags_offset 0xa2000100 --cmdline 'console=ttyS0,115200n8 mem=832M@0xA2000000 androidboot.console=ttyS0 vc-cma-mem=0/176M@0xCB000000'

rm -rf unpack
rm -rf boot
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Making output flashable zip
$green
echo "Making output flashable zip and packing everything..."
cd output/flashablezip/
mkdir outputzip
mkdir outputzip/system
mkdir outputzip/system/lib
mkdir system
mkdir system/lib

cp -avr META-INF/ outputzip/
cp -avr system/lib/modules/ outputzip/system/lib/
cp ../bootimg_processing/outputbootimg/boot.img outputzip/boot.img

echo "Moving old zip file..."
mkdir old_builds_zip
mv outputzip/*.zip old_builds_zip/

echo "Packing files into zip..."
cd outputzip
zip -r $KERNEL_BUILD.zip *
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# Cleaning
$blue
echo "Cleaning..."

rm -rf META-INF
rm -rf system
rm boot.img
cd ../../
rm -rf ../arch/arm/boot/boot.img-zImage
rm -rf bootimg_processing
rm -rf flashablezip/system
echo ""
echo ""
echo "==========================================================="
echo ""
echo ""


# End of script
$red
echo ""
echo "*************END OF KERNEL COMPILATION SCRIPT**************"
echo ""
echo "*********************HAPPY FLASHING************************"
$normal
