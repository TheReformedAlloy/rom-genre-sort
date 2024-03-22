#!/bin/sh

input_file="gba.dat"
output_file="output.json"

inside_game_block=false
json_string=""
N=$'\n'
T=$'\t'

while IFS='' read -r line; do
    case "$line" in
        'game ('*)
            inside_game_block=true
            comment=""
            genre=""
            crc=""
            ;;
        ')'*)
            inside_game_block=false
            if [ ! -z "$comment" ]; then
                json_string="$json_string$N\"$crc\": {$N$T\"name\": \"$comment\",$N$T\"genre\": \"$genre\"$N},"
            fi
            ;;
        *)
            if $inside_game_block; then
                case "$line" in
                    *'comment '*)
                        comment="${line#*\"}"     # remove everything before the first quote
                        comment="${comment%%\"*}" # remove everything after the first quote
                        ;;
                    *'genre "'*) 
                        genre="${line#*\"}"
                        genre="${genre%%\"*}"
                        ;;
                    *'rom ( crc '*)
                        crc="${line#*crc }" # removes everything up to crc
                        crc="${crc%% )*}"   # removes everything after the first space
                        ;;
                esac
            fi
            ;;
    esac
done < "$input_file"

# Remove trailing comma, add brackets
json_string="{${json_string%%,}$N}"

echo "$json_string" > "$output_file"
