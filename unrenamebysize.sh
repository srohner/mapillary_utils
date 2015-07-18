#!/bin/bash

export separator="___"
parallel_options="--noswap" # options to use for GNU parallel

if [ $# -lt 1 ]; then
	echo "This software renames files by removing a prefix that begins and ends with '$separator': '${separator}1234567${separator}myfile.jpg' -> 'myfile.jpg'"
	echo
	echo "Usage: $0 file1 [file2 [file3 [...]]] or $0 *.jpg"
	exit 1
fi

do_stuff() {
	local srcfile="$1"

	if [ ! -f "$srcfile" ]; then
		# current element is not a file
		return
	fi

	local dstfile=$(echo "$srcfile" | sed -e "s/^$separator[0-9]\+$separator//")

	if [ "$srcfile" == "$dstfile" ]; then
		echo "INFO: Skipping file '$srcfile'. Its name has not a suitable format to be unrenamed."
		return
	fi

	if [ -e "$dstfile" ]; then
		# destination already exists
		echo "ERROR: Skipping file '$srcfile'. Destination file '$dstfile' already exists."
		return
	fi

	mv "$srcfile" "$dstfile"
}
export -f do_stuff

parallel $parallel_options do_stuff ::: "$@"
