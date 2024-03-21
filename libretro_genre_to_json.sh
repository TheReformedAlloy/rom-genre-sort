#!/bin/bash

input_file="gba.dat"
output_file="output.json"

inside_game_block=false
json_string=""
N=$'\n'
T=$'\t'

while IFS='' read -r line; do
#	echo "$line"
    if [[ $line =~ ^game\ \( ]] then
        inside_game_block=true
        comment=""
        genre=""
        crc=""
        
    elif [[ $line =~ ^\) ]]; then
        inside_game_block=false
        if [ ! -z "$comment" ]; then
            json_string="$json_string$N\"$crc\": {$N$T\"name\": \"$comment\",$N$T\"genre\": \"$genre\"$N},"
        fi
    elif $inside_game_block; then
        if [[ $line =~ ^'	comment' ]]; then
            comment="${line#*\"}"   # remove everything before the first quote
            comment="${comment%%\"*}"   # remove everything after the first quote
        elif [[ $line =~ ^'	genre' ]]; then
			genre="${line#*\"}"
            genre="${genre%%\"*}"
        elif [[ $line =~ ^'	rom ( crc' ]]; then
            crc="${line#*crc }" # removes everything up to crc
            crc="${crc%% )*}" # removes everything after the first space
#            echo $crc
        fi
    fi
done < "$input_file"

# Remove trailing comma, add brackets
json_string="{${json_string%%,}$N}"

echo "$json_string" > "$output_file"
