#!/usr/bin/env bash

COLORS=()
ALTCOLORS=()

config_replace_eol() {
	sed -r -i config.def.h -e "/$1/ c\\$1 $2"
}
config_replace_lines_between() {
	_tmp="$(mktemp)"
	awk -v start="$1" -v inside="$2" -v finish="$3" '
		BEGIN {p=1}
		$0 ~ start {print;print inside;p=0}
		$0 ~ finish {p=1}
		p' config.def.h > "$_tmp" && mv "$_tmp" config.def.h
}

read_xresources() {
	while read -r key val; do
		case "$(echo "$key" | sed -re 's/([^\s]*):$/\1/')" in
			*color*)
				COLORS["$(echo $key | sed 's/[^0-9]//g')"]="$val"
				;;
			*cursorColor)
				ALTCOLORS[0]="$val"
				config_replace_eol 'static unsigned int defaultcs =' '256;'
				;;
			*background)
				ALTCOLORS[1]="$val"
				config_replace_eol 'static unsigned int defaultbg =' '257;'
				;;
			*foreground)
				ALTCOLORS[2]="$val"
				config_replace_eol 'static unsigned int defaultfg =' '258;'
				;;
			*font)
				config_replace_eol 'static char font\[\] =' "\"$val\";"
				;;
			*modkey)
				config_replace_eol '#define MODKEY' "$val"
				;;
			*tabspaces)
				config_replace_eol 'static unsigned int tabspaces =' "$val;"
				;;
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
print_buttons() {
	echo '	/* button               mask            string */
	{ Button4,              XK_ANY_MOD,     "\\033[A" },
	{ Button5,              XK_ANY_MOD,     "\\033[B" },'
}

#
# Actually run everything
#

config_replace_eol 'static char shell\[\] =' "\"$SHELL\";"

read_xresources

config_replace_lines_between '^static const char \\*colorname\\[\\] = {' "$(print_colors)" '^};'
config_replace_lines_between '^static Mousekey mshortcuts\\[\\] = {' "$(print_buttons)" '^};'
