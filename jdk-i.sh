#!/bin/bash
tput reset

echo "Java Development Kit (JDK) installer for Linux"
echo ""

# shellcheck disable=SC1091
source /etc/os-release
OS_ID="${ID}"

apt update >/dev/null 2>&1
apt install wget -y >/dev/null 2>&1

# Root-user check
if [ "${EUID}" -ne 0 ]; then
    echo "ERROR: You must to run this script as root";
    exit 1;
fi

# OS check
if [ "${OS_ID}" != "ubuntu" ] && [ "${OS_ID}" != "debian" ] && [ "${OS_ID}" != "raspbian" ]; then
    echo "ERROR: This script couldn't run on your machine";
    echo "ERROR: At this moment we support only these OS: Debian, Ubuntu, Raspbian";
    exit 1;
fi

# Check version in first flag
if [ -n "${1}" ]; then
    VERSION="${1}";
    FD_VERSION=$(echo "${VERSION}" | cut -d'.' -f1)
    echo "Searching JDK ${VERSION}...";
else
    echo "ERROR: Specify the required JDK version in first flag";
    exit 1;
fi

# Searching JDK version
wget --spider --quiet https://download.oracle.com/java/"${FD_VERSION}"/latest/jdk-"${FD_VERSION}"_linux-x64_bin.deb
LATEST="${?}"

wget --spider --quiet https://download.oracle.com/java/"${FD_VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb
ARCHIVE="${?}"

if [ "${LATEST}" == "0" ] && [ "${ARCHIVE}" == "0" ]; then

    options=("JDK ${VERSION} (Latest, LTS)" "JDK ${VERSION} (Oldest, first version)")
    selected=0

    function drawMenu {
        tput reset
        echo "We found a few versions of JDK. What we need to install?"
        echo ""
        for ((i=0; i<${#options[@]}; i++)); do
            if [ "${i}" -eq "${selected}" ]; then
                echo -e "\e[1m[*] ${options[${i}]}\e[0m"
            else
                echo "[ ] ${options[${i}]}"
            fi
        done
    }

    drawMenu

    while true; do
        read -rsn1 key
        case "${key}" in
            'A')
                selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} ))
                drawMenu
                ;;
            'B')
                selected=$(( (selected + 1) % ${#options[@]} ))
                drawMenu
                ;;
            '')
                break
                ;;
        esac
    done

    if [ "${options[selected]}" == "JDK ${VERSION} (Latest, LTS)" ]; then
        echo ""
        echo "Installing JDK..."
        # Downloading from latest
        wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/latest/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1
    elif [ "${options[selected]}" == "JDK ${VERSION} (Oldest, first version)" ]; then
        echo ""
        echo "Installing JDK..."
        # Downloading from archive (as first version of JDK, not latest)
        wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1
    fi

elif [ "${LATEST}" != "0" ] && [ "${ARCHIVE}" == "0" ]; then
    echo ""
    echo "WARN: it will not be the latest version, you are only installing version ${VERSION} from archive"
    echo "Installing JDK ${VERSION}..."
    # Downloading from archive
    wget -O /tmp/jdk-install.deb https://download.oracle.com/java/"${FD_VERSION}"/archive/jdk-"${VERSION}"_linux-x64_bin.deb >/dev/null 2>&1
else
    echo "ERROR: Couldn't find the specified JDK version on Oracle's website";
    exit 1;
fi

# Installation
apt install /tmp/jdk-install.deb -y >/dev/null 2>&1

# Setting up JDK in alternatives
echo "Setting up JDK...";
update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-"${FD_VERSION}"/bin/java 1 >/dev/null 2>&1
update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-"${FD_VERSION}"/bin/javac 1 >/dev/null 2>&1
update-alternatives --set java /usr/lib/jvm/jdk-"${FD_VERSION}"/bin/java >/dev/null 2>&1
update-alternatives --set javac /usr/lib/jvm/jdk-"${FD_VERSION}"/bin/javac >/dev/null 2>&1

# Last check and finish
if java -version >/dev/null 2>&1; then
    rm /tmp/jdk-install.deb >/dev/null 2>&1;
    echo ""
    echo "Setup was successful! Here is your 'java -version'";
    echo "";
    java -version
    echo "";
else
    rm /tmp/jdk-install.deb >/dev/null 2>&1;
    echo "ERROR: Oh, something went wrong...";
    echo "ERROR: Installation was failed. You can try again.";
    exit 1;
fi
