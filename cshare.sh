#!/usr/bin/env bash

PARTS_DIR="Parts"
SOURCE_DIR="Source"
CHUNK_SIZE_MB=25    # change 25 to whatever size you want

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
    local source_folder
    source_folder=$(get_folder_path "$SOURCE_DIR")

    if [ ! -d "$source_folder" ]; then
        echo "${RED}❌ Source folder does not exist.${RESET}"
        exit 1
    fi

    # Prepare parts folder
    if [ -d "$PARTS_DIR" ]; then
        if [ "$(ls -A "$PARTS_DIR")" ]; then
            read -rp "⚠️  '$PARTS_DIR' is not empty. Overwrite? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo "${RED}❌ Split cancelled.${RESET}"
                exit 0
            fi
            rm -rf "$PARTS_DIR"
        fi
    fi
    mkdir -p "$PARTS_DIR"

    local chunk_size_bytes=$((CHUNK_SIZE_MB * 1024 * 1024))
    local total_size=0

    # Recursively split all files
    find "$source_folder" -type f | while read -r file; do
        rel_path="${file#$source_folder/}"
        out_dir="$PARTS_DIR/$(dirname "$rel_path")"
        mkdir -p "$out_dir"
        split -b "$chunk_size_bytes" -d --additional-suffix=.part "$file" "$out_dir/$(basename "$file").part"
        file_size=$(stat -c%s "$file")
        total_size=$((total_size + file_size))
    done

    total_parts=$(find "$PARTS_DIR" -type f | wc -l)
    echo -e "✅ ${GREEN}Split complete${RESET}: $total_parts parts created in '${PARTS_DIR}'"
    echo "📦 Total size processed: $(format_size "$total_size")"
    exit 0
}

join_parts() {
    local parts_folder
    parts_folder=$(get_folder_path "$PARTS_DIR")

    if [ ! -d "$parts_folder" ]; then
        echo "${RED}❌ Parts folder does not exist.${RESET}"
        exit 1
    fi

    # Prepare output folder
    if [ -d "$SOURCE_DIR" ]; then
        if [ "$(ls -A "$SOURCE_DIR")" ]; then
            read -rp "⚠️  '$SOURCE_DIR' folder is not empty. Overwrite? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo "${RED}❌ Merge cancelled.${RESET}"
                exit 0
            fi
            rm -rf "$SOURCE_DIR"
        fi
    fi
    mkdir -p "$SOURCE_DIR"

    # Find all unique base file paths
    mapfile -t base_files < <(find "$parts_folder" -type f -name "*.part" | sed -E 's/\.part[0-9]+\.part$//' | sort -u)

    for base in "${base_files[@]}"; do
        rel_path="${base#$parts_folder/}"
        mkdir -p "$SOURCE_DIR/$(dirname "$rel_path")"

        # THIS IS THE CORRECTED, ROBUST COMMAND FOR MERGING
        # It now correctly handles spaces and other special characters in filenames.
        find "$parts_folder" -type f -name "$(basename "$base").part*.part" -print0 | sort -zV | xargs -0 cat > "$SOURCE_DIR/$rel_path"

        size=$(stat -c%s "$SOURCE_DIR/$rel_path")
        echo -e "🔄 Reconstructed: $rel_path ($(format_size "$size"))"
    done

    echo -e "✅ ${GREEN}Merge complete${RESET}: files restored to '$SOURCE_DIR'"
    exit 0
}

show_menu() {
    local options=("Split contents of source folder" "Merge parts from parts folder" "Exit")
    local selected=0
    local key

    while true; do
        print_banner
        echo "${BOLD}${CYAN}Use ↑ and ↓ arrows, Enter to select${RESET}"
        echo
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo " ${CYAN}● ${options[$i]}${RESET}"
            else
                echo " ○ ${options[$i]}"
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
        fi
    done
}

show_menu
