#!/usr/bin/env bash

# campus-share.sh — Large File Splitter/Joiner for University Resources

PARTS_DIR="Parts"
OUTPUT_DIR="Output"
DEFAULT_CHUNK_MB=90

mkdir -p "$PARTS_DIR" "$OUTPUT_DIR"

# Colors
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
MAGENTA=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Banner
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

# Helper: format size
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

# Split function
split_file() {
    if [ "$(ls -A "$PARTS_DIR")" ]; then
        read -p "⚠️  '$PARTS_DIR' is not empty. Overwrite? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "❌ Split cancelled."
            return
        fi
        rm -rf "$PARTS_DIR" && mkdir "$PARTS_DIR"
    fi

    read -p "Enter path to the large file: " file_path
    if [ ! -f "$file_path" ]; then
        echo "❌ File does not exist."
        return
    fi

    read -p "Chunk size in MB (default $DEFAULT_CHUNK_MB): " chunk_mb
    chunk_mb=${chunk_mb:-$DEFAULT_CHUNK_MB}

    chunk_size_bytes=$((chunk_mb * 1024 * 1024))

    split -b "$chunk_size_bytes" "$file_path" "$PARTS_DIR/$(basename "$file_path").part" || {
        echo "❌ Failed to split file."
        return
    }

    total_size=$(stat -c%s "$file_path")
    parts_count=$(ls "$PARTS_DIR" | wc -l)
    echo -e "✅ ${GREEN}Split complete${RESET}: $parts_count parts created in '${PARTS_DIR}'"
    echo "📦 Total size: $(format_size $total_size)"
}

# Join function
join_files() {
    if [ ! "$(ls -A "$PARTS_DIR")" ]; then
        echo "❌ No part files found in '$PARTS_DIR'."
        return
    fi

    read -p "Enter output file name: " output_name
    if [ -z "$output_name" ]; then
        echo "❌ Invalid output name."
        return
    fi

    output_path="$OUTPUT_DIR/$output_name"
    if [ -f "$output_path" ]; then
        read -p "⚠️  '$output_path' exists. Overwrite? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "❌ Join cancelled."
            return
        fi
    fi

    cat "$PARTS_DIR"/* > "$output_path" || {
        echo "❌ Failed to join files."
        return
    }

    total_size=$(stat -c%s "$output_path")
    echo -e "✅ ${GREEN}Join complete${RESET}: '$output_name' created in '${OUTPUT_DIR}'"
    echo "📦 Total size: $(format_size $total_size)"
}

# Menu with arrow keys
show_menu() {
    local options=("Split a file into parts" "Join parts into a single file" "Exit")
    local selected=0
    local key

    while true; do
        print_banner
        echo "${BOLD}${CYAN}Use ↑ and ↓ arrows, Enter to select${RESET}"
        echo
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$selected" ]; then
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
                0) split_file ;;
                1) join_files ;;
                2) echo "👋 Goodbye!"; exit 0 ;;
            esac
            echo -e "\nPress Enter to return to menu..."
            read
        fi
    done
}

show_menu
