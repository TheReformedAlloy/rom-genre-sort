#!/bin/sh

input_file="gba.dat"
output_file="output.json"

# declare -A crc_to_genre
# declare -A name_to_genre

inside_game_block=false
crc_to_genre_json=""
name_to_genre_json=""
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
                crc_to_genre_json="$crc_to_genre_json$N\"$crc\":\"$genre\","
                name_to_genre_json="$name_to_genre_json$N\"$comment\":\"$genre\","

                # json_string="$json_string$N\"$crc\": {$N$T\"name\": \"$comment\",$N$T\"genre\": \"$genre\"$N},"
            fi
            ;;
        *)
            if $inside_game_block; then
                case "$line" in
                    *'comment '*)
                        comment="${line#*\"}"     # remove everything before the first quote
                        comment="${comment%%\"*}" # remove everything after the first quote
                        #lower case, remove all symbols and spaces
                        comment=$(echo "$comment" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
                        ;;
                    *'genre "'*) 
                        genre="${line#*\"}"
                        genre="${genre%%\"*}"
                        ;;
                    *'rom ( crc '*)
                        crc="${line#*crc }" # removes everything up to crc
                        crc="${crc%% )*}"   # removes everything after the first space
                        # crc="${crc,,}" # to lower case
                        crc=$(echo "$crc" | tr '[:upper:]' '[:lower:]')
                        ;;
                esac
            fi
            ;;
    esac
done < "$input_file"

# Remove trailing comma, add brackets
jsonstr="{$N$crc_to_genre_json${name_to_genre_json%%,}$N}"

# write to file
echo "$jsonstr" > "$output_file"

#remove duplicate keys
jsonstr=$(jq 'to_entries | unique | from_entries' $output_file)

echo "$jsonstr" > "$output_file"
