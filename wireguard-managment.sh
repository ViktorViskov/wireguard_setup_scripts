#!/bin/bash
# default settings
device_to_intenet=$(ip -o link show | awk '/BROADCAST,MULTICAST,UP,LOWER_UP/ {gsub(":","",$2); 
print $2; exit}')
server_public_address="Your public address"
server_ip="10.0.1.1/32"
server_port="51820"
client_name="default_client"
client_ip="10.0.1.100/32"

# variables
server_private_key=""
server_public_key=""
client_private_key=""
client_public_key=""
menu=true
action=true

# show app managment menu
start_ui() {
    # check for user is root
    check_for_root
    if [ $? = 1 ]; then
        while [ $menu != $'\e' ]
        do
            # select submenu
            main_menu

            case $menu in 
                # install menu
                "i")
                    action=true
                    while [ $action != $'\e' ]
                    do
                        # show menu
                        install_menu

                        # read action
                        action=$(read_action)

                        case $action in 
                            # install wireguard
                            "i")
                            clear
                            echo "Intalling wireguard"
                            apt update
                            apt install wireguard -y
                            echo "Installing successfull"
                            echo "Press any key to continue"
                            read -n1
                            ;;

                            # remove wireguard
                            "r")
                            clear
                            echo "Deleting wireguard"
                            apt purge wireguard -y
                            echo "Deleting successfull"
                            echo "Press any key to continue"
                            read -n1
                            ;;
                            # enable autostart
                            "a")
                            clear
                            echo "Enabling wireguard"
                            systemctl enable wg-quick@wg0
                            echo "Press any key to continue"
                            read -n1
                            ;;

                            # disable autostart
                            "d")
                            clear
                            echo "Disabling wireguard"
                            systemctl disable wg-quick@wg0
                            echo "Press any key to continue"
                            read -n1
                            ;;

                            #enable inv4 routing
                            "4")
                            # uncommenting
                            sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
                            sed -i 's/#net.ipv4.ip_forward=0/net.ipv4.ip_forward=0/g' /etc/sysctl.conf

                            # enabling
                            sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
                            
                            # reload settings
                            sysctl -p /etc/sysctl.conf

                            clear
                            echo "Routing enabled"
                            echo "Press any key to continue"
                            read
                            ;;
                            #disable inv4 routing
                            "5")
                            clear
                            # disabling
                            sed -i 's/net.ipv4.ip_forward=1/net.ipv4.ip_forward=0/g' /etc/sysctl.conf
                            
                            # reload settings
                            sysctl -p /etc/sysctl.conf

                            echo "Routing disabled"
                            echo "Press any key to continue"
                            read
                            ;;

                        esac
                    done
                ;;
                # server menu
                "s")
                    action=true
                    while [ $action != $'\e' ]
                    do
                        # show menu
                        server_menu

                        # read action
                        action=$(read_action)

                        case $action in 
                            # create server config file
                            "c")
                            #  confirm action
                            clear
                            echo "Its overwrite current config file. Want you continue? [y/n]"
                            read -rn1 confirm_input
                            if [ $confirm_input = "y" ]
                            then
                                # script
                                create_config_action
                            fi
                            ;;

                            # restart
                            "r")
                            restart_server_action
                            ;;

                            # stop server
                            "t")
                            stop_server_action
                            ;;

                            # show file
                            "s")
                            clear
                            cat /etc/wireguard/wg0.conf
                            echo ""
                            echo "Press any key for continue"
                            read -n1
                            ;;

                            # edith file
                            "e")
                            vi /etc/wireguard/wg0.conf
                            ;;

                        esac
                    done
                    # change default value
                    server_menu=true
                ;;
                # client menu
                "c")
                action=true
                    while [ $action != $'\e' ]
                    do
                        # show menu
                        client_menu

                        # read action
                        action=$(read_action)

                        case $action in 
                            # create server config file
                            "a")
                            create_client
                            ;;

                            # restart
                            "d")
                            delete_client
                            ;;

                            # stop server
                            "l")
                            show_used_ip
                            ;;
                        esac
                    done
                    # change default value
                    client_menu=true
                ;;
            esac
        done
        clear


    else
        echo "Need root privilegios!"
    fi
}

# 
# UI
# 

# UI main menu
main_menu() {
    clear
    echo "Wireguard managment app"
    echo "Press 'i' to open install config menu"
    echo "Press 's' to open server config menu"
    echo "Press 'c' to open client config menu"
    echo -n "ESC to exit: "
    
    #  dialog to select menu
    menu=true
    read -rn1 menu
}

# show install menu
install_menu() {
    clear
    echo "Install menu"
    echo "Press 'i' to install wireguard"
    echo "Press 'r' to remove wireguard"
    echo "Press 'a' to enable autostart"
    echo "Press 'd' to disable autostart"
    echo "Press '4' to enable ipv4 routing"
    echo "Press '5' to disable ipv4 routing"
    echo -n "ESC to back: "
}

# show server menu
server_menu() {
    clear
    echo "Server menu"
    echo "Press 'c' to create server config file (/etc/wireguard/wg0.conf)"
    echo "Press 'r' to start/restart wireguard server"
    echo "Press 't' to stop wireguard server"
    echo "Press 's' to show server config file (/etc/wireguard/wg0.conf)"
    echo "Press 'e' to edith server config file (/etc/wireguard/wg0.conf)"
    echo -n "ESC to back: "
}

# show client menu
client_menu() {
    clear
    echo "Client menu"
    echo "Press 'a' to add client to server and generate config file"
    echo "Press 'd' to delete client from server"
    echo "Press 'l' to show all used IP"
    echo -n "ESC to back: "
}

# read menu action
read_action() {
    # key=true
    # read key
    read -rn1 key

    #  to lower case
    key=$(echo $key | tr 'A-Z' 'a-z')

    # to int
    # key=$(printf '%d' "'$key")
    # return $(expr $key)

    # result
    echo -n $key
}

# 
# Server actions
# 

# menu action function
create_config_action () {
    clear

    # read data from user
    read_server_user_input

    # generate keys
    create_server_keys

    # create config file
    create_configs

    # message
    echo "Config file was created"
    echo "Press any key for continue"
    read -n1
}

# read data to config
read_server_user_input() {
    # show interfaces
    show_network_interfaces

    # read internet interface
    echo -n "Interface with internet: [$device_to_intenet]: "
    read -r new_device_to_intenet
    if [ "$new_device_to_intenet" != "" ]; then
        device_to_intenet="$new_device_to_intenet"
    fi

    #read server ip
    echo -n "Server ip address: [$server_ip]: "
    read -r new_server_ip
    if [ "$new_server_ip" != "" ]; then
        server_ip="$new_server_ip"
    fi

    #read port
    echo -n "Server port: [$server_port]: "
    read -r new_server_port
    if [ "$new_server_port" != "" ]; then
        server_port="$new_server_port"
    fi

    #read public address
    echo -n "Server public address: [$server_public_address]: "
    read -r new_server_public_address
    if [ "$new_server_public_address" != "" ]; then
        server_public_address="$new_server_public_address"
    fi
}

# function for generate wireguard keys
create_server_keys() {
    server_private_key=$(wg genkey)
    server_public_key=$(echo $server_private_key | wg pubkey)

    # write to files
    echo -n $server_private_key >/etc/wireguard/server_private.key
    echo -n $server_public_key >/etc/wireguard/server_public.key
}

# create config file
create_configs() {
    # write to file
    echo "[Interface]" >/etc/wireguard/wg0.conf
    echo "Address = $server_ip" >>/etc/wireguard/wg0.conf
    echo "ListenPort = $server_port" >>/etc/wireguard/wg0.conf
    echo "PrivateKey = $server_private_key" >>/etc/wireguard/wg0.conf
    echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $device_to_intenet -j MASQUERADE" >>/etc/wireguard/wg0.conf
    echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $device_to_intenet -j MASQUERADE" >>/etc/wireguard/wg0.conf
    echo "" >>/etc/wireguard/wg0.conf
    echo "#Public = $server_public_address:$server_port" >>/etc/wireguard/wg0.conf
    echo "" >>/etc/wireguard/wg0.conf
}

# menu action for restart server
restart_server_action() {
    clear

    wg-quick down wg0
    echo "Server was stopped"
    wg-quick up wg0
    echo "Server was started"
    echo ""
    echo "Press any key for continue"
    read -n1
}

# menu action for stop server
stop_server_action() {
    clear

    wg-quick down wg0
    echo "Server was stopped"
    echo ""
    echo "Press any key for continue"
    read -n1
}

# 
# Client actions
# 

# method for create client
create_client() {
    clear

    # show users
    show_users

    # read data from user
    read_client_user_input
    read_from_config

    # generate keys
    create_client_keys
    register_on_server

    # create config file
    create_client_config
}

# read data to config
read_client_user_input() {
    # read name for client
    echo -n "Client name: [$client_name]: "
    read -r new_client_name
    if [ "$new_client_name" != "" ]; then
        client_name="$new_client_name"
    fi

    # read client ip
    echo -n "Client IP: [$client_ip]: "
    read -r new_client_ip
    if [ "$new_client_ip" != "" ]; then
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
    echo "" >>/etc/wireguard/wg0.conf
    echo "[Peer]        #$client_name" >>/etc/wireguard/wg0.conf
    echo "PublicKey = $client_public_key        #$client_name" >>/etc/wireguard/wg0.conf
    echo "AllowedIPs = $client_ip       #$client_name" >>/etc/wireguard/wg0.conf
}

# generate config file
create_client_config() {
    echo "[Interface]" >"$client_name.conf"
    echo "PrivateKey = $client_private_key" >>"$client_name.conf"
    echo "Address = $client_ip" >>"$client_name.conf"
    echo "" >>"$client_name.conf"
    echo "#ClientPublicKey = $client_public_key" >>"$client_name.conf"
    echo "" >>"$client_name.conf"
    echo "[Peer]" >>"$client_name.conf"
    echo "PublicKey = $server_public_key" >>"$client_name.conf"
    echo "Endpoint = $server_public_address" >>"$client_name.conf"
    echo "AllowedIPs = 0.0.0.0/0" >>"$client_name.conf"
    # echo "PersistentKeepalive = 29" >>"$client_name.conf" # send empty packet to save connection every 29 sec
}

# function for delete user
delete_client() {
    clear

    # ask for user name
    show_users
    echo -n "User to delete: "
    read -r user_to_delete

    # delete
    sed -i "/ #$user_to_delete\b/d" /etc/wireguard/wg0.conf
}

# show all users
show_users() {
    echo "Users registered on server"
    awk '/ #/ {print $4} '  /etc/wireguard/wg0.conf | awk '/#/ {gsub("#","",$1); print $1}' | awk '!seen[$0]++'
}


# method for used ip addresses
show_used_ip() {
    clear
    echo "All used IP addresses"
    cat /etc/wireguard/wg0.conf | grep AllowedIPs | awk '{print $4, "\t-\t" , $3}'
    echo ""
    echo "Press any key for continue"
    read -n1
}

# 
# Other functions
# 

# check for root
check_for_root() {
    user_name=$(whoami)
    if [ $user_name = "root" ]; then
        return 1
    else
        return 0
    fi
}

# show all network interfaces
show_network_interfaces() {
    clear
    echo "Available network interfaces"
    ip -o link show | awk '{print $2}' 
}

# 
# start script
# 
start_ui
