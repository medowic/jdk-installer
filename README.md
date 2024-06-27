# jdk-installer
This is **Java Development Kit** installer for Linux Debian-based system (Debian, Ubuntu). All JDKs downloads from [offical Oracle's website](https://www.oracle.com/java/technologies/downloads/). Script is fully automatic. You just need to choose a version and chill out.
> [!IMPORTANT]
> This script only works with JDKs which is distributed under the [Oracle No-Fee Terms and Conditions License](https://java.com/freeuselicense) (**JDK 17 and later**).
# Install
```shell
wget -O jdk-i.sh https://raw.githubusercontent.com/medowic/jdk-installer/master/jdk-i.sh
chmod +x jdk-i.sh
```
# Usage
Before you start script you must to choose a JDK version and write it in first flag
```shell
./jdk-i.sh [JDK-VERSION]
```
### Examples:
This command will install **JDK 21.0.1**
```shell
./jdk-i.sh 21.0.1
```
This command will install **JDK 21**, **but during the installation process**, the script will ask you which version to install: the Latest or the Oldest (because this is the LTS version)
```shell
./jdk-i.sh 21
```
# License
This is project is under the [MIT License](https://raw.githubusercontent.com/medowic/jdk-installer/master/LICENSE).
