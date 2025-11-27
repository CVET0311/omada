# Install the TP-Link Omada SDN Software Controller (self-hosted)

Here, we install the Omada SDN software controller in two ways: the first, an automated install using a shell script, and the second, a manual install with the instructions below. A future script will include the automated installation and configuration of the NGINX reverse proxy.

The instructions for both the automated and manual installation methods were tested on a fresh installation of Ubuntu Server 24.04 LTS as a virtual machine in Proxmox VE v9.0.11, and with with the following dependency versions:
- Omada SDN Controller, version 6.0.0.24 (Debian package)
- OpenJDK, version 17.0.17 (headless)
- MongoDB Community Edition, version 8.0.12 (<8.1.0 required)

> The official install documentation from TP-Link states that the Java Runtime Environment (JRE) is needed, but this is incorrect. The Java Development Kit (JDK) is the necessary package, and like the JRE package specified in the instructions, can also run in headless mode.

In case of issues installing the Omada SDN software controller, use the following links to check the currently available versions of the dependencies:
- Omada SDN https://support.omadanetworks.com/us/product/omada-software-controller/#Controller_Software
- Commons Daemon https://archive.apache.org/dist/commons/daemon/source/
- LibSSL https://archive.ubuntu.com/ubuntu/pool/main/o/openssl/

# Automated Install Using a Shell Script

Here, we update and upgrade the packages, pull the script, and install the Omada SDN software controller using the script hosted in this repository.

> WARNING: Always check scripts yourself--do not inherently trust any script! The provided script includes plenty of comments that explain what each command does.


## 1. Update the local package database and upgrade packages:
```
sudo apt update && sudo apt dist-upgrade -y
```

## 2. Pull the Script, Change Permissions, and Run the Script

```
wget https://raw.githubusercontent.com/CVET0311/omada/main/install-omada.sh
chmod u+x install-omada.sh
./install-omada.sh
```

# Manual Installation Instructions

It is important not to skip over any steps, which may result in a failed installation. These instructions include setting specific versions of packages using enviroment variables for modularity, and changing them may break the installation.

## 1. Update the local package database and upgrade packages:
Update the local package database:
```
sudo apt update && sudo apt dist-upgrade -y
```

## 2. Set the package version variables
Set the variables:
```
OMADA_VER=6.0.0.24
JDK_VER=17
MONGODB_VER=8.0.12
```
Optional - check the variables:
```
echo "The Omada SDN Controller version set is $OMADA_VER"
echo "The OpenJDK version set is $JDK_VER"
echo "The MongoDB version set is $MONGODB_VER"
```

## 3. Install the dependencies

Install the dependencies for Omada:
```
sudo apt install -y \
    openjdk-$JDK_VER-jdk-headless \
    gnupg \
    jsvc 
```

Optional - check the version of Java:
```
java -version
```

## 4. Install Mongo-DB

Install the MongoDB repository key and update the package database again with the MongoDB repository:
```
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor && \
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
```

Install MongoDB with the version specified using the environment variable:
```
sudo apt install -y --allow-downgrades \
    mongodb-org=$MONGODB_VER \
    mongodb-org-database=$MONGODB_VER \
    mongodb-org-server=$MONGODB_VER \
    mongodb-mongosh \
    mongodb-org-shell=$MONGODB_VER \
    mongodb-org-mongos=$MONGODB_VER \
    mongodb-org-tools=$MONGODB_VER \
    mongodb-org-database-tools-extra=$MONGODB_VER
```
> When installing a specific version of MongoDB, the desired version must be referenced for all of the components. For more information, see the [MongoDB Installation Docs](https://www.mongodb.com/docs/manual/administration/install-community/?linux-distribution=ubuntu&linux-package=default&operating-system=linux&search-linux=with-search-linux).

Start the mongod.service and check the status (press 'q' to exit):
```
sudo systemctl daemon-reload && \
sudo systemctl enable --now mongod
sudo systemctl status mongod.service
```

> If the MongoDB fails to start after the controller starts, check for errors:
> `journalctl -xeu mongod.service`

Prevent the MongoDB version from being upgraded on the next 'apt upgrade', which may break the install:
```
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections
```

> If there is an issue with the service starting, it will likely be the result of the physical CPU flags (AVX) not being passed to the OS in a virtual machine. To allow this feature in Proxmox VE, shutdown the host, and change the host type to 'host', then start the VM again.
>`VM > Hardware > Processors > Type: 'Host'`
>Find more information at [SuperUser.com](https://superuser.com/questions/1814515/mongodb-error-failed-with-result-core-dump).

## 5. Install the Omada Software Controller
Download and install the latest version of the Omada SDN software controller:
Omada SDN Controller
```
wget "https://static.tp-link.com/upload/software/2025/202510/20251031/omada_v${OMADA_VER}_linux_x64_20251027202535.deb"
sudo dpkg -i omada_v*
```

Visit http://localhost:8088 or http://your_ip_address:8088 to check for proper install.

## References:
  
- MongoDB. (n.d.). *Install MongoDB Community Edition*. https://www.mongodb.com/docs/manual/administration/install-community/?operating-system=linux&linux-distribution=ubuntu&linux-package=default&search-linux=with-search-linux
- Super User. (n.d.). *MongoDB error - failed with result 'core-dump'*. https://superuser.com/questions/1814515/mongodb-error-failed-with-result-core-dump
- TP-Link. (2025 October 16). *How to install Omada Software Controller on Linux system*. https://www.tp-link.com/us/support/faq/3272/
