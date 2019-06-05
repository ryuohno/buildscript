#!/bin/sh

set -x

#-----------------------------------------------------------------------------------------
# TARGET(You edit.)
#-----------------------------------------------------------------------------------------
# H3, M3, V3H
export SUPPORT_SOC=H3

# salvator-x, sk, kingfisher, condor
export SUPPORT_BOARD=sk

# 3.13.0, 3.15.0
export BSP_VER=3.15.0

# mmp, gfx, bsp
export SELECT_PKG=mmp

# free
export ORG=org

# To your environment.
export TFTPD_PUBLIC=/IMAGE-RFS
export NFSD_SHARE=${TFTPD_PUBLIC}
export SREC_TOP=${TFTPD_PUBLIC}
export DIR_DOWNLOAD=/home/rcar/ダウンロード

#-----------------------------------------------------------------------------------------
# conditions
#-----------------------------------------------------------------------------------------
if [ ${SUPPORT_BOARD} = "sk" ]; then
    if [ ${SUPPORT_SOC} = "H3" ]; then
        export REL_BOARD_NAME=h3ulcb
    else
        export REL_BOARD_NAME=m3ulcb
    fi
else
    export REL_BOARD_NAME=${SUPPORT_BOARD}
fi

if [ ${SELECT_PKG} = "only" ]; then
    export BB_ARG=core-image-minimal
else
    export BB_ARG=core-image-weston
fi

if [ ${BSP_VER} = "3.13.0" ]; then
    export HASH_POKY=7e7ee662f5dea4d090293045f7498093322802cc
    export HASH_OE=352531015014d1957d6444d114f4451e241c4d23
    export HASH_LINARO=75dfb67bbb14a70cd47afda9726e2e1c76731885
    export HASH_RENESAS=00f70f062aace04c051fa92d3cd7b887718fc313

elif [ ${BSP_VER} = "3.15.0" ]; then
    export HASH_POKY=7e7ee662f5dea4d090293045f7498093322802cc
    export HASH_OE=352531015014d1957d6444d114f4451e241c4d23
    export HASH_LINARO=75dfb67bbb14a70cd47afda9726e2e1c76731885
    export HASH_RENESAS=8af0b7d6e445b532088a068dc012757001be3a1f

else
    echo "## script error !!! ##"
#    exit
fi


#-----------------------------------------------------------------------------------------
# Install required packages 
#-----------------------------------------------------------------------------------------
echo "Admin_rcar" | sudo -S apt-get -y update
sudo apt-get -y upgrade

sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat libsdl1.2-dev xterm python-crypto cpio python python3 \
     python3-pip python3-pexpect xz-utils debianutils iputils-ping libssl-dev

#-----------------------------------------------------------------------------------------
# WORK
#-----------------------------------------------------------------------------------------
mkdir work || :
cd work
export WORK=`pwd`
echo ${WORK}

#-----------------------------------------------------------------------------------------
# Clone basic Yocto layers
#-----------------------------------------------------------------------------------------
cd ${WORK}
git clone git://git.yoctoproject.org/poky
git clone git://git.openembedded.org/meta-openembedded
git clone git://git.linaro.org/openembedded/meta-linaro.git
git clone git://github.com/renesas-rcar/meta-renesas

#-----------------------------------------------------------------------------------------
# Switch to proper branches/commits
#-----------------------------------------------------------------------------------------
cd ${WORK}/poky
git checkout -b tmp ${HASH_POKY}
cd ${WORK}/meta-openembedded
git checkout -b tmp ${HASH_OE}
cd ${WORK}/meta-linaro
git checkout -b tmp ${HASH_LINARO}
cd ${WORK}/meta-renesas
git checkout -b tmp ${HASH_RENESAS}

#-----------------------------------------------------------------------------------------
# Download proprietary driver modules to $WORK/proprietary folder.
# You should see the following files: 
#-----------------------------------------------------------------------------------------
if [ ${SELECT_PKG} = "mmp" ] || [ ${SELECT_PKG} = "gfx" ]; then
    cd ${WORK}
    mkdir proprietary || :
    export PKGS_DIR=${WORK}/proprietary
    cp -f ${DIR_DOWNLOAD}/R-Car_Gen3_Series_Evaluation_Software_Package_*.zip ${PKGS_DIR}
    ls -1 ${PKGS_DIR}/*.zip

    cd ${WORK}/meta-renesas
    bash meta-rcar-gen3/docs/sample/copyscript/copy_evaproprietary_softwares.sh -f ${PKGS_DIR}
    unset PKGS_DIR
fi

#-----------------------------------------------------------------------------------------
# Setup build environment 
#-----------------------------------------------------------------------------------------
cd ${WORK}
source poky/oe-init-build-env

#-----------------------------------------------------------------------------------------
# Prepare default configuration files. 
#-----------------------------------------------------------------------------------------
export DIR_CONF_SRC=${WORK}/meta-renesas/meta-rcar-gen3/docs/sample/conf/${REL_BOARD_NAME}/poky-gcc/${SELECT_PKG}
export DIR_CONF_DST=${WORK}/build/conf

if [ ${SELECT_PKG} = "mmp" ] || [ ${SELECT_PKG} = "gfx" ]; then
    cp ${DIR_CONF_SRC}/*.conf ${DIR_CONF_DST}/.
    cd ${WORK}/build
    cp ${DIR_CONF_DST}/local-wayland.conf ${DIR_CONF_DST}/local.conf

else
    cp ${DIR_CONF_SRC}/*.conf ${DIR_CONF_DST}/.

fi

#-----------------------------------------------------------------------------------------
# Add Packages
#-----------------------------------------------------------------------------------------
echo "CORE_IMAGE_EXTRA_INSTALL += \"util-linux\"" >> $WORK/build/conf/local.conf
echo "CORE_IMAGE_EXTRA_INSTALL += \"e2fsprogs-mke2fs\"" >> $WORK/build/conf/local.conf
echo "CORE_IMAGE_EXTRA_INSTALL += \"dosfstools\"" >> $WORK/build/conf/local.conf

#-----------------------------------------------------------------------------------------
# Error avoidance
#-----------------------------------------------------------------------------------------
echo "CONNECTIVITY_CHECK_URIS = \"\"" >> $WORK/build/conf/local.conf

#-----------------------------------------------------------------------------------------
# Edit local.conf with evaluation packages requirements:
#-----------------------------------------------------------------------------------------
echo "DISTRO_FEATURES_append = \" use_eva_pkg\"" >> $WORK/build/conf/local.conf

#-----------------------------------------------------------------------------------------
# 
#-----------------------------------------------------------------------------------------
cd $WORK/build
bitbake ${BB_ARG} -k -c fetchall
bitbake ${BB_ARG} -k

#-----------------------------------------------------------------------------------------
# Archive kernel Image
#-----------------------------------------------------------------------------------------
export DIR_ARCHIVE=${WORK}/build/tmp/deploy/images
export DIR_DEPLOY=${DIR_ARCHIVE}/${REL_BOARD_NAME}
export TIME_STAMP=`date +%Y%m%d_%H%M%S`
tar jcvf ${DIR_ARCHIVE}/${SUPPORT_SOC}${SUPPORT_BOARD}${BSP_VER}${SELECT_PKG}_${ORG}_${TIME_STAMP}.tar.bz2 ${DIR_DEPLOY}

#-----------------------------------------------------------------------------------------
# Setup kernel Image, root file system
#-----------------------------------------------------------------------------------------
export DIR_TFTP=${TFTPD_PUBLIC}/${SUPPORT_SOC}/${SUPPORT_BOARD}/${BSP_VER}/${SELECT_PKG}/${ORG}/tftpboot
mkdir -p ${DIR_TFTP}
export DIR_RFS=${NFSD_SHARE}/${SUPPORT_SOC}/${SUPPORT_BOARD}/${BSP_VER}/${SELECT_PKG}/${ORG}/rfs
mkdir -p ${DIR_RFS}
export DIR_SREC=${SREC_TOP}/${SUPPORT_SOC}/${SUPPORT_BOARD}/${BSP_VER}/${SELECT_PKG}/${ORG}/srec
mkdir -p ${DIR_SREC}
cp ${DIR_DEPLOY}/Image ${DIR_TFTP}
cp ${DIR_DEPLOY}/Image*.dtb ${DIR_TFTP}
cp ${DIR_DEPLOY}/*.srec ${DIR_SREC}
tar jxvf ${DIR_DEPLOY}/${BB_ARG}-${REL_BOARD_NAME}.tar.bz2 -C ${DIR_RFS}

echo "### Complete BSP building & setup ! ###"


