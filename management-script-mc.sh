#!/bin/bash

# useradd $name --home /home/$name --shell /bin/bash

# Choose Project Name
read -p 'Project Name: ' name

#Choose version minecraft server
choose_version () {
echo """
Choose Version :

1 - 1.12
2 - 1.13
3 - 1.14
4 - 1.15

"""
read -p 'Patch server: ' choose
case $choose in
    1) version="1.12.2";;
    2) version="1.13.2";;
    3) version="1.14.4";;
    4) version="1.15.2";;
    *) choose_version;;
esac
}

choose_version

# Download java-server.jar
wget -O java-server.jar https://papermc.io/api/v1/paper/$version/latest/download
echo "Minecraft Server PaperMc $version Download !"

# Create folder minecraft and folder project name
mkdir /opt/minecraft/
mkdir /opt/minecraft/$name/

# Change owner and move java-server.jar
chown minecraft: java-server.jar
mv java-server.jar /opt/minecraft/$name/java-server.jar

# Copy/Paste and change owner mc-run.sh
cp mc-run.sh /opt/minecraft/$name/mc-run.sh
chown minecraft: /opt/minecraft/$name/mc-run.sh

# Copy/Paste eula.txt
cp eula.txt /opt/minecraft/$name/eula.txt

# Copy/Pasten change variable and move minecraft.service
cp minecraft-template.service minecraft-"$name".service
sed -i "s/srv-name/$name/g" minecraft-"$name".service
mv minecraft-"$name".service /usr/lib/systemd/system/minecraft-"$name".service
