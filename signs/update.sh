#!/bin/bash
APP_DATA_PATH=$(echo $LOCALAPPDATA | sed 's/\\/\//g')
GAME_LOCAL_PATH="$APP_DATA_PATH/Colossal Order/Cities_Skylines"
IMPORT_PATH="$GAME_LOCAL_PATH/Addons/Import"
if [ -z "$1" ]; then
	printf "ERROR: Missing PATH argument\n"
	exit 1
elif [ ! -d "$1" ]; then
	printf "ERROR: Unknown PATH argument \'%s\'\n" "$1"
	exit 2
fi
ASSET_LIST_PATH="$1"'/asset_list.txt'
if [ -z "$2" ]; then
	printf "ERROR: Missing ACTION argument\n"
	exit 3
# Update asset textures
elif [ "$2" == "--textures" ]; then
	MATERIALS_DIR="$1"'/textures/material'
	EXPORT_DIR="$1"'/textures/export'
	ASSET_PREFIX="$1"'_road_sign'
	MATERIAL_MAP=('n' 'lod_n')
	if [ "$3" != "--skip-generate" ]; then
		printf "Generating texture materials...\n"
		while IFS="" read -r p || [ -n "$p" ]
		do
			total=${#MATERIAL_MAP[*]}
			for (( i=0; i<=$(( $total -1 )); i++ ))
			do
				SRC="$MATERIALS_DIR"'/'"$ASSET_PREFIX"'_'"${MATERIAL_MAP[$i]}"'.png'
				DEST="$EXPORT_DIR"'/'"$ASSET_PREFIX"'_'"$p"'_'"${MATERIAL_MAP[$i]}"'.png'
				if test -f "$SRC"; then
					cp "$SRC" "$DEST"
					if ! test -f "$DEST"; then
						printf "Failed to generate %s\n" "$DEST"
					fi
				else
					printf "Skipping %s\n" "$SRC"
				fi
			done
		done < "$ASSET_LIST_PATH"
		printf "Finished generating textures\n"
	fi
	printf "Copying texture files to imports...\n"
	find "$EXPORT_DIR" -name '*.png' -exec cp {} "$IMPORT_PATH" \;
	echo "Finished copying files!"
# Update asset models
elif [ "$2" == "--models" ]; then
	cd "$1"'/models/' && bash 'update.sh' "${@:3}"
# Update asset staging area
elif [ "$2" == "--stage" ]; then
	if [ -z "$3" ]; then
		printf "ERROR: Missing ASSET argument\n"
		exit 4
	fi
	SNAP_STAGE_PATH="$GAME_LOCAL_PATH/Snapshots"
	ASSET_STAGE_PATH="$GAME_LOCAL_PATH/AssetStagingArea"
	THUMB_EXPORT_PATH="$1"'/thumb/export'
	SNAPSHOT_EXPORT_PATH="$1"'/snapshot/export'
	find "$SNAP_STAGE_PATH" -printf '%T+ %p\n' | sort -r | head  > data.tmp
	while IFS="" read -r p || [ -n "$p" ]
	do
		pattern="Snapshots\/[^\/]*$"
		if [[ "$p" =~ $pattern ]]; then
			pattern2='[[:space:]](.*\/([^\/]+))'
			[[ "$p" =~ $pattern2 ]]
			DEST_PATH="${BASH_REMATCH[1]}"
			if [[ ! -z "$DEST_PATH" ]]; then
				printf "Copying asset %s to %s\n" "$3" "${BASH_REMATCH[2]}"
				cp -a ./"$SNAPSHOT_EXPORT_PATH"'/'"$3"/*.png "$DEST_PATH"/
				break
			fi
		fi
	done < data.tmp
	find "$ASSET_STAGE_PATH" -printf '%T+ %p\n' | sort -r | head  > data.tmp
	while IFS="" read -r p || [ -n "$p" ]
	do
		pattern="AssetStagingArea\/[^\/]*$"
		if [[ "$p" =~ $pattern ]]; then
			pattern2='[[:space:]](.*\/([^\/]+))'
			[[ "$p" =~ $pattern2 ]]
			DEST_PATH="${BASH_REMATCH[1]}"
			if [[ ! -z "$DEST_PATH" ]]; then
				printf "Copying asset %s to %s\n" "$3" "${BASH_REMATCH[2]}"
				cp -a ./"$THUMB_EXPORT_PATH"'/'"$3"/*.png "$DEST_PATH"/
				break
			fi
		fi
	done < data.tmp
	rm -f data.tmp
else
	printf "ERROR: Unknown ACTION argument \'%s\'\n" "$2"
fi
