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

rename() {
	local srcfile="$1"

	if [ ! -f "$srcfile" ]; then
		# current element is not a file
		return
	fi

	local filesize=$(stat --format=%s "$srcfile")
	local dstfile="${separator}""${filesize}""${separator}""$srcfile"

	if grep -qEe "^$separator[0-9]+$separator" <<< "$srcfile"; then # not high-performance, see http://stackoverflow.com/a/240181
		# file has been already renamed (probably by a previous run of this script)
		echo "INFO: Skipping file '$srcfile'. It looks like it has been already renamed."
		return
	fi

	if [ -e "$dstfile" ]; then
		# destination already exists
		echo "ERROR: Skipping file '$srcfile'. Destination file '$dstfile' already exists."
		return
	fi

	mv "$srcfile" "$dstfile"
}
export -f rename

parallel $parallel_options rename ::: "$@"
