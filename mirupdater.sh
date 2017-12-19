#!/bin/bash
#####################################################################
#                                                                   #
#  "Arch Mirrorlist Updater"                                        #
#  Filename: mirupdater.sh                                          #
#  Author: Rasmus van Guido (goldenfinch.net@zoho.com)              #
#  Version: 1.0                                                     #
#  Licence: GNU General Public License v2.0                         #
#																	#
#  Description: This is a simple bash script for use in an Arch     #
#     Linux operating system. It basically simplify the updating    #
#     and selecting of faster mirrors for your mirrorlist file.     #
#     So, instead of typing several commands on the terminal        #
#     just to update your mirrorlist, this script will do just      #
#     that for you.                                                 #
#                                                                   #
#  How to use this script:                                          #
#     1. Just place this script in your home directory              #
#     2. Make sure you make this file executable                    #
#     3. Then run it like so in your terminal: # ./mirupdater.sh    #
#                                                                   #
#  PS: You need to be root to run this script. Thank you!           #
#                                                                   #
#####################################################################

# CONFIGURATION
# The number of mirrors to select. Default is 6
NMIRRS=6


# DO NOT CHANGE anything below unless you know what you are doing
ARCHOS="ARCH"
ARUSER="root"
ARCHCK=false
SDELAY=2
ISARCH=$( { /usr/bin/uname -a; } 2>&1 )
MRCOMP="https://www.archlinux.org/mirrorlist/all/"
MIRDIR="/etc/pacman.d/"
MLFILE="mirrorlist"
MLPCNW="mirrorlist.pacnew"
MLPCOL="mirrorlist.old"
MLPCBK="mirrorlist.backup"
MLTEMP="/tmp/mirrorlist.tmp"
DBLOCK="/var/lib/pacman/db.lck"
TXCOLR="\033[0;33m"
NOCOLR="\033[0m"

if [[ "$ISARCH"==*"$ARCHOS"* ]]; then
	# Just to make sure we're running on a Archlinux OS platform
	printf "\n::Thank you for using this mirrorlist updater :)\n"
	printf "::${TXCOLR}WARNING:${NOCOLR} Before you continue, make sure pacman is not running...\n"
	read -n1 -r -p "::Press space bar to continue..."
	printf "\n"
	ARCHCK=true
else
	printf "\n${TXCOLR}===== ERROR =====${NOCOLR}\n"
	printf "This script is only intended for Achlinux Operating System.\n"
	printf "For more information, please visit: https://www.archlinux.org/\n"
	printf "\n"
	exit 0
fi

# Make sure this file is running by a 'root' user
if [ "$USER" != "$ARUSER" ]; then
	printf "\n::IMPORTANT: You need to be 'root' to perform this task...\n"
	printf "::Please log in as a root then try again...\n\n"
	exit 0
fi

# Some utility check, make sure we have all that we need
if [ ! -f "/usr/bin/bash" ]; then
	printf "\n::${TXCOLR}ERROR:${NOCOLR} Missing required dependency: bash...\n"
	exit 0
fi

if [ ! -f "/usr/bin/rankmirrors" ]; then
	printf "\n::${TXCOLR}ERROR:${NOCOLR} Missing required dependency: rankmirrors...\n"
	exit 0
fi

if [ ! -f "/usr/bin/curl" ]; then
	printf "\n::${TXCOLR}ERROR:${NOCOLR} Missing required dependency: curl...\n"
	exit 0
fi

printf "::Checking important mirrorlist files...\n"

sleep "$SDELAY"

# Save a copy of the mirrorlist file in the /tmp directory
cp -f "$MIRDIR$MLFILE" "$MLTEMP"

if [[ "$ARCHCK"==true ]]; then

	# Check for the actual mirrorlist file and back it up
	if [ -f "$MIRDIR$MLFILE" ]; then
		cp -f "$MIRDIR$MLFILE" "$MIRDIR$MLPCOL"
		printf "::Main mirrorlist file is intact (backup created: mirrorlist.old)...\n"
	else
		printf "::${TXCOLR}FATAL ERROR:${NOCOLR} $MIRDIR$MLFILE file is missing...\n\n"
		exit 0
	fi
	
	# Check for the mirrorlist.pacnew file, if there's none, make one
	if [ ! -f "$MIRDIR$MLPCNW" ]; then
		printf "::Getting a fresh mirrorlist.pacnew file...\n\n"
		
		sleep "$SDELAY"
		
		curl -o "$MIRDIR$MLPCNW" "$MRCOMP"
		printf "\n"
	else
		printf "::mirrorlist.pacnew is still the latest update...\n"
	fi
else
	exit 0
fi

printf "::Updating mirrors...\n"
printf "::Selecting the faster local mirrors (this may take a few minutes)...\n"
printf "\n::NOTE: If you want to monitor this activity, open up a new terminal\n"
printf "::      and run this command: tail -f /etc/pacman.d/mirrorlist\n\n"

sleep "$SDELAY"

if [ ! -f "$MIRDIR$MLPCBK" ]; then
	cp -f "$MIRDIR$MLPCNW" "$MIRDIR$MLPCBK"
	sed -i 's/^#Server/Server/' "$MIRDIR$MLPCBK"
else
	sed -i 's/^#Server/Server/' "$MIRDIR$MLPCBK"
fi

if [ -f "$MIRDIR$MLPCBK" ] && [ -f "$MIRDIR$MLPCNW" ]; then
	printf "::Mirror update in progress. Please wait.......................\n"
	rankmirrors -n "$NMIRRS" "$MIRDIR$MLPCBK" > "$MIRDIR$MLFILE"
	
	sleep "$SDELAY"
	
	printf "\n::Done selecting local mirrors. $NMIRRS mirror(s) selected...\n"
	printf "::Will now update pacman's package list...\n\n"
	
	sleep "$SDELAY"

	if [ -f "$DBLOCK" ]; then
		printf "::${TXCOLR}WARNING:${NOCOLR} Pacman appears to be running. "
		printf "Finish the pacman process first...\n"
		
		read -p "::Done running pacman? Y:Continue, n:Terminate (Y/n) " YN
	
		case $YN in
			[Yy]*) 
				rm -f "$DBLOCK" ;;
			[Nn]*)
				kill 0 ;;
			*)
				rm -f "$DBLOCK" ;;
		esac
	fi	

	# Force update pacman's package list
	pacman -Syyu
	printf "\n::Done!\n\n"
	
	# Cleanup
	rm -f "$MIRDIR$MLPCBK"
	rm -f "$MLTEMP"
	exit 0
fi
