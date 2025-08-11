#!/usr/bin/env bash

PARTS_DIR="Parts"
SOURCE_DIR="Source"
DEFAULT_CHUNK_MB=90

# Colors
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
MAGENTA=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)

print_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}
   ____                                ____  _                    
  / ___|__ _ _ __ ___  _ __  _   _ ___/ ___|| |__   __ _ _ __ ___ 
 | |   / _\` | '_ \` _ \| '_ \| | | / __\___ \| '_ \ / _\` | '__/ _ \\
 | |__| (_| | | | | | | |_) | |_| \__ \___) | | | | (_| | | |  __/
  \____\__,_|_| |_| |_| .__/ \__,_|___/____/|_| |_|\__,_|_|  \___|
                      |_|                                         
${RESET}"
}

format_size() {
    local bytes=$1
    local units=(B KB MB GB TB)
    local i=0
    while (( bytes >= 1024 && i < 4 )); do
        bytes=$(( bytes / 1024 ))
        ((i++))
    done
    echo "${bytes} ${units[$i]}"
}

get_folder_path() {
    local default_folder="$1"
    local folder_path

    if [ -d "$default_folder" ]; then
        folder_path="$default_folder"
    else
        echo "Default folder '$default_folder' not found."
        read -rp "Enter full path to the folder: " folder_path
        if [ ! -d "$folder_path" ]; then
            echo "${RED}❌ Folder does not exist. Exiting.${RESET}"
            exit 1
        fi
    fi

    echo "$folder_path"
}

split_folder() {
    # Get source folder (where original files are)
    local source_folder
    source_folder=$(get_folder_path "$SOURCE_DIR")

    # Confirm or create Parts folder (where parts go)
    if [ -d "$PARTS_DIR" ]; then
        if [ "$(ls -A "$PARTS_DIR")" ]; then
            read -rp "⚠️  '$PARTS_DIR' is not empty. Overwrite? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo "${RED}❌ Split cancelled.${RESET}"
                return
            fi
            rm -rf "$PARTS_DIR"
        fi
    fi
    mkdir -p "$PARTS_DIR"

    # Get chunk size
    read -rp "Chunk size in MB (default $DEFAULT_CHUNK_MB): " chunk_mb
    chunk_mb=${chunk_mb:-$DEFAULT_CHUNK_MB}
    chunk_size_bytes=$((chunk_mb * 1024 * 1024))

    local total_size=0
    local total_parts=0

    for file in "$source_folder"/*; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file")
            # split with suffix length 4 (partaa, partab, ...)
            split -b "$chunk_size_bytes" -d --additional-suffix=".part" "$file" "$PARTS_DIR/${base_name}.part"
            file_size=$(stat -c%s "$file")
            total_size=$((total_size + file_size))
        fi
    done

    total_parts=$(ls "$PARTS_DIR" | wc -l)
    echo -e "✅ ${GREEN}Split complete${RESET}: $total_parts parts created in '${PARTS_DIR}'"
    echo "📦 Total size processed: $(format_size "$total_size")"
}

join_parts() {
    # Get parts folder (where parts are)
    local parts_folder
    parts_folder=$(get_folder_path "$PARTS_DIR")

    if [ ! "$(ls -A "$parts_folder")" ]; then
        echo "${RED}❌ No part files found in '$parts_folder'.${RESET}"
        return
    fi

    # Confirm or create Source folder (where joined files go)
    if [ -d "$SOURCE_DIR" ]; then
        if [ "$(ls -A "$SOURCE_DIR")" ]; then
            read -rp "⚠️  '$SOURCE_DIR' folder is not empty. Overwrite files if duplicates? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo "${RED}❌ Merge cancelled.${RESET}"
                return
            fi
        fi
    else
        mkdir -p "$SOURCE_DIR"
    fi

    # Find unique base filenames before ".part"
    base_names=$(ls "$parts_folder" | sed -E 's/(.+)\.part.*/\1/' | sort -u)

    for base in $base_names; do
        output_file="$SOURCE_DIR/$base"
        if [ -f "$output_file" ]; then
            read -rp "⚠️  '$output_file' exists. Overwrite? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo "${YELLOW}Skipping $base${RESET}"
                continue
            fi
        fi

        cat "$parts_folder"/"$base".part* > "$output_file"
        size=$(stat -c%s "$output_file")
        echo -e "✅ ${GREEN}Merged${RESET}: $base → '$SOURCE_DIR' ($(format_size "$size"))"
    done
}

show_menu() {
    local options=("Split contents of Source folder" "Merge parts from Parts folder" "Exit")
    local selected=0
    local key

    while true; do
        print_banner
        echo "${BOLD}${CYAN}Use ↑ and ↓ arrows, Enter to select${RESET}"
        echo
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo " ${CYAN}> ${options[$i]}${RESET}"
            else
                echo "   ${options[$i]}"
            fi
        done

        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key == "[A" ]]; then
                ((selected--))
                ((selected<0)) && selected=$((${#options[@]} - 1))
            elif [[ $key == "[B" ]]; then
                ((selected++))
                ((selected>=${#options[@]})) && selected=0
            fi
        elif [[ $key == "" ]]; then
            case $selected in
                0) split_folder ;;
                1) join_parts ;;
                2) echo "👋 Goodbye!"; exit 0 ;;
            esac
            echo -e "\nPress Enter to return to menu..."
            read
        fi
    done
}

show_menu
