#!/usr/bin/env bash

clean_backups() {
	for p in /usr/lib/modules/*; do
		if [ -L "$p" ] && [[ "${p##*/}" != "${CURR_KERNEL}" ]]; then
			printf "Link found: %s -> %s\n" "$p" "$(readlink -f "$p")"
			unlink "$p"
		fi
	done
}

backup_kernel() {
	mkdir -p /tmp/kernel-backups

	if [ -d /usr/lib/modules/"${CURR_KERNEL}" ]; then
		cp -r /usr/lib/modules/"${CURR_KERNEL}" /tmp/kernel-backups
	fi
}

link_backup() {
	if [ -d /tmp/kernel-backups/"${CURR_KERNEL}" ] && [ ! -e /usr/lib/modules/"${CURR_KERNEL}" ]; then
		ln -s /tmp/kernel-backups/"${CURR_KERNEL}" /usr/lib/modules/
	fi
}

main() {
	CURR_KERNEL="$(uname -r)"
	clean_backups
	if [[ "$1" == "preupgrade" ]]; then
		backup_kernel
	elif [[ "$1" == "postupgrade" ]]; then
		link_backup
	fi
}

main "$@"
