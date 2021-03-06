#!/bin/bash

name=""			#set name variable
version=""		#set version variable
port=""			#set server port
boot=False		#set boot server after created
url_request=""		#set for url request bukkit version
url_download=""		#set url download version bukkit support
bukkit=""		#set bukkit support (spigot, crafbukkit, paper, vanilla)
table_version_bukkit=""	#set all version for support
bukkit_version=()	#set list all version
bukkit_under_version=()	#set list all under_version



# Check setting is set to launch script
check() {
if [ -z $1 ]
then
  if [ "$(whoami)" == "minecraft" ]
  then
    choose_name_server
  else
    echo "Permision denied ! Connect to minecraft user !"
    exit
  fi
else
    echo "No settings! Delete $1"
    exit
fi
}


# Choose Project Name
choose_name_server() {
read -p 'Project Name: ' name_server
if [ -z $name_server ]
then
    echo -e "Enter name server!"
    choose_name_server
else
    name="$(echo $name_server | tr [A-Z] [a-z])"
    for file in /opt/minecraft/instances/*
    do
	if [ -d $file ] && [ $name = $(echo $file | cut -d'/' -f5) ]
 	then
	    dual=True
	    break
	fi
    done
    if [ $dual ]
    then
	echo "Name already existing !"
	choose_name_server
    else
	server_port
    fi
fi
}


# Choose port server
server_port(){
read -p 'Choose Server Port: ' choose_port
if [ "${choose_port##*[!0-9]*}" ] && [ $choose_port -ge 25565 ]
then
    for port_list in $(grep port ~/instances/settings.ini | cut -d'=' -f2)
    do
        if [ $choose_port = $port_list ]
        then
            duplicate=True
            break
        fi
    done
    if [ $duplicate ]
    then
        read -p "Duplicate Port $port_list (Do you want to continue ? yes/no ): " choose
        if [ $choose = "yes" ]
        then
	    port=$choose_port
            bukkit_support
        else
            server_port
        fi
    else
	port=$choose_port
        bukkit_support
    fi
else
    echo "Port bigger 25565"
    server_port
fi
}

# Choose bukkit support
bukkit_support() {
echo '
Bukkit Support :
1 - Spigot
2 - Craftbukkit
3 - Papermc
4 - Vanilla
5 - Other
'

read -p 'Choose Bukkit Support: ' number_bukkit
case $number_bukkit in
    1)	url_request="https://getbukkit.org/download/spigot"
	bukkit="spigot"
	request_https;;
    2)	url_request="https://getbukkit.org/download/craftbukkit"
	bukkit=""craftbukkit
	request_https;;
    3)	url_request="https://papermc.io/ci/rssLatest"
	bukkit="papermc"
	request_https;;
    4)	url_request="https://getbukkit.org/download/vanilla"
	bukkit="vanilla"
	request_https;;
    5)  read -p "Your link: " $url_request
	bukkit="other"
	request_https;;
    *)	bukkit_support;;
esac
}


# Check pull request http
request_https() {
request_url="$(curl -i -o - --silent -X GET $url_request)"
http_status=$(echo "$request_url" | grep HTTP |  awk '{print $2}')
if [ $http_status == "200" ]
then
    if [ $bukkit != "papermc" ]
    then
	table_version_bukkit="$(echo "$request_url" | grep -oP '<h2>1\.\d+\.\d+' | cut -c5-11)"
    else
	table_version_bukkit="$(echo "$request_url" | grep -oP '1\.\d+\.\d+')"
    fi
    list_version
else
    echo "Error $http_status, server web not found"
fi
}


# List all version and all under_version
list_version(){
bukkit_version=()	#set list all version
bukkit_under_version=()	#set list all under_version
for version_list in $table_version_bukkit
do
    under_version=$(echo "$version_list" | grep -oP '1\.\d+')
    if ! [[ ${bukkit_version[*]} =~ (^|[[:space:]])"$under_version"($|[[:space:]]) ]]
    then
	bukkit_under_version=("${bukkit_under_version[@]}" $version_list)
	bukkit_version=("${bukkit_version[@]}" $under_version)
    fi
done
choose_version
}


# Echo under_version for bukkit support
choose_version(){
number_choose=1
for versions in ${bukkit_under_version[*]}
do
    echo "$number_choose - $versions"
    ((number_choose++))
done
echo "0 - Back"

read -p "Choose version $bukkit support: " choose
if [ $choose -ge 1 ] && [ $choose -le ${#bukkit_under_version[*]} ]
then
    version=${bukkit_under_version[$choose-1]}
    download_request
elif [ $choose -eq 0 ]
then
    bukkit_support
else
    choose_version
fi
}


# Check if download page is good
download_request(){
if [ $bukkit != "papermc" ] && [ $bukkit != "other" ]
then
    url_download="https://cdn.getbukkit.org/$bukkit/$bukkit-$version.jar"
elif [ $bukkit == "papermc" ]
then
    url_download="https://papermc.io/api/v1/paper/$version/latest/download"
fi
request_url="$(curl -i -o - --silent -X GET $url_download)"
http_status=$(echo "$request_url" | grep HTTP |  awk '{print $2}')
if [ $http_status == "200" ]
then
    settings_file
fi
}


settings_file(){
# Create file config.ini if not exist
touch ~/settings/settings-${name}.ini
echo "
[$name]
ram=1024
port=$port
" > ~/settings/settings-${name}.ini
boot_server
}

boot_server(){
read -p "Boot server ? (yes/no) : " choose
if [ $choose = "yes" ]
then
    boot=True
fi
server_script
}


server_script(){
# Create folder projet on /opt
mkdir /opt/minecraft/instances/$name
# Download java-server.jar and move
curl -o java-server.jar $url_download
mv java-server.jar /opt/minecraft/instances/$name/java-server.jar
echo "Minecraft Server $bukkit $version Download on /opt/minecraft/instances/$name !"
# Copy/Paste, mc-run.sh and eula.txt
cp file-srv/mc-run.sh /opt/minecraft/instances/$name/mc-run.sh
sed -i "s/name/$name/g" /opt/minecraft/instances/$name/mc-run.sh
cp file-srv/eula.txt /opt/minecraft/instances/$name/eula.txt
# Copy/Paste management-template.sh
cp file-srv/management-template.sh ~/instances/management-"$name".sh
sed -i "s/name/$name/g" ~/instances/management-"$name".sh

if [ $boot ]
then
    echo "$name"
    sleep 2
    cd /opt/minecraft/instances/$name
    /usr/bin/screen -dmS mc-srv-$name /bin/bash mc-run.sh
fi
}

check



