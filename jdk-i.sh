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
    echo ""
}

function uninstallJava() {
    # Uninstall JDK that installed on machine
    echo "Uninstall JDK..."

    VERSION_JDK=$(java -version 2>&1 | grep 'version' | cut -d '"' -f2 | cut -d '.' -f1)

    apt purge jdk-"${VERSION_JDK}" -y >/dev/null 2>&1
    apt autoremove -y >/dev/null 2>&1

    update-alternatives --remove java /usr/lib/jvm/jdk-"${VERSION_JDK}"/bin/java >/dev/null 2>&1
    update-alternatives --remove javac /usr/lib/jvm/jdk-"${VERSION_JDK}"/bin/javac >/dev/null 2>&1
}

function installPackage() {
    # Deleting another version, if exist
    if java -version >/dev/null 2>&1; then
        echo "Found another version of JDK. Deleting it...";
        uninstallJava >/dev/null 2>&1;
    fi

    # Check installation file location and installing
    if [ -z "${1}" ]; then
        echo "Installing JDK...";
        apt install /tmp/jdk-install.deb -y >/dev/null 2>&1;
    else
        echo "Installing from path (${1})";
        VERSION_MAJOR=$(apt install "${1}" -y 2>&1 | grep jdk- | sed "1q;d" | awk '{print $1}' | cut -d '-' -f2);
    fi

    # Configuring JDK in alternatives
    echo "Сonfiguring JDK..."
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-"${VERSION_MAJOR}"/bin/java 1 >/dev/null 2>&1
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-"${VERSION_MAJOR}"/bin/javac 1 >/dev/null 2>&1
    update-alternatives --set java /usr/lib/jvm/jdk-"${VERSION_MAJOR}"/bin/java >/dev/null 2>&1
    update-alternatives --set javac /usr/lib/jvm/jdk-"${VERSION_MAJOR}"/bin/javac >/dev/null 2>&1
}

function searchWebsite() {
    # Searching JDK version on server
    echo "Searching JDK ${VERSION}..."

    wget --spider --quiet https://download.oracle.com/java/"${VERSION_MAJOR}"/latest/jdk-"${VERSION_MAJOR}"_linux-x64_bin.deb
    LATEST="${?}"

    wget --spider --quiet https://download.oracle.com/java/"${VERSION_MAJOR}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb
    ARCHIVE="${?}"

    if [ "${LATEST}" == "0" ] && [ "${ARCHIVE}" == "0" ]; then
        if [ "${VERSION_FLAG}" == "-l" ] || [ "${VERSION_FLAG}" == "--latest" ]; then
            echo "Downloading latest version...";
            wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/latest/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
        elif [ "${VERSION_FLAG}" == "-o" ] || [ "${VERSION_FLAG}" == "--oldest" ]; then
            echo "Downloading oldest version...";
            wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION_MAJOR}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
        else
            options=("JDK ${VERSION} (Latest)" "JDK ${VERSION} (Oldest, first version)")
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

            if [ "${options[selected]}" == "JDK ${VERSION} (Latest)" ]; then
                echo "Downloading latest JDK ${VERSION} from Oracle's website...";
                # Downloading from latest
                wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/latest/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
            elif [ "${options[selected]}" == "JDK ${VERSION} (Oldest, first version)" ]; then
                echo "";
                echo "Downloading oldest JDK ${VERSION} from Oracle's website...";
                # Downloading from archive (as first version of JDK, not latest)
                wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
            fi
        fi

    elif [ "${LATEST}" != "0" ] && [ "${ARCHIVE}" == "0" ]; then
        echo "";
        echo "WARN: it will not be the latest version, you are only installing version ${VERSION} from Oralce's archive";
        echo "";
        echo "Downloading JDK ${VERSION} from Oracle's website...";
        # Downloading from archive (as first version of JDK, not latest)
        wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION_MAJOR}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1;
    else
        echo "ERROR: Couldn't find the specified JDK version";
        exit 1;
    fi
}

function checkInstall() {
    # Deleting installation file, if exist
    if [ -f /tmp/jdk-install.deb ]; then
        rm /tmp/jdk-install.deb >/dev/null 2>&1;
    fi

    # Check installation and finish
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

# Start of script
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

# Check flags
if [ -n "${1}" ]; then
    if [ -f "${1}" ] && [[ ${1} == *.deb ]]; then
        installPackage "${1}";
        checkInstall;
    elif [ "${1}" == "delete" ]; then
        uninstallJava;
        if ! java -version >/dev/null 2>&1; then
            echo "Uninstall was successful";
            echo "";
            exit 0;
        else
            echo "ERROR: Something went wrong. JDK isn't uninstalled.";
            echo "";
            exit 1;
        fi
    else
        VERSION="${1}";
        VERSION_MAJOR=$(echo "${VERSION}" | cut -d '.' -f1);
        VERSION_FLAG="${2}";
        searchWebsite;
        installPackage;
        checkInstall;
    fi
else
    echo "ERROR: Specify the required JDK version or path to .deb package in first flag";
    exit 1;
fi
