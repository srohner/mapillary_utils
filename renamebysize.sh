#!/bin/bash

separator="___"
export separator
parallel_options="--noswap" # options to use for GNU parallel

if [ $# -lt 1 ]; then
	echo "This software renames files by prepending the filename with the file's size (in bytes): 'myfile.jpg' -> '___1234567___myfile.jpg'"
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

	local filesize=$(stat --format=%s $srcfile)
	local dstfile="${separator}""${filesize}""${separator}""$srcfile"

	if [ -e "$dstfile" ]; then
		# destination already exists
		echo "ERROR: Destination file $dstfile already exists. Skipping file '$srcfile'..."
		return
	fi

	mv "$srcfile" "$dstfile"
}
export -f do_stuff

parallel $parallel_options do_stuff ::: "$@"
