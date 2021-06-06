#!/usr/bin/env sh

COLORS=()
ALTCOLORS=('#cccccc' '#555555')

config_replace_eol() {
	sed -r -i config.def.h -e "s#($1).*#\1 $2#"
}
config_replace_lines_between() {
	_tmp="$(mktemp)"
	awk -v start="$1" -v inside="$2" -v finish="$3" '
		BEGIN {p=1}
		$0 ~ start {print;print inside;p=0}
		$0 ~ finish {p=1}
		p' config.def.h > "$_tmp" && mv "$_tmp" config.def.h
}

# args: firstLine secondLine lineMatch replacement
config_replace_line_between() {
	sed -r -i config.def.h -e "/$1/,/$2/{s/$3/$4/}"
}

read_xresources() {
	while read -r _key val; do
		key="$(printf '%s' "$_key" | sed -re 's/([^\s]*):$/\1/')"
		case "$key" in
			*borderpx)
				config_replace_eol 'int borderpx =' "$val;"
				;;
			*color*)
				COLORS["$(printf '%s' "$key" | sed 's/[^0-9]//g')"]="$val"
				;;
			*cursorColor)
				ALTCOLORS[0]="$val"
				config_replace_eol 'unsigned int defaultcs =' '256;'
				;;
			*cursorRev)
				ALTCOLORS[1]="$val"
				config_replace_eol 'unsigned int defaultrcs =' '257;'
				;;
			*background)
				ALTCOLORS[2]="$val"
				config_replace_eol 'unsigned int defaultbg =' '258;'
				;;
			*foreground)
				ALTCOLORS[3]="$val"
				config_replace_eol 'unsigned int defaultfg =' '259;'
				;;
			\*font)
				config_replace_eol 'char \*font =' "\"$val\";"
				;;
			*modkey)
				config_replace_eol '#define MODKEY' "$val"
				;;
			*mouse*)
				button="$(printf '%s' "$key" | sed 's/[^0-9]//g')"
				escaped="$(printf '%s' "$val" | sed 's/[\/&]/\\&/g')"
				config_replace_line_between 'MouseShortcut mshortcuts\[\] = \{' '^\};' "(Button$button,\s+[^\s]+\s+).*" "\1$escaped \},"
				;;
			#*tabspaces)
			#	config_replace_eol 'static unsigned int tabspaces =' "$val;"
			#	;;
			*)
				echo "unknown appres : $key --> $val"
				;;
		esac
	done <<EOF
$(appres st)
EOF
}

print_colors() {
	for i in ${!COLORS[@]}; do
		printf '\t[%d] = "%s",\n' "$i" "${COLORS[i]}"
	done
	for i in ${!ALTCOLORS[@]}; do
		printf '\t[%d] = "%s",\n' "$((256+i))" "${ALTCOLORS[i]}"
	done
}

#
# Actually run everything
#

config_replace_eol 'static char \*shell =' "\"$SHELL\";"

read_xresources

if ((${#COLORS[@]} + ${#ALTCOLORS[@]})); then
	config_replace_lines_between 'const char \\*colorname\\[\\] = {' "$(print_colors)" '^};'
fi
