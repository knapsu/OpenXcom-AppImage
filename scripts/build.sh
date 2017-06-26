#!/bin/bash
set -e

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
WORKDIR=${PWD}

APP=OpenXcom
LOWERAPP=${APP,,}

# Load helper functions
. "$SCRIPTDIR/functions.sh"

# Define version number and output file name
case "${ARCH:-$(uname -i)}" in
  x86_64|amd64)
    TARGET_ARCH="x86-64";;
  i?86)
    TARGET_ARCH="x86";;
  *)
    echo "Unsupported target architecture"
    exit 1;;
esac
echo "Target architecture: ${TARGET_ARCH}"

COMMIT_HASH=$(git log -n 1 --pretty=format:'%h')
COMMIT_TIMESTAMP=$(git log -n 1 --pretty=format:'%cd' --date=format:'%Y-%m-%d %H:%M')
OPENXCOM_VERSION_STRING=".${COMMIT_HASH} (${COMMIT_TIMESTAMP})"
APPIMAGE_NAME="OpenXcom_$(date -u +'%Y%m%d%H%M')_${TARGET_ARCH}.AppImage"

# Build binaries
rm -rf "openxcom"
git clone https://github.com/SupSuper/OpenXcom.git openxcom
cd "openxcom"
cmake \
  -DBUILD_PACKAGE=OFF \
 -DCMAKE_BUILD_TYPE="Release" \
 -DOPENXCOM_VERSION_STRING="${OPENXCOM_VERSION_STRING}" \
 .
make
cd ..

# Prepare working directory
rm -rf "appimage"
mkdir -p "appimage"
cd "appimage"

# Initialize AppDir
mkdir "${APP}.AppDir"
mkdir -p "${APP}.AppDir/usr/bin"
mkdir -p "${APP}.AppDir/usr/lib"
mkdir -p "${APP}.AppDir/usr/share/openxcom"
APPDIR="${PWD}/${APP}.AppDir"

# Copy binaries
cp "${WORKDIR}/openxcom/bin/openxcom" "${APPDIR}/usr/bin/"

# Copy libraries
cd "${APPDIR}"
copy_deps
delete_blacklisted
cd "${OLDPWD}"
# Fix: Remove NVIDIA GLX libraries
rm -rf "${APPDIR}/usr/lib/nvidia-"*
# Fix: Do not store libraries in subdirectories (potential LD_LIBRARY_PATH problem)
find "${APPDIR}/usr/lib/" -type f -print0 | xargs -0 mv -t "${APPDIR}/usr/lib/"
find "${APPDIR}/usr/lib/" -mindepth 1 -type d -print0 | xargs -0 rm -rf


# Copy assets
cp -r "${WORKDIR}/openxcom/bin/"* "${APPDIR}/usr/share/openxcom/"
rm -f "${APPDIR}/usr/share/openxcom/openxcom"

# Copy translations
#cp ${WORKDIR}/translations/openxcom.openxcom/* ${APPDIR}/usr/share/openxcom/common/Language/
#cp ${WORKDIR}/translations/openxcom.x-com-1/* ${APPDIR}/usr/share/openxcom/standard/xcom1/Language/
#cp ${WORKDIR}/translations/openxcom.x-com-2/* ${APPDIR}/usr/share/openxcom/standard/xcom2/Language/

# Setup desktop integration (launcher, icon, menu entry)
cp "${WORKDIR}/openxcom/res/linux/openxcom.desktop" "${APPDIR}/${LOWERAPP}.desktop"
cp "${WORKDIR}/openxcom/res/linux/icons/openxcom.svg" "${APPDIR}/${LOWERAPP}.svg"

cd "${APPDIR}"
get_apprun
get_desktopintegration ${LOWERAPP}
cd "${OLDPWD}"

# Create AppImage bundle
generate_openxcom_appimage "${APPDIR}" "${APPIMAGE_NAME}"
mv *.AppImage "${WORKDIR}"
