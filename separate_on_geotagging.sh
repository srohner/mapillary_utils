#!/bin/bash

export reliable_dir="reliably_tagged"
export unreliable_dir="unreliably_tagged"

parallel_options="--noswap -j 200%" # options to use for GNU parallel

if [ $# -lt 1 ]; then
	echo "This software moves JPEG image files with EXIF data into folders '$reliable_dir' or '$unreliable_dir' based on exiftool's values of the fields 'GPS Date/Time' and 'GPS Position'. A reliable geotagging is one where the mentioned values occur only once per picture. Unreliably tagged images are those where the same timestamp/location occurs multiple times or not at all. Filetypes other than JPEG are not moved."
	echo
	echo "Usage: $0 file1 [file2 [file3 [...]]] or $0 *.jpg"
	exit 1
fi

print_timelocation() {
	local file="$1"
	
	local timelocation=$(exiftool "$file" | grep -E "GPS (Date/Time|Position)" | tr -d '\n')
	echo "$timelocation"
}
export -f print_timelocation


# print gps date/time and position
read_entry() {
	local file="$1"

	# skip element if not a file
	if [ ! -f "$file" ]; then
		# current element is not a file
		return
	fi

	# output gps date/time and position
	print_timelocation "$file"
}
export -f read_entry

# param1: filename
# param2: "reliable"/"unreliable"
prepare_dir() {
	local file="$1"

	if [[ "$2" == "reliable" ]]; then
		mkdir -p $(dirname "$file")/"$reliable_dir"
		echo $(dirname "$file")/"$reliable_dir"/$(basename "$file")
	elif [[ "$2" == "unreliable" ]]; then
		mkdir -p $(dirname "$file")/"$unreliable_dir"
		echo $(dirname "$file")/"$unreliable_dir"/$(basename "$file")
	else
		>&2 echo ERROR: Unrecognized parameter in function $FUNCNAME. Aborting... # https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
		exit 1
	fi
}
export -f prepare_dir

# sort pictures
sort_picture() {
	local file="$1"
	local target_file
	
	# skip element if not a file
	if [ ! -f "$file" ]; then
		# current element is not a file
		return
	fi

	# read date/time and location of file
	local time_location=$(print_timelocation "$file")
	
	# prepare to move files
	if [ ${#time_location} -eq 0 ]; then
		# couldn't read time/location
		local filetype=$(exiftool "$file" | grep "^File Type" | sed -e "s/.*: \(.*\)$/\1/")
		if [[ "$filetype" == "JPEG" ]]; then
			# filetype is JPEG, but time/location couldn't be read
			target_file=$(prepare_dir "$file" unreliable)
		else
			# filetype is NOT JPEG, do nothing
			return
		fi
	# check if file is reliably geotagged
	elif [[ "$duplicate_entries" =~ "$time_location" ]]; then
		# duplicate / geocoding NOT reliable
		target_file=$(prepare_dir "$file" unreliable)
	else
		# not duplicate / geocoding probably reliable
		target_file=$(prepare_dir "$file" reliable)
	fi

	# move file
	if [ -e "$target_file" ]; then
		echo "WARNING: Destination file '$target_file' exists. Skipping..."
	else
		mv "$file" "$target_file"
	fi
}
export -f sort_picture

export duplicate_entries=$(parallel $parallel_options --linebuffer read_entry ::: "$@" | sort | uniq -d)

parallel $parallel_options sort_picture ::: "$@"
