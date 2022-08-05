#!/bin/bash

###    PARSE POSITIONAL ARGS    ###
nxm_link=$1; shift

if [ -z "$nxm_link" ]; then
	echo "ERROR: please specify a NXM Link to download"
	exit 1
fi

nexus_game_id=${nxm_link#nxm://}
nexus_game_id=${nexus_game_id%%/*}
###    PARSE POSITIONAL ARGS    ###

instance_link="$HOME/.config/modorganizer2/instances/${nexus_game_id:?}"
instance_dir=$(readlink -f  "$instance_link")
if [ ! -d "$instance_dir" ]; then
	[ -L "$instance_link"] && rm "$instance_link"

	zenity --ok-label=Exit --ellipsize --error --text \
		"Could not download file because there is no Mod Organizer 2 instance for '$nexus_game_id'"
	exit 1
fi

instance_dir_windowspath="Z:$(sed 's/\//\\\\/g' <<<$instance_dir)"
pgrep -f "$instance_dir_windowspath\\\\modorganizer2\\\\ModOrganizer.exe"
process_search_status=$?

game_appid=$(cat "$instance_dir/appid.txt")

function send_download_to_running_instance() {
	if [ -z "$(command -v protontricks)" ]; then
		if [ -n "$(command -v flatpak)" ]; then
			if flatpak info com.github.Matoking.protontricks > /dev/null; then
				using_flatpak_protontricks=1
			fi
		fi
	else
		using_flatpak_protontricks=0
	fi

	executable_path="$instance_dir/modorganizer2/nxmhandler.exe"
	if [ "$using_flatpak_protontricks" == "0"]; then
		WINEESYNC=1 WINEFSYNC=1 protontricks-launch --appid "$game_appid" "$executable_path" "$nxm_link"
	else
		flatpak run --env='WINEESYNC=1' --env='WINEFSYNC=1' --command=protontricks-launch com.github.Matoking.protontricks --appid "$game_appid" "$executable_path" "$nxm_link"
	fi

	return $?
}

function start_download() {
	if [ -z "$(command -v steam)" ]; then
		if [ -n "$(command -v flatpak)" ]; then
			if flatpak info com.valvesoftware.Steam > /dev/null; then
				using_flatpak_steam=1
			fi
		fi
	else
		using_flatpak_steam=0
	fi

	if [ "$using_flatpak_steam" == "0"]; then
		steam -applaunch "$game_appid" "$nxm_link"
	else
		flatpak run com.valvesoftware.Steam -applaunch "$game_appid" "$nxm_link"
	fi

	return $?
}

if [ "$process_search_status" == "0" ]; then
	echo "INFO: sending download '$nxm_link' to running Mod Organizer 2 instance"
	download_start_output=$(send_download_to_running_instance 2>&1)
else
	echo "INFO: starting Mod Organizer 2 to download '$nxm_link'"
	download_start_output=$(start_download 2>&1)
fi
download_start_status=$?

if [ "$download_start_status" != "0" ]; then
	zenity --ok-label=Exit --ellipsize --error --text \
		"Failed to start download:\n\n$download_start_output"
	exit 1
fi

