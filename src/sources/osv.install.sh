#! /bin/bash
#
# This script installs OSv on a freshly deployed Fedora system.
# There are just some configs to set (see below).
#
# Dependencies:
#     bash
#     sed
#     systemctl
#     tee
#     yum


#################################################################################
# Config                                                                        #
#################################################################################
# Name of the network bridge
bridge='virbr0'

# Name of the  ethernet connection
eth='em1'

# Username of the user who will run OSv (must already exist)
user='osvuser'
group="$user"
# Default path to OSv installation: ~$user
path_to_osv="$(getent passwd $user | cut -d: -f6)"

# Name of the logfile
logfile="./osv.install.log"

# Show traces of all commands
debug=0

# Packages to install - feel free to add more
packages=(
    # Dependencies listed on the OSv-github page
    'ant'                       # provides java-1.7.0-openjdk
    'bison'                     # provides m4
    'boost-static'              # provides boost-devel
    'flex'                      # provides m4
    'gcc-c++'                   # provides libmpc, gcc
    'genromfs'
    'libmpc-devel'              # provides libmpc
    'libtool'                   # provides automake, autoconf
    'libvirt'
    'maven-shade-plugin'        # provides maven, java-1.7.0-openjdk{,-devel}
    'qemu'

    # Added by us because we needed them
    'boost'
    'cmake'
    'dhclient'
    'git'                       # provides openssh, openssh-clients
    'make'
    'openssh-server'            # provides openssh
    'qemu-kvm'
)




#################################################################################
# Permission and general settings                                               #
#################################################################################
# if not root... return
# workaround for `su` 'bug'
if (( $(id -u) != 0 )); then
    echo "This file must be executed as root!"
    exit 1
fi

if [[ -z $user ]]; then
    echo "User does not exist. Please fix the configuration"
    exit 1
fi

if [[ -z $path_to_osv ]]; then
    echo "Invalid OSv path. Please fix the configuration"
    exit 1
fi

if [[ -z $logfile ]]; then
    echo "Invalid logfile path. Please fix the configuration"
    exit 1
fi

out='/dev/stdout'
yes=''
for i in "$@"; do
    if [[ $i = -h || $i = --help ]]; then
        echo "Usage: $(basename $0) [-h|--help] [-s|--silent] [-y|--yes]"
        echo
        echo '-h | --help'
        echo '    Shows this help'
        echo
        echo '-s | --silent'
        echo '    No output to stdout / stderr. Just write to $logfile'
        echo
        echo '-y | --yes'
        echo '    Answer all questions with "yes"'
        exit
    elif [[ $i = -s || $i = --silent ]]; then
        out='/dev/null'
    elif [[ $i = -y || $i = --yes ]]; then
        yes=' -y'
    fi
done



# needed by I/O redirection
{
#################################################################################
# Prepare / adapt cmds...                                                   #
#################################################################################
(( $debug == 1 )) && set -x

echo prepare system commands
echo =======================
echo
install="yum$yes install"
echo "install command: $install"

update="yum$yes update"
echo "update command: $update"

start='systemctl start'
echo "start command: $start"

restart='systemctl restart'
echo "restart command: $restart"

disable='systemctl disable'
echo "disable command: $disable"

enable='systemctl enable'
echo "enable command: $enable"

# no output
nbdir='/etc/sysconfig/network-scripts'

echo
echo


#################################################################################
# Install packages                                                              #
#################################################################################
echo prepare packages
echo ================
echo
echo
echo update os
echo =========
echo
if ! $update; then
    echo "ERROR: Could not update: $i"
    exit 1
fi
echo
echo

echo packages to install:
echo ====================
echo
tmp=$IFS
IFS=$'\n'
echo "${packages[*]}"
IFS=$tmp
echo
echo

echo install packages
echo ================
echo
for i in "${packages[@]}"; do
    if ! $install "$i"; then
        echo "ERROR: Could not install: $i"
        exit 1
    fi
done
echo
echo



#################################################################################
# Enable services                                                               #
#################################################################################
echo enable services
echo ===============
echo
echo ssh...
$enable sshd
$start sshd
echo
echo



#################################################################################
# Network bridge                                                                #
#################################################################################
echo create network bridge
echo =====================
echo
[[ -d $nbdir ]] || mkdir -vp "$nbdir"
cd "$nbdir"

echo backup old configs
[[ -e ifcfg-$bridge ]] && mv -v "ifcfg-$bridge" "ifcfg-${bridge}.bak"
[[ -e ifcfg-$eth ]] && mv -v "ifcfg-$eth" "ifcfg-${eth}.bak"

echo create new configs
cat > "ifcfg-$bridge" << EOF
TYPE=Bridge
DEVICE=virbr0
ONBOOT=yes
NETMASK=255.255.255.0
BOOTPROTO=dhcp
SEARCH="google.com"
EOF

cat > "ifcfg-$eth" << EOF
TYPE=Ethernet
DEVICE=em1
ONBOOT=yes
HWADDR=00:22:64:BE:AB:BB
IPV6INIT=no
USERCTL=no
BRIDGE=virbr0
EOF
echo
echo



#################################################################################
# NetworkManager                                                                #
#                                                                               #
# We disabled the standard NetworkManager because it messes around with the     #
# configuration for the interfaces                                              #
# We use dhclient instead but feel free to use your own                         #
#################################################################################
echo disable network manager
echo =======================
echo
$disable NetworkManager
echo
echo



#################################################################################
# SELinux                                                                       #
#                                                                               #
# The OSv sometimes hangs due to SELinux                                        #
#################################################################################
echo disable selinux
echo ===============
echo
echo change SELinux config
if [[ -d /sys/fs/selinux ]]; then
    cd /etc/selinux
    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' config
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' config
    cat config
fi
echo
echo



#################################################################################
# OSv                                                                           #
#################################################################################
echo install osv
echo ===========
echo
echo prepare osv dir
[[ -d $path_to_osv ]] || mkdir -vp "$path_to_osv"
cd "$path_to_osv"
echo
echo

echo clone git repos
echo ===============
echo
echo main repo
git clone https://github.com/cloudius-systems/osv.git osv
cd osv
git submodule update --init
cd ..
chown -R $user:$group "$path_to_osv/osv"
echo

echo osv extensions
git clone https://github.com/cloudius-systems/osv-apps.git osv-apps
chown -R $user:$group "$path_to_osv/osv-apps"

(( $debug == 1 )) && set +x

# I/O redirection
} 2>&1 | tee "$logfile" >& "$out"
