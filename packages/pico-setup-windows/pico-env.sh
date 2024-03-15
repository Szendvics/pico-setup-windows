#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is being executed, not sourced. Please source it: source $0"
    exit 1
fi

# Path to the version.ini file this contains the installation of the utils
version_ini_path="version.ini"

errors=0

add_to_path() {
    if [ -d "$1" ]; then
      export PATH="$1:$PATH"
    fi
}

convert_to_posix() {
	  cygpath -u "$1"
}

verify_exe() {
    echo "Checking $1..."
    if ! command -v $2 &> /dev/null; then
      echo "ERROR: $1 is required but was not found."
      ((errors++))
    fi
}

# Parse version.ini file to export each line as a variable
while IFS='=' read -r key value; do
    # Remove potential Windows carriage returns
    key=$(echo $key | tr -d '\r')
    value=$(echo $value | tr -d '\r')

    # Skip lines that start with a square bracket (section names)
    if [[ $key =~ ^\[.*\]$ ]]; then
      continue
    fi

    # Check if the key ends with _PATH
    if [[ $key =~ _PATH$ ]]; then
      # Convert the value to a POSIX path using cygpath
      value=$(cygpath "$value")
    fi

    # Dynamically create and export variable
    declare "$key=$value"
    export "$key"
done < "$version_ini_path"


# Check if PICO_SDK_VERSION is set
if [ -z "$PICO_SDK_VERSION" ]; then
    echo "ERROR: Unable to determine Pico SDK version."
    ((errors++))
fi

# Setting other paths based on PICO_INSTALL_PATH
PICO_SDK_PATH="$PICO_INSTALL_PATH/pico-sdk"
export PICO_SDK_PATH

# Example of adding directories to PATH
add_to_path "$PICO_INSTALL_PATH/cmake/bin"
add_to_path "$PICO_INSTALL_PATH/gcc-arm-none-eabi/bin"
add_to_path "$PICO_INSTALL_PATH/ninja"
add_to_path "$PICO_INSTALL_PATH/python"
add_to_path "$PICO_INSTALL_PATH/git/cmd"
add_to_path "$PICO_INSTALL_PATH/pico-sdk-tools"
add_to_path "$PICO_INSTALL_PATH/picotool"

# Verifying executables
verify_exe "GNU Arm Embedded Toolchain" "arm-none-eabi-gcc"
verify_exe "CMake" "cmake"
verify_exe "Ninja" "ninja"
verify_exe "Python 3" "python"
verify_exe "Git" "git"

# Additional paths and checks based on existence
if [ -d "$PICO_INSTALL_PATH/openocd" ]; then
    echo "OPENOCD_SCRIPTS=$PICO_INSTALL_PATH/openocd/scripts"
    export OPENOCD_SCRIPTS="$PICO_INSTALL_PATH/openocd/scripts"
    add_to_path "$PICO_INSTALL_PATH/openocd"
fi

# Setting the CMake generator explicitly
export CMAKE_GENERATOR=Ninja
