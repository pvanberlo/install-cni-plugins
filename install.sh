#!/bin/sh

set -e

DEST_DIR=${DEST_DIR:-"/opt/cni/bin"}
PRE_EXTRACTED_DIR=${PRE_EXTRACTED_DIR:-"/opt/cni-plugins"}

usage() {
    echo "Usage: $0 [plugin1] [plugin2] ..."
    echo "       $0 --help"
    echo ""
    echo "Installs specified CNI plugins from ${PRE_EXTRACTED_DIR} to ${DEST_DIR}."
    echo "If no plugins are specified, all available plugins will be installed."
    echo ""
    if [ -n "$1" ]; then
        echo "Available plugins: $1"
    fi
    echo "DEST_DIR: $DEST_DIR (can be overridden by environment variable)"
    exit 1
}

if [ ! -d "${PRE_EXTRACTED_DIR}" ] || [ -z "$(ls -A "${PRE_EXTRACTED_DIR}")" ]; then
    echo "Error: The pre-extracted plugins directory is missing or empty: ${PRE_EXTRACTED_DIR}" >&2
    echo "This script is designed to run in the container built by the accompanying Dockerfile." >&2
    echo "If running standalone, ensure plugins are pre-extracted into that directory." >&2
    exit 1
fi

mkdir -p "${DEST_DIR}"

ALL_PLUGINS=$(find "${PRE_EXTRACTED_DIR}" -maxdepth 1 -type f \
    -perm +a=x \
    -print0 | \
    xargs -0 -I {} basename "{}" | \
    tr '\n' ' ' | \
    sed 's/ *$//'
)

for arg in "$@"; do
    if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
        usage "$ALL_PLUGINS"
    fi
done

PLUGINS_TO_INSTALL=""
if [ "$#" -gt 0 ]; then
    for arg in "$@"; do
        found=0
        for p in $ALL_PLUGINS; do
            if [ "$arg" = "$p" ]; then
                PLUGINS_TO_INSTALL="$PLUGINS_TO_INSTALL $arg"
                found=1
                break
            fi
        done
        if [ "$found" -eq 0 ]; then
            echo "Error: Unknown plugin specified: $arg" >&2
            usage "$ALL_PLUGINS"
        fi
    done
else
    PLUGINS_TO_INSTALL=$ALL_PLUGINS
fi

if [ -n "$PLUGINS_TO_INSTALL" ]; then
    echo "Installing plugins to ${DEST_DIR}:${PLUGINS_TO_INSTALL}"
    for plugin in $PLUGINS_TO_INSTALL; do
        install -m 0755 "${PRE_EXTRACTED_DIR}/${plugin}" "${DEST_DIR}/"
    done
    echo "CNI plugins installed successfully."
else
    echo "No plugins selected to install."
fi
