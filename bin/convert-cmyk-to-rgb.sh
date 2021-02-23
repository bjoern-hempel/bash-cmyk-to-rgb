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
SETTING_REPLACE=true
SETTING_PROFILE_FILE="$ENV_CURRENT_PATH/.profiles"
SETTING_PROFILE_RGB=""
SETTING_PROFILE_CMYK=""

# ----------
# function: show help
# ----------
showHelp() {
    cat "$BASH_SOURCE" | grep --color=never "# help:" | grep -v 'cat parameter' | sed 's/[ ]*# help:[ ]*//g' | sed "s~%scriptname%~$ENV_SCRIPTNAME~g"
}

# ----------
# function: show version
# ----------
showVersion() {
    echo "$ENV_SCRIPTNAME $ENV_VERSION - $ENV_AUTHOR <$ENV_EMAIL>"
}

# ----------
# function: Function to find all image files within the current folder.
# ----------
getImageFiles() {
    find . -regex ".*\.\(jpg\|gif\|png\|jpeg\)"
}

# ----------
# function: Function to get the colorspace of the given image.
# ----------
getImageColorspace() {
    identify -format "%[colorspace]" "$1"
}

# ----------
# function: Function to get the file size of given image.
# ----------
getImageFileSize() {
    #stat -c%s "$1"
    du -h "$1" | cut -f1
}

# ----------
# function: Checks if the given colorspace has to be converted.
# ----------
getToBeConverted() {
    case "$1" in
        CMYK) return 0 ;;
        *) return 1 ;;
    esac
}

# ----------
# function: Gets the type name of given path.
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
# function: Function to print some image file informations.
# ----------
printFileInformations() {
    local imageColorspace=$(getImageColorspace "$1")
    local imageFileSize=$(getImageFileSize "$1")
    echo "→ Filename:         $1"
    echo "→ Colorspace:       $imageColorspace"
    echo "→ Size:             $imageFileSize"
}

# read arguments
# help:
# help: Usage: %scriptname% [options...]
while [[ $# > 0 ]]; do
    case "$1" in
        # help:
        # help:  -f,    --force                       Force to convert the image.
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

# check profiles
if [ ! -f "$SETTING_PROFILE_FILE" ]; then
    echo "The .profile file was not found. Abort." && echo && exit
fi

# load profiles
source "$SETTING_PROFILE_FILE"

# check profiles
if [ "$SETTING_PROFILE_RGB" == "" ] || [ ! -f "$SETTING_PROFILE_RGB" ]; then
    echo "The rgb profile was not found or not given. Check your .profile file. Abort." && echo && exit
fi
if [ "$SETTING_PROFILE_CMYK" == "" ] || [ ! -f "$SETTING_PROFILE_CMYK" ]; then
    echo "The cmyk profile was not found or not given. Check your .profile file. Abort." && echo && exit
fi

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

    # print some informations
    printFileInformations "$imageFile"

    # checks if the image has to be converted
    if ! getToBeConverted "$imageColorspace"; then
        echo -e "→ STATUS:           \e[42mfine\e[0m"
	echo && echo
        continue
    fi

    # image has to be converted
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

