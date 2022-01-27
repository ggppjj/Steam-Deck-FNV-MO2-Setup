#!/bin/bash

function is_inside_directory() {
	absolute_target_path=$(realpath "$1")
	absolute_directory=$(realpath "$2")

	relative_target_path=${absolute_target_path##$absolute_directory}

	if [ "$relative_target_path" == "$absolute_target_path" ]; then
		# if the variables are equal it means there is no relative path from the directory to the target
		# the target path is not inside the directory
		return 1
	else
		return 0
	fi
}

if is_inside_directory "$install_dir" "$HOME"; then
	log_info "installing inside home directory, no additional permissions needed"
else
	if [ "$using_flatpak_steam" == "0" ]; then
		opt_flatpak_sandbox_warning=""
	else
		opt_flatpak_sandbox_warning=" and the Flatpak Sandbox"
	fi

	log_warn "installing outside home directory, manual permission configuration may be needed"
	# TODO verify access configuration before displaying warning
	"$dialog" dangerquestion \
		"You are attempting to install Mod Organizer 2 outside your home directory.\n\nThis may require manual configuration of the Steam Runtime${opt_flatpak_sandbox_warning}.\n\nAre you sure you want to continue?"
fi

