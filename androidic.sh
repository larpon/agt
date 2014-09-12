#!/bin/bash

#
# androidic.sh
# 
# Copyright (c) 2014 Lars Pontoppidan.
#
# Bash script to scale an input image to the various formats in an Android res/drawable resource
#

# Global flags
OUTDIR="."
FORCE=1
TARGET_DPI_CLASS="xxhdpi"
VERSION="0.1"

# Known dpi classes
declare -a DPI_CLASSES=('mdpi' 'hdpi' 'xhdpi' 'xxhdpi' 'xxxhdpi');
# Follow array above
declare -a DPI_SCALES=('2' '3' '4' '6' '8');
declare -a DPI_FACTORS=('1' '1.5' '2' '3' '4');

usage()
{
	echo -e "Usage:\n\t# `basename $0` [OPTIONS] FILE\n"
	echo "Options:"

	echo -e "\t-f"
	echo -e "\t\tForce override of destination files"
	echo -e "\r"
 
	local list=$(for class in "${DPI_CLASSES[@]}"; do echo -n "$class, "; done | sed 's/, $//')
	echo -e "\t-d CLASS"
	echo -e "\t\tThe Android graphic DPI classification of the input file."
	echo -e "\t\tDefault: $TARGET_DPI_CLASS"
	echo -e "\t\tAccepted: $list"
	echo -e "\r"

	echo -e "\t-v"
	echo -e "\t\tPrint version and exit"
	echo -e "\r"
	
	echo
	echo "Example usage:"
	echo -e "\tGenerate Android standard 2,3,4,6,8 graphic scaled images from default xxhdpi target DPI class"
	echo -e "\t\t# `basename $0` ic_action_test96.png"
	echo -e "\n"
	echo -e "\tGenerate Android standard 2,3,4,6,8,10 graphic scaled images from target DPI class xxxhdpi"
	echo -e "\t\t# `basename $0` ic_action_test128.png"
}

check_exes()
{
	command -v convert >/dev/null 2>&1 || { echo >&2 "This script requires the command line tool \"convert\" to run (part of the ImageMagick tool chain)"; exit 1; }
}

# error()
# {
# 	if [ $REPORT_ERRORS -eq 0 ]; then
# 		echo -n "Error    : "
# 		if [ -z "$1" ]; then
# 			return 1
# 		fi
# 		until [ -z "$1" ]; do
# 			echo -ne "$1"
# 			echo -n " "
# 			shift
# 		done
# 		echo
# 	fi
# 	return 0
# }

die()
{
	usage
	#echo -e "\nThe script didn't finish execution due to following errors:"
	echo ""
	echo $1
	#error $1
	 #echo >&2 "$@"
	#cd $CURRENT_DIR
    exit 1
}

setup_env()
{
	TODO='todo'
}

cleanup_env()
{
	TODO='todo'
}

mkpath()
{
	if [ ! -d "$1" ]; then
		mkdir -p "$1"
	fi
}

# $1 DPI class eg. "xhdpi"
get_dpi_scale()
{
	for (( i = 0; i < ${#DPI_CLASSES[@]}; i++ )); do
		if [ "${DPI_CLASSES[$i]}" = "$1" ]; then
			echo "${DPI_SCALES[$i]}";
		fi
	done
}

# $1 DPI class eg. "xhdpi"
get_dpi_factor()
{
	for (( i = 0; i < ${#DPI_CLASSES[@]}; i++ )); do
		if [ "${DPI_CLASSES[$i]}" = "$1" ]; then
			echo "${DPI_FACTORS[$i]}";
		fi
	done
}


FLOAT_SCALE=2
# Evaluate a floating point number expression.
function float_eval()
{
	local stat=0
	local result=0.0
	if [[ $# -gt 0 ]]; then
		result=$(echo "scale=$FLOAT_SCALE; $*" | bc -q 2>/dev/null)
		stat=$?
		if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
	fi
	echo $result
	return $stat
}

# Evaluate a floating point number conditional expression.
function float_cond()
{
	local cond=0
	if [[ $# -gt 0 ]]; then
		cond=$(echo "$*" | bc -q 2>/dev/null)
		if [[ -z "$cond" ]]; then cond=0; fi
		if [[ "$cond" != 0  &&  "$cond" != 1 ]]; then cond=0; fi
	fi
	local stat=$((cond == 0))
	return $stat
}

# Round
round()
{
	echo $(printf %.$2f "$1")
}

# $1 file path
scale()
{
	local go=false
	
	local file_width=`identify -format "%w" "$1"`
	local target_factor=`get_dpi_factor "$TARGET_DPI_CLASS"`
	local mdpi=$(float_eval "$file_width / $target_factor")
	
	# Traverse DPI array backwards
	for (( idx=${#DPI_CLASSES[@]}-1 ; idx>=0 ; idx-- )) ; do
		local dpi_class="${DPI_CLASSES[idx]}"
		if [ "$dpi_class" = "$TARGET_DPI_CLASS" ]; then
			go=true
		fi
		
		if [ "$go" = true ] ; then
			#local scale=`get_dpi_scale "$dpi_class"`
			local factor=`get_dpi_factor "$dpi_class"`
			
			local size=`float_eval "$mdpi * $factor"`
			size=`round "$size" 0`
			
			#echo "$size"
			
			local outdir="res/drawable-$dpi_class"
			mkpath "$outdir"
			outfile="$outdir/$1"
			
			if [ -f "$outfile" ] && [ "$FORCE" -ne 0 ]; then
				echo -e "$outfile already exists"
				read -n1 -p "Overwrite? [y,n] " OVERWRITE
				case $OVERWRITE in  
				y|Y) rm "$outfile"; echo "";; 
				n|N) echo ""; continue;; 
				*) die "Aborted";; 
				esac
			fi
			
			convert "$1" -resize "$size""x" png32:"$outfile";
		fi
	done
	
}

run()
{
	# Requires at least 1 argument
	[ "$#" -gt 0 ] || die "Missing argument"
	scale $1
}

#
# Main
#

check_exes


setup_env

while getopts ":fd:v" OPTION
do
	case $OPTION in
		f ) FORCE=0;;
		d ) TARGET_DPI_CLASS=$OPTARG;;
		v ) echo $VERSION; exit 0;;
		* ) die "One or more options not recognized";; # DEFAULT
	esac
done
shift $(($OPTIND - 1)) # Move argument pointer to next argument.

run $1

cleanup_env

exit 0