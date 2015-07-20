#!/bin/bash

if [ $# -lt 1 ]; then
	echo "This software does the following changes to JPEG files:"
	echo "- remove all JPEG meta-information (including thumbnail) except EXIF-tags"
	echo "- remove the MakerNotes EXIF tag"
	echo "- add the GPSVersionID=2.3.0.0 EXIF tag"
	echo
	echo "Usage: $0 file1 [file2 [file3 [...]]] or $0 *.jpg"
	exit 1
fi

parallel_options="--noswap"

do_stuff() {
	local file="$1"
	jhead -dc -di -dx -du "$file" # remove all side-information except exif
	exiftool \
		-overwrite_original    `# do not create a backup file` \
		-GPSVersionID=2.3.0.0  `# set gps version id so the mapillary webinterface can process the pictures` \
		-makernotes:all=       `# remove makernotes (proprietary exif information) since we do not know what they contain` \
		-ImageDescription= `# remove image description (created e.g. by Mapillary app)` \
		-ifd1:all=             `# remove thumbnail and associated tags ( http://perlmaven.com/how-to-remove-thumbnail-from-a-jpeg-using-image-exiftool )` \
		"$file"
}
export -f do_stuff

parallel $parallel_options do_stuff ::: "$@"
