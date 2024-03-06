#!/bin/bash

clear
# Color codes
green='\e[32m'
red='\e[38;5;196m'
orange='\e[38;5;214m'
lightgray='\033[00;37m'
resetcolor='\e[0m'

# Check sudo
if [[ $EUID -eq 0 ]]; then
	messagecolor=$red
	echo -e "${red}Please do not run this script as sudo!"
	read -r
	exit 1
fi

# Answer is yes function
function answer_yes() {
	case "$1" in
		[Yy]|[Yy][Ee][Ss])
			return 0
			;;
		*)
			return 1
			;;
	esac
}

# Answer is no function
function answer_no() {
	case "$1" in
		[Nn]|[Nn][Oo])
			return 0
			;;
		*)
			return 1
			;;
	esac
}
echo -e "${orange}####################"
echo -e "${orange}# Checking system! #"
echo -e "${orange}####################\n"

# What is your OS?
OS=$(uname)
userOS=""

if [ "$OS" == "Darwin" ]; then
    userOS="MacOS"
    echo -e "${resetcolor}Ok, I see you're using ${orange}$userOS!${resetcolor}"
elif [ "$OS" == "Linux" ]; then
    userOS="Linux"
    echo -e "${resetcolor}Ok, I see you're using ${orange}$userOS!${resetcolor}"
else
    echo -e "${red}Unsupported operating system: $OS${resetcolor}"
    exit 1
fi

# Does ssh-keygen exist?
if command -v ssh-keygen &> /dev/null; then
    echo -e "${orange}ssh-keygen${resetcolor} package is ${green}available\n${resetcolor}"
else
    echo -e "${orange}ssh-keygen ${red}not found! ${resetcolor}Please install ${orange}OpenSSH${resetcolor} or make sure it's in your ${orange}PATH\n${resetcolor}Press Enter to exit"
    read -r
    exit 1
fi

# Create SSH path
ssh_folder="$HOME/.ssh"
if [ ! -d "$ssh_folder" ]; then
    echo -e "${resetcolor}Creating ${orange}$ssh_folder\n${resetcolor}"
    mkdir -p "$ssh_folder"
fi

keyname="git$userOS" # get keyname based on the users OS
# Check if key already exists
if [ -e "$ssh_folder/$keyname" ]; then
    while true; do

	echo -e "${red}The key already exists!${resetcolor} Do you want to overwrite it?"
	read -p "Enter your choice (y/n): " answer_overwrite_key
	
	if answer_yes "$answer_overwrite_key"; then
	    echo -e "${resetcolor}\nOverwritting ${orange}keypair...\n${resetcolor}Press enter twice and leave the ${orange}passphrase empty${resetcolor} for now\n"
	    sleep 1
	    rm "$ssh_folder/$keyname" && rm "$ssh_folder/$keyname.pub"
	    ssh-keygen -t rsa -f $ssh_folder/$keyname
	    echo -e "\n${resetcolor}ssh keypair ${orange}$keyname${resetcolor} and ${orange}$keyname.pub${resetcolor} have been ${green}overwritten${resetcolor}"
	    break
	elif answer_no "$answer_overwrite_key"; then
	    echo -e "\n${red}Exiting..."
	    exit 1
	else
	    echo ""
	fi
    done
    # Create the key if it doesn't exist
else
    ssh-keygen -t rsa -f $ssh_folder/$keyname
    echo -e "\n${resetcolor}ssh keypair ${orange}$keyname${resetcolor} and ${orange}$keyname.pub${resetcolor} have been ${green}created${resetcolor}"
fi
 

# Create or overwrite SSH config file
config_file="$ssh_folder/config"
if [ -e "$config_file" ]; then
    
    while true; do
    
	echo -e "\n${red}The config file already exists! ${resetcolor}Do you want to overwrite it?"
	read -p "Enter your choice (y/n): " answer_overwrite

	if answer_yes "$answer_overwrite"; then
	    cat << EOF > "$config_file"
Host github.com
	User git
	Hostname github.com
	PreferredAuthentications publickey
	IdentityFile ~/.ssh/$keyname
	IdentitiesOnly yes
EOF
	    echo -e "\n${green}Config file overwritten!${resetcolor}"
	    break
	elif answer_no "$answer_overwrite"; then
	    echo -e "\n${red}Exiting..."
	    exit 1
	else
	    echo ""
	fi
    done
else
    cat << EOF > "$config_file"
Host github.com
	User git
	Hostname github.com
	PreferredAuthentications publickey
	IdentityFile ~/.ssh/$keyname
	IdentitiesOnly yes
EOF
    echo -e "\n${green}Config file created!${resetcolor}"
fi

#Copy the public key to clipboard
if [ "$userOS" == "MacOS" ]; then
    pbcopy < "$ssh_folder/$keyname.pub"
    echo -e "${green}Public key copied to clipboard!"
else
    if command -v xclip &> /dev/null; then
        xclip -sel clip < "$ssh_folder/$keyname.pub"
	echo -e "${green}Public key copied to clipboard!"
    elif command -v xsel &> /dev/null; then
        xsel --clipboard < "$ssh_folder/$keyname.pub"
	echo -e "${green}Public key copied to clipboard!"
    else
        echo -e "${red}Neither xclip nor xsel found. Please install one of them."
        exit 1
    fi
fi
echo -e "\nGo to https://github.com/settings/profile -> SSH and GPG Keys\nChoose New SSH key and paste the .pub key contents in your clipboard"
