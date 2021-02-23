#!/usr/bin/env bash

# some environment variables
ENV_ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_SCRIPTNAME=$(basename "$0")
ENV_CURRENT_PATH=$(pwd)
ENV_VERSION='1.0'
ENV_AUTHOR='Björn Hempel'
ENV_EMAIL='bjoern@hempel.li'

# some settings
SETTING_DRYRUN=true
SETTING_VERBOSE=false
SETTING_REPLACE=false
SETTING_PROFILE_RGB=""
SETTING_PROFILE_CMYK=""
SETTING_FILTER="jpg|gif|png|jpeg|tif"
SETTING_WORKING_DIRECTORY="$ENV_CURRENT_PATH"
SETTING_NEEDED_APPLICATIONS=( convert grep sed cat )

# ----------
# Show help
#
# @author  Björn Hempel
# @version 1.0
# ----------
showHelp() {
    cat "$BASH_SOURCE" | grep --color=never "# help:" | grep -v 'cat parameter' | sed 's/[ ]*# help:[ ]*//g' | sed "s~%scriptname%~$ENV_SCRIPTNAME~g"
}

# ----------
# Show version
#
# @author  Björn Hempel
# @version 1.0
# ----------
showVersion() {
    echo "$ENV_SCRIPTNAME $ENV_VERSION - $ENV_AUTHOR <$ENV_EMAIL>"
}

# ----------
# Function to find all image files within the current folder.
#
# @author  Björn Hempel
# @version 1.0
# ----------
getImageFiles() {
    find . -regex ".*\.\(${SETTING_FILTER//|/\\|}\)"
}

# ----------
# Function to get the colorspace of the given image.
#
# @author  Björn Hempel
# @version 1.0
# ----------
getImageColorspace() {
    identify -format "%[colorspace]" "$1" 2>/dev/null
}

# ----------
# Function to get the file size of given image.
#
# @author  Björn Hempel
# @version 1.0
# ----------
getImageFileSize() {
    #stat -c%s "$1"
    du -h "$1" | cut -f1
}

# ----------
# Checks if the given colorspace has to be converted.
#
# @author  Björn Hempel
# @version 1.0
# ----------
getToBeConverted() {
    case "$1" in
        CMYK) return 0 ;;
        *) return 1 ;;
    esac
}

# ----------
# Gets the type name of given path.
#
# @author  Björn Hempel
# @version 1.0
# ----------
getTypeName() {
    local path=$(dirname "$1")
    local base=$(basename "$1")
    local extension="${base##*.}"
    local filename="${base%.*}"
    local type="$2"
    echo "$path/$filename.$type.$extension"
}

# ----------
# Function to print some image file informations.
#
# @author  Björn Hempel
# @version 1.0
# ----------
printFileInformations() {
    local imageColorspace=$(getImageColorspace "$1")
    local imageFileSize=$(getImageFileSize "$1")
    echo "→ Filename:         $1"
    echo "→ Colorspace:       $imageColorspace"
    echo "→ Size:             $imageFileSize"
}

# ------------
# Check if a given application exists
#
# @author  Björn Hempel
# @version 1.0
# ------------
applicationExists() {
  `which $1 >/dev/null`
}

# read arguments
# help:
# help: Usage: %scriptname% [options...]
while [[ $# > 0 ]]; do
    case "$1" in
        # help:
        # help:  -i,    --image-filter                Change the image filter (default: jpg|gif|png|jpeg|tif)
        -i=*|--image-filter=*)
            SETTING_FILTER="${1#*=}"
            ;;
        -i|--image-filter)
            shift
            SETTING_FILTER="$1"
            ;;

        # help:  -w,    --working-directory           Change the working directory (default: current directory)
        -w=*|--working-directory=*)
            SETTING_WORKING_DIRECTORY="${1#*=}"
            ;;
        -w|--working-directory)
            shift
            SETTING_WORKING_DIRECTORY="$1"
            ;;

        # help:  -r,    --replace                     Replace the image instead of copying it.
        -r|--replace)
            SETTING_REPLACE=true
            ;;

        # help:
        # help:  -f,    --force                       Force to convert the image (no dry run).
        -f|--force)
            SETTING_DRYRUN=false
            ;;

        # help:
        # help:  -x,    --verbose                     Set output to verbose.
        -x|--verbose)
            SETTING_VERBOSE=true
            ;;

        # help:
        # help:  -h,    --help                        Shows this help.
        -h|--help)
            showHelp && exit 0
            ;;

        # help:  -v,    --version                     Shows the version number.
        -v|--version)
            showVersion && exit 0
            ;;

        # help:
        # collect all unknown parameters
        *)
            PARAMETERS+=("$1")
            ;;
    esac
    shift
done

# check installed applications
for application in "${SETTING_NEEDED_APPLICATIONS[@]}"; do
    if ! applicationExists $application; then
        echo "The application \"$application\" does not exists. Please install this application before. Abort." && showHelp && exit
    fi
done

# check working directory
if [ ! -d "$SETTING_WORKING_DIRECTORY" ]; then
    echo "The given working directory does not exists. Abort." && showHelp && exit
fi

# check profiles
SETTING_PROFILE_FILE="$SETTING_WORKING_DIRECTORY/.profiles"
if [ ! -f "$SETTING_PROFILE_FILE" ]; then
    echo "The .profile file was not found. Abort." && showHelp && exit
fi

# load profiles
source "$SETTING_PROFILE_FILE"

# check profiles
if [ "$SETTING_PROFILE_RGB" == "" ] || [ ! -f "$SETTING_PROFILE_RGB" ]; then
    echo "The rgb profile was not found or not given. Check your .profile file. Abort." && showHelp && exit
fi
if [ "$SETTING_PROFILE_CMYK" == "" ] || [ ! -f "$SETTING_PROFILE_CMYK" ]; then
    echo "The cmyk profile was not found or not given. Check your .profile file. Abort." && showHelp && exit
fi

# change working directory
cd $SETTING_WORKING_DIRECTORY

# collect image files
imageFiles=$(getImageFiles)

# loop throug image file
echo
for imageFile in $imageFiles; do
    # ignore .rgb.* and .cmyk.* files
    if [[ $imageFile =~ \.(rgb|cmyk)\.[a-zA-Z]+$ ]]; then
        continue
    fi

    # get some informations
    imageColorspace=$(getImageColorspace "$imageFile")
    imageFileSize=$(getImageFileSize "$imageFile")

    # checks if the image has to be converted
    if ! getToBeConverted "$imageColorspace"; then
        if $SETTING_VERBOSE; then
            printFileInformations "$imageFile"
            echo -e "→ STATUS:           \e[42mfine\e[0m"
	    echo && echo
        fi
        continue
    fi

    # image has to be converted
    printFileInformations "$imageFile"
    echo -e "→ STATUS:           \e[41mto be converted\e[0m"

    # check dryrun
    if $SETTING_DRYRUN; then
        echo "→ Dryrun. Use -f to convert."
	echo && echo
        continue
    fi

    # convert image
    imageFileCMYK=$(getTypeName "$imageFile" "cmyk")
    imageFileRGB=$(getTypeName "$imageFile" "rgb")
    echo "→ Convert image to sRGB."
    echo "  → Source:         $imageFile"
    echo "  → Target:         $imageFileRGB"
    echo "  → RGB profile:    $SETTING_PROFILE_RGB"
    echo "  → CMYK profile:   $SETTING_PROFILE_CMYK"
    convert -profile "$SETTING_PROFILE_CMYK" -profile "$SETTING_PROFILE_RGB" -colorspace rgb "$imageFile" "$imageFileRGB"
    echo "→ Done."

    # replace origin file
    if $SETTING_REPLACE; then
        echo "→ Replace origin file with rgb version."
        rm "$imageFile"
        mv "$imageFileRGB" "$imageFile"
        echo "→ Done."
    fi

    # print some informations
    if $SETTING_REPLACE; then
        printFileInformations "$imageFile"
    else
        printFileInformations "$imageFileRGB"
    fi

    # finally
    echo && echo
done

