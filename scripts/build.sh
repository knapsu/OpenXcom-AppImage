#!/bin/bash
set -e

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "${SCRIPT}")
WORKDIR=${PWD}

# Load helper functions
source "${SCRIPTDIR}/functions.sh"

# Define build variables
APP="OpenXcom"
LOWERAPP="openxcom"
DATE=$(date -u +'%Y%m%d')

case "$(uname -i)" in
  x86_64|amd64)
    SYSTEM_ARCH="x86_64"
    SYSTEM_PLATFORM="x86-64";;
  i?86)
    SYSTEM_ARCH="i686"
    SYSTEM_PLATFORM="x86";;
  *)
    echo "Unsupported system architecture"
    exit 1;;
esac
echo "System architecture: ${SYSTEM_PLATFORM}"

case "${ARCH:-$(uname -i)}" in
  x86_64|amd64)
    TARGET_ARCH="x86_64"
    PLATFORM="x86-64";;
  i?86)
    TARGET_ARCH="i686"
    PLATFORM="x86";;
  *)
    echo "Unsupported target architecture"
    exit 1;;
esac
echo "Target architecture: ${PLATFORM}"

# Build OpenXcom binaries
if [ -d openxcom ]; then
  cd openxcom
  git clean -xdf
  git checkout master
  git pull
else
  git clone https://github.com/SupSuper/OpenXcom.git openxcom
  cd openxcom
fi


# If building from tag use a specific version of OpenXcom sources
if [ -n "${TRAVIS_TAG}" ]; then
  git checkout ${TRAVIS_TAG}
fi
COMMIT_HASH=$(git log -n 1 --pretty=format:'%h')
COMMIT_TIMESTAMP=$(git log -n 1 --pretty=format:'%cd' --date=format:'%Y-%m-%d %H:%M')

# Check if source code was modified since last scheduled build.
if [[ "${TRAVIS_EVENT_TYPE}" == "cron" ]]; then
  echo "Scheduled build"
  echo "Checking if source code was modified since last build"

  if [ -f "${WORKDIR}/cache/commit-hash" ]; then
    PREVIOUS_HASH=$(cat "${WORKDIR}/cache/commit-hash")
  fi
  echo "Previous source hash: ${PREVIOUS_HASH:-unknown}"

  CURRENT_HASH=$(git log -n 1 --pretty=format:'%H')
  echo "Current source hash: ${CURRENT_HASH}"

  if [ "${PREVIOUS_HASH}" == "${CURRENT_HASH}" ]; then
    echo "Source code not modified"
    exit
  fi
else
  echo "Standard build"
fi

if [ -n "${TRAVIS_TAG}" ]; then
  # When building from tag use it as package version number
  VERSION="${TRAVIS_TAG}"
  INTERNAL_VERSION_SUFFIX=""
else
  # For standard builds use current date and commit hash as package version number
  VERSION="${DATE}_${COMMIT_HASH}"
  INTERNAL_VERSION_SUFFIX=".${COMMIT_HASH} (${COMMIT_TIMESTAMP})"
fi

cmake \
  -DBUILD_PACKAGE=OFF \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="/usr" \
  -DOPENXCOM_VERSION_STRING="${INTERNAL_VERSION_SUFFIX}" \
  .
make
cd ..

# Download translations
tx pull -a

# Prepare working directory
rm -rf "appimage"
mkdir -p "appimage"
cd "appimage"
download_appimagetool

# Initialize AppDir
mkdir "AppDir"
mkdir -p "AppDir/usr/bin"
mkdir -p "AppDir/usr/lib"
mkdir -p "AppDir/usr/share/openxcom"
APPDIR="${PWD}/AppDir"

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
cp -r "${WORKDIR}/translations/openxcom.openxcom/"* "${APPDIR}/usr/share/openxcom/common/Language/"
cp -r "${WORKDIR}/translations/openxcom.x-com-1/"* "${APPDIR}/usr/share/openxcom/standard/xcom1/Language/"
cp -r "${WORKDIR}/translations/openxcom.x-com-2/"* "${APPDIR}/usr/share/openxcom/standard/xcom2/Language/"

# Setup desktop integration (launcher, icon, menu entry)
cp "${WORKDIR}/openxcom/res/linux/openxcom.desktop" "${APPDIR}/${LOWERAPP}.desktop"
cp "${WORKDIR}/openxcom/res/linux/icons/openxcom.svg" "${APPDIR}/${LOWERAPP}.svg"
cd "${APPDIR}"
get_apprun
get_desktopintegration ${LOWERAPP}
cd "${OLDPWD}"

# Create AppImage bundle
if [[ "${VERSION}" =~ ^v[0-9]+\.[0-9]+ ]]; then
  VERSION=${VERSION:1}
fi
APPIMAGE_FILE_NAME="OpenXcom_${VERSION}_${PLATFORM}.AppImage"
cd "${WORKDIR}/appimage"
./appimagetool -n "${APPDIR}"
mv *.AppImage "${WORKDIR}/${APPIMAGE_FILE_NAME}"

cd "${WORKDIR}"
sha1sum *.AppImage

# Remember last source code version used by scheduled build
if [[ "${TRAVIS_EVENT_TYPE}" == "cron" ]]; then
  mkdir -p "${WORKDIR}/cache"
  echo -n "${CURRENT_HASH}" > "${WORKDIR}/cache/commit-hash"
fi
