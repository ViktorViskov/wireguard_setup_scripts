#!/bin/bash
# variables
device_to_intenet="enp0s3"
server_public_address="viktorviskov.com"
server_ip="10.0.1.1/24"
server_port="51820"
server_private_key=""
server_public_key=""

start() {
    # check for user is root
    check_for_root
    if [ $? = 1 ]
    then
        # read data from user
        read_user_input

        # generate keys
        create_keys

        # create config file
        create_configs
    else
        echo "Need root privilegios!"
    fi
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
read_user_input() {
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
create_keys() {
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
    echo "[Peer]" >> /etc/wireguard/wg0.conf
}

# start
start