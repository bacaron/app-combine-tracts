#!/bin/bash

# top variables
track=`jq -r '.track' config.json`
indices=`jq -r '.combineIndices' config.json`
roiNames=(`cat names.txt`)

# reformat indices to keep all indices to merge on one line
indexArray=()
while read -r line; do
	indexArray+=("$line")
done <<< "$indices"

# generate individual tracts for each index
connectome2tck ${track} assignments.txt node -files per_node

# loop through all indices to combine
for (( i=0; i<${#indexArray[*]}; i++ ))
do
	holder=""
	for j in ${indexArray[$i]}
	do
		file=(*node$((j))*.tck)
		holder=$holder" `echo $file`"
	done

	if [[ $i -lt 10 ]]; then
		tckedit ${holder[*]} track00$((i+1)).tck
	else
		tckedit ${holder[*]} track0$((i+1)).tck
	fi
done

# create final tractogram
if [ ! -f track/track.tck ]; then

	# combine to one final tractogram
	holder=(*track0*.tck)
	
	if [ ${#holder[@]} == 1 ]; then
        cp -v ${holder[0]} ./track/track.tck
    else
        tckedit ${holder[*]} ./track/track.tck
    fi
	tckinfo ./track/track.tck > ./track/track_info.txt
fi

# final check
if [ -f track/track.tck ]; then
	echo "tracts combined"
	mv node*.tck ./raw
else
	echo "something went wrong. check logs and derivatives"
	exit 1
fi