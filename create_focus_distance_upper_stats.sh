#!/bin/bash

# just a quick hack to see how many 'Focus Distance Upper' entries appear for which distances (and sort the results by distance)

exiftool *.JPG | grep Upper | sort | uniq -c | sort -k 2 -n -t :
