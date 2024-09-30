#! /bin/bash

set -eou pipefail


config_env_pairs=(
  "gcc-9.5.0 serial-minsizerel"
  "gcc-9.5.0 serial-relwithdebinfo"
  "gcc-9.5.0 serial-release"
  "gcc-9.5.0 serial-release-native"

  "gcc-10.4.0 serial-minsizerel"
  "gcc-10.4.0 serial-relwithdebinfo"
  "gcc-10.4.0 serial-release"
  "gcc-10.4.0 serial-release-native"

  "gcc-11.3.0 serial-minsizerel"
  "gcc-11.3.0 serial-relwithdebinfo"
  "gcc-11.3.0 serial-release"
  "gcc-11.3.0 serial-release-native"

  "gcc-12.3.0 serial-minsizerel"
  "gcc-12.3.0 serial-relwithdebinfo"
  "gcc-12.3.0 serial-release"
  "gcc-12.3.0 serial-release-native"

  "gcc-13.1.0 serial-minsizerel"
  "gcc-13.1.0 serial-relwithdebinfo"
  "gcc-13.1.0 serial-release"
  "gcc-13.1.0 serial-release-native"

  "llvm-14.0.6 serial-minsizerel"
  "llvm-14.0.6 serial-relwithdebinfo"
  "llvm-14.0.6 serial-release"
  "llvm-14.0.6 serial-release-native"

  "llvm-15.0.7 serial-minsizerel"
  "llvm-15.0.7 serial-relwithdebinfo"
  "llvm-15.0.7 serial-release"
  "llvm-15.0.7 serial-release-native"

  "llvm-16.0.2 serial-minsizerel"
  "llvm-16.0.2 serial-relwithdebinfo"
  "llvm-16.0.2 serial-release"
  "llvm-16.0.2 serial-release-native"
)

for cfg_env in "${config_env_pairs[@]}"; do

  cfg=$(echo $cfg_env | cut -f1 -d' ')
  env=$(echo $cfg_env | cut -f2- -d' ')

  echo $cfg $env

  ./run_config.sh ubuntu-spack "$cfg" "$env"
done

