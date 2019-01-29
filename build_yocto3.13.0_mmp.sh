#!/bin/sh

echo "Admin_rcar" | sudo -S apt-get update
sudo apt-get upgrade

sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat libsdl1.2-dev xterm python-crypto cpio python python3 \
     python3-pip python3-pexpect xz-utils debianutils iputils-ping libssl-dev

mkdir work || exit
cd work
WORK=`pwd`
echo $WORK

cd ${WORK}
git clone git://git.yoctoproject.org/poky
git clone git://git.openembedded.org/meta-openembedded
git clone git://git.linaro.org/openembedded/meta-linaro.git
git clone git://github.com/renesas-rcar/meta-renesas

cd $WORK/poky
git checkout -b tmp 7e7ee662f5dea4d090293045f7498093322802cc
cd $WORK/meta-openembedded
git checkout -b tmp 352531015014d1957d6444d114f4451e241c4d23
cd $WORK/meta-linaro
git checkout -b tmp 75dfb67bbb14a70cd47afda9726e2e1c76731885
cd $WORK/meta-renesas
git checkout -b tmp 00f70f062aace04c051fa92d3cd7b887718fc313

cd ${WORK}
cp -f /home/rcar/Share/R-Car_Gen3_Series_Evaluation_Software_Package_*.zip ${WORK}/proprietary
ls -1 ${WORK}/proprietary/*.zip

export PKGS_DIR=${WORK}/proprietary
cd ${WORK}/meta-renesas
sh meta-rcar-gen3/docs/sample/copyscript/copy_evaproprietary_softwares.sh -f $PKGS_DIR
unset PKGS_DIR

###################################
# In case of MMP
###################################
cd ${WORK}
source poky/oe-init-build-env

cp ${WORK}/meta-renesas/meta-rcar-gen3/docs/sample/conf/h3ulcb/poky-gcc/mmp/*.conf ./conf/.
cd ${WORK}/build
cp conf/local-wayland.conf conf/local.conf

###################################
# vfat,
###################################
echo "CORE_IMAGE_EXTRA_INSTALL += \"util-linux\"" >> $WORK/build/conf/local.conf
echo "CORE_IMAGE_EXTRA_INSTALL += \"e2fsprogs-mke2fs\"" >> $WORK/build/conf/local.conf
echo "CORE_IMAGE_EXTRA_INSTALL += \"dosfstools\"" >> $WORK/build/conf/local.conf
echo "CONNECTIVITY_CHECK_URIS = \"\"" >> $WORK/build/conf/local.conf
echo "DISTRO_FEATURES_append = \" use_eva_pkg\"" >> $WORK/build/conf/local.conf

cd $WORK/build
bitbake core-image-weston -c fetchall -k
bitbake core-image-weston -k

