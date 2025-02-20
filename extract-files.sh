#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=tulip
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

LINEAGE_ROOT="${MY_DIR}/../../.."

HELPER="${LINEAGE_ROOT}/vendor/lineage/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true
SECTION=
KANG=

while [ "$1" != "" ]; do
    case "$1" in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -k | --kang)            KANG="--kang"
                                ;;
        -s | --section )        shift
                                SECTION="$1"
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC="$1"
                                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC=adb
fi

# Add uhid group for fingerprint service
FP_SERVICE_RC="$BLOB_ROOT"/vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc
sed -i "s/input/uhid input/" "$FP_SERVICE_RC"

# BLOB HAX
function blob_fixup() {
    case "${1}" in
    vendor/lib64/libgf_ca.so)
        sed -i "s|/system/etc/firmware|/vendor/firmware\x0\x0\x0\x0|g" "${2}"
        ;;
    vendor/bin/mlipayd@1.1)
        patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${2}"
        ;;
    vendor/lib64/libmlipay.so)
        patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${2}"
        ;;
    vendor/lib64/libmlipay@1.1.so)
        patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${2}"
        ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${LINEAGE_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" ${KANG} --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
