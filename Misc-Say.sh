Volume="$4"
Word="$5"

osascript -e "Set Volume $Volume"
say $Word
osascript -e "Set Volume 0"