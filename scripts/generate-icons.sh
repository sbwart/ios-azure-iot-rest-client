#!/bin/bash
#
# generate-icons.sh - use inkscape to produce icons of various resolutions for an iOS app
#

resolutions=(20 29 40 58 60 76 80 83.5 87 120 152 167 180)

for size in ${resolutions[@]}; do
	echo "Generating ${size} by ${size} image"
	inkscape -z -e icon-${size}x${size}.png -w ${size} -h ${size} -b white icon.svg
done

exit 0