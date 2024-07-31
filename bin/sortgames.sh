#!/bin/sh

genrejson="output.json"

for romfile in *.*; do
	romfileNoExt="${romfile%.*}"
	romfileNoBrackets="${romfileNoExt%%\(*}"
	romfileNoSymbols=$(echo "$romfileNoBrackets" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]' )
	# echo $romfileNoSymbols

	# Calculate CRC
	case $romfile in 
		*.zip)
			crc=$(unzip -p "$romfile" | xcrc /proc/self/fd/0)
			;;
		*.7z)
			crc=$(7z e "$romfile" -so | xcrc /proc/self/fd/0)
			;;
		*.*)
			crc=$(xcrc "$romfile")
			;;
		*) 
			continue
			;;
	esac

	#first search by CRC
    genre=$(jq -r '.["'"$crc"'"]' $genrejson);

	#then search by name
	if [ "$genre" = "null" ]; then
	 	genre=$(jq -r 'to_entries[] | select(.key | contains("'"$romfileNoSymbols"'")) | .value' $genrejson | head -1)
	fi

	if [ -z "$genre" ]; then
		echo "Genre not found: $romfile"
	else
		mkdir -p "$genre"
		mv "$romfile" "$genre/"
		echo "$genre <-- $romfile"
	fi
done