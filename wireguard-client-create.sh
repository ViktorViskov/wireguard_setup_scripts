# variables
client_name="default_client"
client_ip="10.0.1.100/24"
server_public_address=""
server_public_key=""
client_private_key=""
client_public_key=""

start() {
    # check for user is root
    check_for_root
    if [ $? = 1 ]
    then
        # read data from user
        read_user_input
        read_from_config

        # generate keys
        create_keys
        register_on_server

        # create config file
        create_client_config
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
create_keys() {
    client_private_key=$(wg genkey)
    client_public_key=$(echo $client_private_key | wg pubkey)
}

# register to server config
register_on_server() {
    echo "PublicKey = $client_public_key    #$client_name" >> /etc/wireguard/wg0.conf
    echo "AllowedIPs = $client_ip         #$client_name" >> /etc/wireguard/wg0.conf
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

start