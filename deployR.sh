#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`
BUILD_TARGET_DIR=`realpath ./R`
R_VERSION="4.0.0"
R_BUILD_DIRECTORY=`realpath ./R-${R_VERSION}`
R_MAJOR=`cut -d '.' -f 1 <<< $R_VERSION`
R_TGZ="R-${R_VERSION}.tar.gz"
R_SOURCES_URL="https://cran.rstudio.com/src/base/R-${R_MAJOR}/${R_TGZ}"
DOCKER=0
MEMORY_TRACKING=0


helpstring="
Usage: ./deploy-AcyleSeeker.sh [OPTION, ...]
    Detect the system's package management tools
    Install system dependencies to build R-$R_VERSION and AcyleSeeker tool's
    R dependencies
    Download R sources from $R_SOURCES_URL
    Build R in $R_BUILD_DIRECTORY and install the binares in $BUILD_TARGET_DIR
    Download AcyleSeeker from $ACYLE_SEEKER_REPO
    Install/build the dependencies of AcyleSeeker, at the versions defined by the tool.

Examples:
./deploy-AcyleSeeker.sh --install-apt --check-dpkg --r-bin-location /home/public/R
# this will force the use of apt for package install
# force the use of dpkg for package installation verification
# and force the R to be built in /home/public/R

./deploy-AcyleSeeker.sh --no-system-dependencies --no-build-R
# this will skip the system dependencies check/install and R build.

Package management flags
    --check-dpkg                Use dpkg to check if packages are installed
    --check-yum                 Use yum to check if packages are installed

Control flow flags
    --no-system-dependencies    Skip the system dependencies and install
    --no-build-R                Skip the build of R
    --no-install-acyle          Skip the download of AcyleSeeker tool
    --no-acyle-dependencies     Skip the build of AcyleSeeker packages

Build targets
    --r-bin-location            Defines the path to install R binaries
    --r-build-location          Defines the path where R sources are extracted and built

Clean
    --rm-r-tgz                  Remove the .tar.gz of the R sources
    --rm-r-sources              Remove the sources directory of R
    --clean-everything          Like --rm-r-tgz, --rm-r-sources
Divers
    --track-memory              Enable memory tracking during R build
    --docker                    Do everything without prompt nor sudo
                                don't install tcl/tk
    --help                      Show this message
    You can overwrite every package version by doing
    --R_{the-package-name}_VERSION 3.5.7
    For example:
    --R_PLOTLY_VERSION 3.5.7

@author: Lain Pavot
@date: 20/04/2020
"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
ORANGE='\033[38;5;214m'
END='\033[m'

function print_success() {
    printf "${GREEN}"
    echo "[Success] $1"
    printf "${END}"
}

function print_info() {
    printf "${YELLOW}"
    echo "[Info]    $1"
    printf "${END}"
}

function print_skip() {
    printf "${ORANGE}"
    echo "[Skip]    $1"
    printf "${END}"
}

function print_error() {
    printf "${RED}"
    echo "[Error]   $1"
    printf "${END}"
}


function is_root() {
    [ "$(id -u)" == "0" ] && return 0 || return 1;
}

function show_help() {
    echo "$helpstring"
    exit 0
}

function check_dependency(){
    [[ `grep "$1" <<< "$app_list"` == "" ]] && return 0 || return 1;
}


function load_with_dpkg() {
    print_info "Using dpkg-query -l to check weither packages are installed or not..."
    app_list=`dpkg-query -l`
}

function load_with_yum() {
    print_info "Using yum list to check weither packages are installed or not..."
    app_list=`yum list installed`
}

function system_detection() {
    if [ -f "/etc/debian_version" ];then
        print_info "Debian system detected."
        install_system_dependencies="install_debian"
    else
        print_info "RHEL derivated system detected."
        install_system_dependencies="install_centos_rhel"
    fi
    if [[ $CHECK_DPKG -eq 1 ]];then
        load_with_dpkg
        return
    elif [[ $CHECK_YUM -eq 1 ]];then
        load_with_yum
    elif [[ `command -v dpkg-query` != "" ]]; then
        load_with_dpkg
    elif [[ `command -v yum` != "" ]];then
        load_with_yum
    else
        echo "Could not find a way to check weither a package is installed or not."
        echo "Please install the packages yourself."
        echo "Then run this script giving the flag --no-system-dependencies"
        exit
    fi
}

function fail_install() {
    print_error "Dependencies install failed. Exiting."
    exit
}

function detect_missing_dependencies() {
    dependencies=$1
    missing_dependencies=()
    deps="$( IFS=$' '; echo "${dependencies[*]}" )"
    for dependency in $deps ;do
        if check_dependency $dependency;then
            echo "[Missing] $dependency"
            missing_dependencies="$missing_dependencies $dependency"
        else
            echo "[OK]      $dependency"
        fi
    done
}

function install_missing_dependencies() {
    install_command="$1"
    if [[ "$missing_dependencies" != "" ]];then
        print_info "We need to install these system dependencies to compile R and AcylSeeker's packages: $missing_dependencies"
        print_info "Install command for these packages: $install_command"
        if [[ $DOCKER -eq 1 ]];then
            # To prevent user interaction to select geographic area
            # during packages installation, we need to set these env vars
            export TZ="Europe/Paris"
            export DEBIAN_FRONTEND="noninteractive"
        else
            echo "Press enter to continue..."
            read
        fi
        if is_root || [[ $DOCKER -eq 1 ]]; then
            $install_command $missing_dependencies
            [[ $? -ne 0 ]] && fail_install
        else
            sudo $install_command $missing_dependencies
            [[ $? -ne 0 ]] && fail_install
        fi
    fi
}

function install_debian() {
    META_DEPENDENCIES="wget git make file"
    PACKAGES_DEPENDENCIES="libpng-dev libgit2-dev libssh-dev libnetcdf-dev libnetcdff-dev libxml2-dev"
    TCL_DEPENDENCIES="tcl-dev tk-dev tcl8.6 tk8.6 tcl8.6-dev tk8.6-dev tcl8.6-doc tk8.6-doc"
    if [[ $DOCKER -eq 1 ]];then
        WHY_FLAG="-y"
        PACKAGES_DEPENDENCIES="$PACKAGES_DEPENDENCIES language-pack-en"
        R_DEPENDENCIES="g++ gfortran libssl-dev libbz2-dev liblzma-dev libcurl4-openssl-dev libpcre3-dev libpcre2-dev"
    else
        WHY_FLAG=""
        R_DEPENDENCIES="g++ gfortran libssl-dev libbz2-dev liblzma-dev libcurl4-openssl-dev libpcre3-dev libpcre2-dev $TCL_DEPENDENCIES"
    fi
    if [[ $MEMORY_TRACKING -eq 1 ]];then
        R_DEPENDENCIES="$R_DEPENDENCIES openjdk-11-jdk"
    fi
    detect_missing_dependencies "$META_DEPENDENCIES $R_DEPENDENCIES $PACKAGES_DEPENDENCIES"
    install_missing_dependencies "apt-get install $WHY_FLAG"

    # this is necessary for some R packages that need en locals during their install.
    if [[ $DOCKER -eq 1 ]];then
        localedef -i en_US -f UTF-8 en_US.UTF-8
        locale-gen en_US
    fi
}

function install_centos_rhel() {
    META_DEPENDENCIES="wget git make file"
    POWER_TOOLS_DEPENDENCIES="libgit2-devel libaec hdf5-devel"
    PACKAGES_DEPENDENCIES="libpng-devel libgit2-devel libssh-devel netcdf-devel libxml2-devel"
    TCL_DEPENDENCIES="tcl-devel tk-devel tcl tk tcl-devel tk-devel"
    if [[ $DOCKER -eq 1 ]];then
        WHY_FLAG="-y"
        R_DEPENDENCIES="gcc-c++ gcc-gfortran openssl-devel bzip2-devel libcurl-devel pcre-devel"
    else
        WHY_FLAG=""
        R_DEPENDENCIES="gcc-c++ gcc-gfortran openssl-devel bzip2-devel libcurl-devel pcre-devel $TCL_DEPENDENCIES"
    fi
    if [[ `rpm -E %{rhel}` -eq 8 ]];then
        POWER_TOOLS_DEPENDENCIES="$POWER_TOOLS_DEPENDENCIES xz-lzma-compat"
    else
        $PACKAGES_DEPENCIES="$PACKAGES_DEPENCIES lzma-devel hdf5-devel"
    fi

    detect_missing_dependencies "$POWER_TOOLS_DEPENDENCIES"
    install_missing_dependencies "dnf --enablerepo=PowerTools install $WHY_FLAG"

    detect_missing_dependencies "$META_DEPENDENCIES $R_DEPENDENCIES $PACKAGES_DEPENDENCIES"
    install_missing_dependencies "yum install $WHY_FLAG"

    ## FIXME : find equivalent for CentOS:
    # if [[ $DOCKER -eq 1 ]];then
    #     apt-get install -y language-pack-en
    #     localedef -i en_US -f UTF-8 en_US.UTF-8
    #     locale-gen en_US
    # fi
}

function download_and_extract() {
    if [ ! -f "./$R_TGZ" ];then
        print_info "Downloading sources..."
        wget "$R_SOURCES_URL"
        if [[ $? -ne 0 ]];then
            print_error "Could not download R sources. Check your connexcion and the download url."
            exit -1
        fi
        downloaded=1
    else
        print_info "Sources already downloaded"
        downloaded=0
    fi
    if [ ! -d "R-${R_VERSION}" ];then
        print_info "Extracting souces..."
        tar -xf "./$R_TGZ"
        if [[ $? -ne 0 ]];then
            print_error "Could not extract R sources. Check the integrity of the tar.gz."
            exit -2
        fi
    else
        echo "Sources already extracted."
    fi
    if [[ `realpath "./R-${R_VERSION}"` != `realpath "$R_BUILD_DIRECTORY"` ]];then
        [ ! -d "$R_BUILD_DIRECTORY" ] && mkdir "$R_BUILD_DIRECTORY"
        if [[ $downloaded -eq 1 ]];then
            echo "Renaming them..."
            mv "./R-${R_VERSION}" "$R_BUILD_DIRECTORY"
        else
            echo "Copying them..."
            cp -r "./R-${R_VERSION}"/* "$R_BUILD_DIRECTORY"
        fi
    fi
}

function build_install_R() {
    echo "Processing R install for version $R_VERSION"
    download_and_extract
    cd "$R_BUILD_DIRECTORY"
    if [ ! -d "$BUILD_TARGET_DIR" ];then
        mkdir "$BUILD_TARGET_DIR"
    fi
    config_opt=""
    if [[ $MEMORY_TRACKING -eq 1 ]];then
        config_opt="$config_opt --enable-memory-profiling"
    fi
    ./configure --prefix="${BUILD_TARGET_DIR}" --with-readline="no" --with-x="no" $config_opt
    if [ "$?" != "0" ];then
        print_error "Configuration failed."
        print_info "Please fix it first. R needs you to install ${ALL_DEPENDENCIES}"
        print_info "sudo apt-get install ${ALL_DEPENDENCIES}"
        rmdir "$BUILD_TARGET_DIR"
        clean_tgz
        exit -3
    fi
    export CC="gcc -fPIC"
    make --quiet
    if [ "$?" != "0" ];then
        print_error "Compilation failed."
        print_info "Please fix it first. Cannot help you for this step."
        rmdir "$BUILD_TARGET_DIR"
        clean_tgz
        exit -4
    fi
    make install
    cd $ROOT_DIR
}


function clean_all() {
    clean_tgz
    clean_sources
}

function clean_tgz() {
    if [[ $RM_R_TGZ -eq 1 ]] && [ -f "./$R_TGZ" ];then
        print_success "Remove the .tar.gz containing R sources"
        rm -f "./$R_TGZ"
    fi
}

function clean_sources() {
    if [[ $RM_R_SOURCES -eq 1 ]] && [ -d "$R_BUILD_DIRECTORY" ];then
        print_success "Remove the directory containing R sources."
        rm -rf "$R_BUILD_DIRECTORY"
    fi
}

function run() {
    system_detection
    $install_system_dependencies
    build_install_R
    clean_all
}

UNKNOWN=()
while [[ $# -gt 0 ]];do
    parameter="$1"

    case $parameter in
        --check-dpkg)
            CHECK_DPKG=1
            shift
        ;;
        --check-yum)
            CHECK_YUM=1
            shift
        ;;
        --no-system-dependencies)
            NO_SYSTEM_DEPENDENCIES=1
            shift
        ;;
        --no-build-R)
            NO_BUILD_R=1
            shift
        ;;
        --no-install-acyle)
            NO_INSTALL_ACYLE=1
            shift
        ;;
        --no-acyle-dependencies)
            NO_ACYLE_DEPENDENCIES=1
            shift
        ;;
        --r-bin-location)
            BUILD_TARGET_DIR=`realpath $2`
            shift
            shift
        ;;
        --r-build-location)
            R_BUILD_DIRECTORY=`realpath $2`
            shift
            shift
        ;;
        --rm-r-tgz)
            RM_R_TGZ=1
            shift
        ;;
        --rm-r-sources)
            RM_R_SOURCES=1
            shift
        ;;
        --clean-everything)
            RM_R_SOURCES=1
            RM_R_TGZ=1
            shift
        ;;
        --docker)
            DOCKER=1
            shift
        ;;
        --track-memory)
            MEMORY_TRACKING=1
            shift
        ;;
        --help)
            show_help
            shift
        ;;
        *)
            if
                [[ "$1" =~ ^--R_([A-Z]+_)?VERSION$ ]] &&
                [[ `echo "\$$(cut -d '-' -f 3 <<< $1)"` != "" ]];
            then
                eval "$(cut -d '-' -f 3 <<< $1)=$2"
                shift
                R_BUILD_DIRECTORY=`realpath ./R-${R_VERSION}`
                R_MAJOR=`cut -d '.' -f 1 <<< $R_VERSION`
                R_TGZ="R-${R_VERSION}.tar.gz"
                R_SOURCES_URL="https://cran.rstudio.com/src/base/R-${R_MAJOR}/${R_TGZ}"
            else
                UNKNOWN+=("$1")
            fi
            shift
        ;;
    esac
done
if [[ ${#UNKNOWN[@]} -ne 0 ]];then
    print_error "Unknown parameters: "
    for unk in "${UNKNOWN[@]}";do echo "$unk ";done
    show_help
fi
run
echo "Finished."
exit 0
