#!/bin/bash
set -euo pipefail

#  make-static-lib.sh
#  xcode-github-lib
#
#  Created by Edward Smith on 10/7/18.
#  Copyright © 2018 Branch. All rights reserved.

#
# Headers:
#
/bin/mkdir -p "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Versions/A/Headers"
/bin/cp -a \
    "${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}/" \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Versions/A/Headers"

#
# Module map:
#
/bin/mkdir -p "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Versions/A/Modules"
/bin/cp -a \
    "${SOURCE_ROOT}"/"${PRODUCT_NAME}"/module.modulemap \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Versions/A/Modules"

#
# Static library:
#
/bin/cp -a \
    "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_NAME}" \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Versions/A/${PRODUCT_NAME}"

# Link 'Current' version to 'A':
/bin/ln -sfh \
    A \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Versions/Current"

#
# Link to current:
#
/bin/ln -sfh \
    Versions/Current/Headers \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Headers"
/bin/ln -sfh \
    Versions/Current/Modules \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Modules"
/bin/ln -sfh \
    "Versions/Current/${PRODUCT_NAME}" \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/${PRODUCT_NAME}"

/usr/bin/ditto \
    "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework" \
    "${SOURCE_ROOT}/Products/${PRODUCT_NAME}.framework"

echo "Result:"
echo "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework"
