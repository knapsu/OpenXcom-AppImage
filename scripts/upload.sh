#!/bin/bash
set -e

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "${SCRIPT}")
WORKDIR=${PWD}

if [ $# -eq 0 ]; then
  echo "Missing script arguments" >&2
  exit 1
fi
OPTIONS=$(getopt -o '' -l scp,sftp,transfer -- "$@")
if [ $? -ne 0 ] ; then
  echo "Invalid script arguments" >&2
  exit 2
fi
eval set -- "$OPTIONS"

while true; do
  case "$1" in
    (--scp)
      UPLOAD_SCP="true"
      shift;;
    (--sftp)
      UPLOAD_SFTP="true"
      shift;;
    (--transfer)
      UPLOAD_TRANSFER="true"
      shift;;
    (--)
      shift; break;;
    (*)
      break;;
  esac
done

if [ ! -f *.AppImage ]; then
  echo "Nothing to upload"
  exit
fi

if [[ "${UPLOAD_SCP}" == "true" ]]; then
  echo "Uploading to SCP server"
  SCP_USER=${SCP_USER:?Missing SCP_USER variable}
  SCP_SERVER=${SCP_SERVER:?Missing SCP_SERVER variable}
  # Decrypt SSH key on Travis CI
  if [[ "${TRAVIS}" == "true" ]]; then
    openssl aes-256-cbc -K $encrypted_2df94c5b0b2b_key -iv $encrypted_2df94c5b0b2b_iv -in keys/id_rsa.enc -out keys/id_rsa -d
    chmod go-rwx keys/id_rsa
  fi
  scp -i keys/id_rsa *.AppImage ${SCP_USER}@${SCP_SERVER}:${SCP_PATH}
fi

if [[ "${UPLOAD_SFTP}" == "true" ]]; then
  echo "Uploading to SFTP server"
  UPLOAD_USER=${UPLOAD_USER:?Missing UPLOAD_USER variable}
  UPLOAD_SERVER=${UPLOAD_SERVER:?Missing UPLOAD_SERVER variable}
  # Decrypt SSH key on Travis CI
  if [[ "${TRAVIS}" == "true" ]]; then
    openssl aes-256-cbc -K $encrypted_2df94c5b0b2b_key -iv $encrypted_2df94c5b0b2b_iv -in keys/id_rsa.enc -out keys/id_rsa -d
    chmod go-rwx keys/id_rsa
  fi
  echo "put *.AppImage" | sftp -i keys/id_rsa ${UPLOAD_USER}@${UPLOAD_SERVER}:${UPLOAD_PATH}
fi

if [[ "${UPLOAD_TRANSFER}" == "true" ]]; then
  echo "Uploading to https://transfer.sh/"
  curl --upload-file *.AppImage https://transfer.sh/
  echo
fi
