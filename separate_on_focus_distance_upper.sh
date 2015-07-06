#!/bin/bash

export limit=1.2     # the distance limit in meters
export near_dir=near # name of the target directory for pictures BELOW the limit
export far_dir=far   # name of the target directory for pictures ABOVE the limit
parallel_options="--noswap -j 200%" # options to use for GNU parallel

if [ $# -lt 1 ]; then
	echo "This software moves image files with EXIF data in folders '$near_dir' or '$far_dir' based on exiftool's value of the field 'Focus Distance Upper'. The currently defined limit is: ${limit} m."
	echo
	echo "Usage: $0 file1 [file2 [file3 [...]]] or $0 *.jpg"
	exit 1
fi

do_stuff() {
	local file="$1"

	if [ ! -f "$file" ]; then
		# current element is not a file
		return
	fi

	local focusdistanceupper=$(exiftool "$file" | grep -e "^Focus Distance Upper")
	if [ ${#focusdistanceupper} -eq 0 ]; then
		# required exif data not found. grep had no match, since string length is 0, see http://stackoverflow.com/a/17368090
		return
	fi

	local distance=$(echo "$focusdistanceupper" | sed -e "s/.*: \(.*\) m/\1/")
	local is_near=$(echo "$distance < $limit" | bc) # from http://stackoverflow.com/a/1787060
	local target_file

	if [ "$is_near" -eq 1 ]; then
		# near
		mkdir -p $(dirname "$file")/"$near_dir"
		target_file=$(dirname "$file")/"$near_dir"/$(basename "$file")
	else
		# far
		mkdir -p $(dirname "$file")/"$far_dir"
		target_file=$(dirname "$file")/"$far_dir"/$(basename "$file")
	fi

	if [ -e "$target_file" ]; then
		echo "WARNING: Destination file '$target_file' exists. Skipping..."
	else
		mv "$file" "$target_file"
	fi

}
export -f do_stuff

parallel $parallel_options do_stuff ::: "$@"
