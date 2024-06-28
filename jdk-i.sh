#!/bin/bash

function selectMenu {
    tput reset
    echo "Multiple versions found. Select one to install:"
    echo ""
    for ((i=0; i<${#options[@]}; i++)); do
        if [ "${i}" -eq "${selected}" ]; then
            echo -e "\e[1m[*] ${options[${i}]}\e[0m";
        else
            echo "[ ] ${options[${i}]}";
        fi
    done
}

function installPackage() {
    # Installation
    if [ -z "${1}" ]; then
        apt install /tmp/jdk-install.deb -y >/dev/null 2>&1;
    else
        echo "Searching JDK ${1}...";
        echo "Installing from path (${1})";
        MAJOR_VERSION=$(apt install "${1}" -y 2>&1 | grep jdk- | sed "1q;d" | awk '{print $1}' | cut -d '-' -f2);
    fi

    # Setting up JDK in alternatives
    echo "Setting up JDK..."
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-"${MAJOR_VERSION}"/bin/java 1 >/dev/null 2>&1
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-"${MAJOR_VERSION}"/bin/javac 1 >/dev/null 2>&1
    update-alternatives --set java /usr/lib/jvm/jdk-"${MAJOR_VERSION}"/bin/java >/dev/null 2>&1
    update-alternatives --set javac /usr/lib/jvm/jdk-"${MAJOR_VERSION}"/bin/javac >/dev/null 2>&1
}

function searchWebsite() {
    # Searching JDK version on server
    echo "Searching JDK ${VERSION}..."

    wget --spider --quiet https://download.oracle.com/java/"${MAJOR_VERSION}"/latest/jdk-"${MAJOR_VERSION}"_linux-x64_bin.deb
    LATEST="${?}"

    wget --spider --quiet https://download.oracle.com/java/"${MAJOR_VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb
    ARCHIVE="${?}"

    if [ "${LATEST}" == "0" ] && [ "${ARCHIVE}" == "0" ]; then

        options=("JDK ${VERSION} (Latest, as LTS)" "JDK ${VERSION} (Oldest, first version)")
        selected=0

        selectMenu
        while true; do
            read -rsn1 key
            case "${key}" in
                'A')
                    selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} ))
                    selectMenu
                    ;;
                'B')
                    selected=$(( (selected + 1) % ${#options[@]} ))
                    selectMenu
                    ;;
                '')
                    break
                    ;;
            esac
        done

        if [ "${options[selected]}" == "JDK ${VERSION} (Latest, LTS)" ]; then
            echo "";
            echo "Installing JDK...";
            # Downloading from latest (LTS)
            wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/latest/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
        elif [ "${options[selected]}" == "JDK ${VERSION} (Oldest, first version)" ]; then
            echo "";
            echo "Installing JDK...";
            # Downloading from archive (as first version of JDK, not latest)
            wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
        fi


    elif [ "${LATEST}" != "0" ] && [ "${ARCHIVE}" == "0" ]; then
        echo "";
        echo "WARN: it will not be the latest version, you are only installing version ${VERSION} from archive";
        echo "";
        echo "Installing JDK ${VERSION}...";
        # Downloading from archive (as first version of JDK, not latest)
        wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${MAJOR_VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
    else
        echo "ERROR: Couldn't find the specified JDK version on Oracle's website";
        exit 1;
    fi
}

function checkInstall() {

    if [ -f /tmp/jdk-install.deb ]; then
        rm /tmp/jdk-install.deb >/dev/null 2>&1;
    fi

    if java -version >/dev/null 2>&1; then
        echo "";
        echo "Setup was successful! Here is your 'java -version'";
        echo "";
        java -version
        echo "";
        exit 0;
    else
        echo "ERROR: Oh, something went wrong...";
        echo "ERROR: Installation was failed. You can try again.";
        exit 1;
fi
}

tput reset
echo "Java Development Kit (JDK) installer for Linux"
echo ""

if [ "${EUID}" -ne 0 ]; then
    echo "ERROR: You must to run this script as root";
    exit 1;
fi

# OS check
# shellcheck disable=SC1091
source /etc/os-release
OS="${ID}"
if [ "${OS}" != "ubuntu" ] && [ "${OS}" != "debian" ] && [ "${OS}" != "raspbian" ]; then
    echo "ERROR: This script couldn't run on your machine";
    echo "ERROR: At this moment we support only these OS: Debian, Ubuntu, Raspbian";
    exit 1;
fi

# Check first flag
if [ -n "${1}" ]; then
    if [ -f "${1}" ] && [[ ${1} == *.deb ]]; then
        installPackage "${1}";
        checkInstall;
    else
        VERSION="${1}";
        MAJOR_VERSION=$(echo "${VERSION}" | cut -d '.' -f1);
        searchWebsite;
        installPackage;
        checkInstall;
    fi
else
    echo "ERROR: Specify the required JDK version or path to .deb package in first flag";
    exit 1;
fi
