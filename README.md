# jdk-installer
This is **Java Development Kit** installer for Linux Debian-based system (Debian, Ubuntu). All JDKs downloads from [offical Oracle's website](https://www.oracle.com/java/technologies/downloads/). Script is fully automatic. You just need to choose a version and chill out.
> [!IMPORTANT]
> Online install only works with JDKs which is distributed under the [Oracle No-Fee Terms and Conditions License](https://java.com/freeuselicense) (**JDK 17 and later**)
# Install
```shell
wget -O jdk-i.sh https://raw.githubusercontent.com/medowic/jdk-installer/master/jdk-i.sh
chmod +x jdk-i.sh
```
# Usage
Before you start script you must to choose a JDK version and write it in first flag
```shell
./jdk-i.sh [JDK-VERSION] [FLAGS]
```
> [!NOTE]
> If another version of JDK is found, it will be deleted and the JDK version that was specified will be installed
## Versions
### Examples:
This command will install **JDK 21.0.1**
```shell
./jdk-i.sh 21.0.1
```
This command will install **JDK 21**, **but during the installation process**, the script will ask you which version to install: the Latest or the Oldest (because this is the LTS version)
```shell
./jdk-i.sh 21
```
### Offline install
This command will install **JDK from .deb-package** (offline install)
> [!IMPORTANT]
> Offline install only works with .deb-packages
```shell
./jdk-i.sh /path/to/jdk.deb
```
## Flags (optional)
- `--latest` / `-l` - Install **latest** version of JDK, (if it's LTS version, for example)
- `--oldest` / `-o` - Install **oldest (first)** version of JDK, (if it's LTS version, for example)
### Examples:
This command will install **oldest (first)** JDK version
```shell
./jdk-i.sh 21 --oldest
```
This command will install **latest JDK** version
```shell
./jdk-i.sh 21 --latest
```
# Delete
This command will **delete JDK** from your machine
```shell
./jdk-i.sh delete
```
# License
This is project is under the [MIT License](https://raw.githubusercontent.com/medowic/jdk-installer/master/LICENSE)
