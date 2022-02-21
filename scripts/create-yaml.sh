#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)

NAME="$1"
CHART_DIR="$2"
DEST_DIR="$3"
VALUES_FILE="$4"

mkdir -p "${DEST_DIR}"

## Add logic here to put the yaml resource content in DEST_DIR

cp -R "${CHART_DIR}"/* "${DEST_DIR}"

if [[ -n "${VALUES_FILE}" ]] && [[ -n "${VALUES_CONTENT}" ]]; then
  echo "${VALUES_CONTENT}" > "${DEST_DIR}/${VALUES_FILE}"
fi

find "${DEST_DIR}" -name "*"