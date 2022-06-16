#!/bin/bash
# default settings
device_to_intenet="enp0s3"
server_public_address="viktorviskov.com"
server_ip="10.0.1.1/32"
server_port="51820"
client_name="default_client"
client_ip="10.0.1.100/32"

# variables
server_private_key=""
server_public_key=""
client_private_key=""
client_public_key=""

# show app managment menu
start_menu() {
    # check for user is root
    check_for_root
    if [ $? = 1 ]
        then   
        # show system message
        echo "Wireguard managment app"
        echo "Press 'c' to create server config file (/etc/wireguard/wg0.conf)"
        echo "Press 'a' to add client to server and generate config file"
        echo "Press 'd' to delete client from server"
        echo "Press 'r' to start/restart wireguard server"
        echo "Press 's' to stop wireguard server"
        echo -n "ESC to exit: "

        # read user input
        read -ern1 key

        if [ $key = "c" ]
        then
            create_server
            
        elif [ $key = "a" ]
        then
            create_client
        elif [ $key = "d" ]
        then
            delete_client
        elif [ $key = "r" ]
        then
            wg-quick down wg0
            wg-quick up wg0
        elif [ $key = "s" ]
        then
            wg-quick down wg0
        fi
    else
        echo "Need root privilegios!"
    fi
}

# method for create client
create_client() {
        # read data from user
        read_client_user_input
        read_from_config

        # generate keys
        create_client_keys
        register_on_server

        # create config file
        create_client_config
}

# check for root
check_for_root() {
    user_name=$(whoami)
    if [ $user_name = "root" ]
    then
        return 1
    else
        return 0
    fi
}

# read data to config
read_client_user_input() {
    # read name for client
    echo -n "Client name: [$client_name]: "
    read -r new_client_name
    if [ "$new_client_name" != "" ]
    then
        client_name="$new_client_name"
    fi

    # read client ip
    echo -n "Client IP: [$client_ip]: "
    read -r new_client_ip
    if [ "$new_client_ip" != "" ]
    then
        client_ip="$new_client_ip"
    fi
}

# read data from config file
read_from_config() {
    server_public_address=$(awk '/Public/' /etc/wireguard/wg0.conf | awk 'NR == 1' | awk '{print $3}')
    server_public_key=$(cat /etc/wireguard/server_public.key)
}

# function for generate wireguard keys
create_client_keys() {
    client_private_key=$(wg genkey)
    client_public_key=$(echo $client_private_key | wg pubkey)
}

# register to server config
register_on_server() {
    echo "" >> /etc/wireguard/wg0.conf
    echo "[Peer]        #$client_name" >> /etc/wireguard/wg0.conf
    echo "PublicKey = $client_public_key        #$client_name" >> /etc/wireguard/wg0.conf
    echo "AllowedIPs = $client_ip       #$client_name" >> /etc/wireguard/wg0.conf
}

create_client_config() {
    echo "[Interface]" > "$client_name.conf"
    echo "PrivateKey = $client_private_key" >> "$client_name.conf"
    echo "Address = $client_ip"  >> "$client_name.conf"
    echo "" >> "$client_name.conf"
    echo "#ClientPublicKey = $client_public_key" >> "$client_name.conf"
    echo "" >> "$client_name.conf"
    echo "[Peer]" >> "$client_name.conf"
    echo "PublicKey = $server_public_key" >> "$client_name.conf"
    echo "Endpoint = $server_public_address" >> "$client_name.conf"
    echo "AllowedIPs = 0.0.0.0/0" >> "$client_name.conf"
    echo "PersistentKeepalive = 29" >> "$client_name.conf"
}

# method for create server configs
create_server() {
    # read data from user
    read_server_user_input

    # generate keys
    create_server_keys

    # create config file
    create_configs
}

# read data to config
read_server_user_input() {
    # show interfaces
    show_network_interfaces

    # read internet interface
    echo -n "Interface with internet: [$device_to_intenet]: "
    read -r new_device_to_intenet
    if [ "$new_device_to_intenet" != "" ]
    then
        device_to_intenet="$new_device_to_intenet"
    fi

    #read server ip
    echo -n "Server ip address: [$server_ip]: "
    read -r new_server_ip
    if [ "$new_server_ip" != "" ]
    then
        server_ip="$new_server_ip"
    fi

    #read public address
    echo -n "Server public address: [$server_public_address]: "
    read -r new_server_public_address
    if [ "$new_server_public_address" != "" ]
    then
        server_public_address="$new_server_public_address"
    fi
}

# function for generate wireguard keys
create_server_keys() {
    server_private_key=$(wg genkey)
    server_public_key=$(echo $server_private_key | wg pubkey)

    # write to files
    echo -n $server_private_key > /etc/wireguard/server_private.key
    echo -n $server_public_key > /etc/wireguard/server_public.key
}

# create config file
create_configs() {
    # write to file
    echo "[Interface]" > /etc/wireguard/wg0.conf
    echo "Address = $server_ip" >> /etc/wireguard/wg0.conf
    echo "ListenPort = $server_port" >> /etc/wireguard/wg0.conf
    echo "PrivateKey = $server_private_key" >> /etc/wireguard/wg0.conf
    echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $device_to_intenet -j MASQUERADE" >> /etc/wireguard/wg0.conf
    echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $device_to_intenet -j MASQUERADE" >> /etc/wireguard/wg0.conf
    echo "" >> /etc/wireguard/wg0.conf
    echo "#Public = $server_public_address:$server_port" >> /etc/wireguard/wg0.conf
    echo "" >> /etc/wireguard/wg0.conf
}

# function for delete user
delete_client() {
    # search all active clients
    active_users=$(awk '/ #/' /etc/wireguard/wg0.conf | awk '{print $4}' | awk '!seen[$0]++')

    # ask for user name
    echo "Active users:" $active_users
    echo -n "User to delete: "
    read -r user_to_delete

    # delete
    sed -i "/ #$user_to_delete\b/d" /etc/wireguard/wg0.conf
}

# show all network interfaces
show_network_interfaces() {
    clear
    echo "Available network interfaces"
    ip -o link show | awk '{print $2}' 
}


# start script
start_menu