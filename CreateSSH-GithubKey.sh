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
	printf "${red}Please do not run this script as sudo!\n"
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

printf "${orange}#######################################\n"
printf "${orange}##          Checking system!         ##\n"
printf "${orange}#######################################\n"

# What is your OS?
OS=$(uname)
userOS=""

if [ "$OS" == "Darwin" ]; then
    userOS="MacOS"
    printf "${resetcolor}Ok, I see you're using ${orange}$userOS!${resetcolor}\n"
elif [ "$OS" == "Linux" ]; then
    userOS="Linux"
    printf "${resetcolor}Ok, I see you're using ${orange}$userOS!${resetcolor}\n"
else
    printf "${red}Unsupported operating system: $OS${resetcolor}\n"
    exit 1
fi

# Does ssh-keygen exist?
if command -v ssh-keygen &> /dev/null; then
    printf "${orange}ssh-keygen${resetcolor} package is ${green}available!\n${resetcolor}"
else
    printf "${orange}ssh-keygen ${red}not found! ${resetcolor}Please install ${orange}OpenSSH${resetcolor} or make sure it's in your ${orange}PATH\n${resetcolor}Press Enter to exit\n"
    read -r
    exit 1
fi

# Create SSH path
ssh_folder="$HOME/.ssh"
if [ ! -d "$ssh_folder" ]; then
    printf "${resetcolor}Creating ${orange}$ssh_folder${resetcolor}\n"
    mkdir -p "$ssh_folder"
fi

keyname="github$userOS" # get keyname based on the users OS
# Check if key already exists
if [ -e "$ssh_folder/$keyname" ]; then
    while true; do

	printf "${red}The key already exists!${resetcolor}\nDo you want to overwrite it?"
	read -p " Enter your choice (y/n): " answer_overwrite_key
	
	if answer_yes "$answer_overwrite_key"; then
	    printf "${resetcolor}\nOverwritting ${orange}keypair...\n${resetcolor}Press enter twice and leave the ${orange}passphrase empty${resetcolor} for now\n\n"
	    sleep 1
	    rm "$ssh_folder/$keyname" && rm "$ssh_folder/$keyname.pub"
	    ssh-keygen -t rsa -f $ssh_folder/$keyname
	    printf "\n${resetcolor}ssh keypair ${orange}$keyname${resetcolor} and ${orange}$keyname.pub${resetcolor} have been ${green}overwritten${resetcolor}"
	    break
	elif answer_no "$answer_overwrite_key"; then
	    printf "\n${red}Exiting..."
	    exit 1
	else
	    echo ""
	fi
    done
    # Create the key if it doesn't exist
else
    ssh-keygen -t rsa -f $ssh_folder/$keyname
    printf "\n${resetcolor}ssh keypair ${orange}$keyname${resetcolor} and ${orange}$keyname.pub${resetcolor} have been ${green}created${resetcolor}"
fi
 
config_file="$ssh_folder/config"
# Check if the SSH config file exists
if [ -e "$config_file" ]; then
    # Check if the configuration block for github.com exists
    if ! grep -q "^Host github.com$" "$config_file"; then
        # Append the configuration block for github.com
        cat << EOF >> "$config_file"
Host github.com
	User git
	Hostname github.com
	PreferredAuthentications publickey
	IdentityFile ~/.ssh/$keyname
	IdentitiesOnly yes
EOF
        printf "\n${green}Configuration block for github.com appended to the SSH config file.${resetcolor}"
    else
        printf "\n${red}The required configuration already exists in the SSH config file.${resetcolor}"
    fi
else
    # Create a new SSH config file with the configuration block for github.com
    mkdir -p "$ssh_folder"
    cat << EOF > "$config_file"
Host github.com
	User git
	Hostname github.com
	PreferredAuthentications publickey
	IdentityFile ~/.ssh/$keyname
	IdentitiesOnly yes
EOF
    printf "\n${green}SSH config file created with configuration block for github.com.${resetcolor}"
fi

# Copy the public key to clipboard
if [ "$userOS" == "MacOS" ]; then
    pbcopy < "$ssh_folder/$keyname.pub"
    printf "\n${green}Public key copied to clipboard!"
else
    if command -v xclip &> /dev/null; then
        xclip -sel clip < "$ssh_folder/$keyname.pub"
	printf "\n${green}Public key copied to clipboard!"
    elif command -v xsel &> /dev/null; then
        xsel --clipboard < "$ssh_folder/$keyname.pub"
	printf "\n${green}Public key copied to clipboard!"
    else
        printf "${red}Neither xclip nor xsel found. Please install one of them."
        exit 1
    fi
fi
printf "\nGo to https://github.com/settings/profile -> SSH and GPG Keys\nChoose 'New SSH key' and paste the .pub key contents in your clipboard"
