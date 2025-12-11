#!/usr/bin/env bash
#
# menu.sh - Menu Framework for Ultimate Linux Suite
#
# Provides unified menu interface using dialog, whiptail, or text fallback
#

# Prevent multiple sourcing
[[ -n "${_MENU_SH_LOADED:-}" ]] && return 0
readonly _MENU_SH_LOADED=1

# Menu system configuration
declare -g MENU_BACKEND=""  # dialog, whiptail, or text
declare -g MENU_TITLE="Ultimate Linux Suite"
declare -g MENU_BACKTITLE="$MENU_TITLE"
declare -g MENU_WIDTH=70
declare -g MENU_HEIGHT=20
declare -g MENU_LIST_HEIGHT=12

# Detect available menu backend
menu_init() {
    if have_cmd dialog; then
        MENU_BACKEND="dialog"
    elif have_cmd whiptail; then
        MENU_BACKEND="whiptail"
    else
        MENU_BACKEND="text"
    fi

    log_debug "Menu backend: $MENU_BACKEND"
}

# Set menu title
menu_set_title() {
    MENU_TITLE="$1"
    MENU_BACKTITLE="$1"
}

# Display a message box
# Arguments:
#   $1 - Title
#   $2 - Message
message_box() {
    local title="$1"
    local message="$2"

    case "$MENU_BACKEND" in
        dialog)
            dialog --backtitle "$MENU_BACKTITLE" \
                   --title "$title" \
                   --msgbox "$message" \
                   $MENU_HEIGHT $MENU_WIDTH
            ;;
        whiptail)
            whiptail --backtitle "$MENU_BACKTITLE" \
                     --title "$title" \
                     --msgbox "$message" \
                     $MENU_HEIGHT $MENU_WIDTH
            ;;
        text)
            echo ""
            echo "=== $title ==="
            echo ""
            echo "$message"
            echo ""
            read -r -p "Press Enter to continue..."
            ;;
    esac
}

# Display an info box (no wait)
# Arguments:
#   $1 - Title
#   $2 - Message
info_box() {
    local title="$1"
    local message="$2"

    case "$MENU_BACKEND" in
        dialog)
            dialog --backtitle "$MENU_BACKTITLE" \
                   --title "$title" \
                   --infobox "$message" \
                   8 $MENU_WIDTH
            ;;
        whiptail)
            whiptail --backtitle "$MENU_BACKTITLE" \
                     --title "$title" \
                     --infobox "$message" \
                     8 $MENU_WIDTH
            ;;
        text)
            echo "[$title] $message"
            ;;
    esac
}

# Yes/No prompt
# Arguments:
#   $1 - Title
#   $2 - Question
# Returns: 0 for yes, 1 for no
yes_no_prompt() {
    local title="$1"
    local question="$2"

    case "$MENU_BACKEND" in
        dialog)
            dialog --backtitle "$MENU_BACKTITLE" \
                   --title "$title" \
                   --yesno "$question" \
                   10 $MENU_WIDTH
            return $?
            ;;
        whiptail)
            whiptail --backtitle "$MENU_BACKTITLE" \
                     --title "$title" \
                     --yesno "$question" \
                     10 $MENU_WIDTH
            return $?
            ;;
        text)
            echo ""
            echo "=== $title ==="
            echo ""
            echo "$question"
            echo ""
            read -r -p "Continue? [y/N]: " response
            [[ "${response,,}" =~ ^y(es)?$ ]]
            return $?
            ;;
    esac
}

# Input box
# Arguments:
#   $1 - Title
#   $2 - Prompt
#   $3 - Default value (optional)
# Returns: User input via stdout
input_box() {
    local title="$1"
    local prompt="$2"
    local default="${3:-}"
    local result

    case "$MENU_BACKEND" in
        dialog)
            result=$(dialog --backtitle "$MENU_BACKTITLE" \
                           --title "$title" \
                           --inputbox "$prompt" \
                           10 $MENU_WIDTH "$default" \
                           3>&1 1>&2 2>&3)
            echo "$result"
            ;;
        whiptail)
            result=$(whiptail --backtitle "$MENU_BACKTITLE" \
                             --title "$title" \
                             --inputbox "$prompt" \
                             10 $MENU_WIDTH "$default" \
                             3>&1 1>&2 2>&3)
            echo "$result"
            ;;
        text)
            echo ""
            echo "=== $title ==="
            echo ""
            if [[ -n "$default" ]]; then
                read -r -p "$prompt [$default]: " result
                echo "${result:-$default}"
            else
                read -r -p "$prompt: " result
                echo "$result"
            fi
            ;;
    esac
}

# Display a menu and return selection
# Arguments:
#   $1 - Title
#   $2 - Prompt text
#   $3... - Menu items as "tag" "description" pairs
# Returns: Selected tag via stdout, exit code 1 if cancelled
menu_select() {
    local title="$1"
    local prompt="$2"
    shift 2
    local items=("$@")
    local result

    case "$MENU_BACKEND" in
        dialog)
            result=$(dialog --backtitle "$MENU_BACKTITLE" \
                           --title "$title" \
                           --menu "$prompt" \
                           $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
                           "${items[@]}" \
                           3>&1 1>&2 2>&3)
            local exit_code=$?
            echo "$result"
            return $exit_code
            ;;
        whiptail)
            result=$(whiptail --backtitle "$MENU_BACKTITLE" \
                             --title "$title" \
                             --menu "$prompt" \
                             $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
                             "${items[@]}" \
                             3>&1 1>&2 2>&3)
            local exit_code=$?
            echo "$result"
            return $exit_code
            ;;
        text)
            _text_menu "$title" "$prompt" "${items[@]}"
            return $?
            ;;
    esac
}

# Text-based menu fallback
# Arguments:
#   $1 - Title
#   $2 - Prompt
#   $3... - Items as tag/description pairs
_text_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    local items=("$@")
    local count=0
    local tags=()

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    printf "║  %-62s  ║\n" "$title"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"

    # Display menu items
    while [[ ${#items[@]} -gt 0 ]]; do
        local tag="${items[0]}"
        local desc="${items[1]}"
        items=("${items[@]:2}")

        ((count++))
        tags+=("$tag")
        printf "║  %2d) %-58s  ║\n" "$count" "$desc"
    done

    echo "║                                                                ║"
    printf "║   0) %-58s  ║\n" "Cancel / Back"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "$prompt"
    echo ""

    local choice
    read -r -p "Enter selection [0-$count]: " choice

    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return 1
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        echo "${tags[$((choice-1))]}"
        return 0
    fi

    return 1
}

# Checklist (multiple selection)
# Arguments:
#   $1 - Title
#   $2 - Prompt
#   $3... - Items as "tag" "description" "status" triplets
# Returns: Space-separated selected tags via stdout
menu_checklist() {
    local title="$1"
    local prompt="$2"
    shift 2
    local items=("$@")
    local result

    case "$MENU_BACKEND" in
        dialog)
            result=$(dialog --backtitle "$MENU_BACKTITLE" \
                           --title "$title" \
                           --checklist "$prompt" \
                           $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
                           "${items[@]}" \
                           3>&1 1>&2 2>&3)
            local exit_code=$?
            echo "$result"
            return $exit_code
            ;;
        whiptail)
            result=$(whiptail --backtitle "$MENU_BACKTITLE" \
                             --title "$title" \
                             --checklist "$prompt" \
                             $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
                             "${items[@]}" \
                             3>&1 1>&2 2>&3)
            local exit_code=$?
            echo "$result"
            return $exit_code
            ;;
        text)
            _text_checklist "$title" "$prompt" "${items[@]}"
            return $?
            ;;
    esac
}

# Text-based checklist fallback
_text_checklist() {
    local title="$1"
    local prompt="$2"
    shift 2
    local items=("$@")
    local -a tags=()
    local -a descs=()
    local -a selected=()
    local count=0

    # Parse items
    while [[ ${#items[@]} -gt 0 ]]; do
        tags+=("${items[0]}")
        descs+=("${items[1]}")
        if [[ "${items[2]}" == "on" ]]; then
            selected+=("1")
        else
            selected+=("0")
        fi
        items=("${items[@]:3}")
        ((count++))
    done

    while true; do
        echo ""
        echo "=== $title ==="
        echo ""

        for ((i=0; i<count; i++)); do
            local mark=" "
            [[ "${selected[$i]}" == "1" ]] && mark="*"
            printf "  %2d) [%s] %s\n" $((i+1)) "$mark" "${descs[$i]}"
        done

        echo ""
        echo "  0) Done"
        echo ""
        echo "$prompt"
        echo "Toggle selection by entering the number"
        echo ""

        local choice
        read -r -p "Selection: " choice

        if [[ "$choice" == "0" ]]; then
            local result=""
            for ((i=0; i<count; i++)); do
                if [[ "${selected[$i]}" == "1" ]]; then
                    result+="${tags[$i]} "
                fi
            done
            echo "${result% }"
            return 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
            local idx=$((choice-1))
            if [[ "${selected[$idx]}" == "1" ]]; then
                selected[$idx]="0"
            else
                selected[$idx]="1"
            fi
        fi
    done
}

# Progress gauge
# Arguments:
#   $1 - Title
#   $2 - Initial percentage
# Reads percentage updates from stdin until 100 or EOF
progress_gauge() {
    local title="$1"
    local percent="${2:-0}"

    case "$MENU_BACKEND" in
        dialog)
            dialog --backtitle "$MENU_BACKTITLE" \
                   --title "$title" \
                   --gauge "Processing..." \
                   8 $MENU_WIDTH "$percent"
            ;;
        whiptail)
            whiptail --backtitle "$MENU_BACKTITLE" \
                     --title "$title" \
                     --gauge "Processing..." \
                     8 $MENU_WIDTH "$percent"
            ;;
        text)
            local line
            while read -r line; do
                printf "\r[%-50s] %3d%%" \
                    "$(printf '#%.0s' $(seq 1 $((line/2))))" \
                    "$line"
            done
            echo ""
            ;;
    esac
}

# Display a text file
# Arguments:
#   $1 - Title
#   $2 - File path
textbox() {
    local title="$1"
    local file="$2"

    case "$MENU_BACKEND" in
        dialog)
            dialog --backtitle "$MENU_BACKTITLE" \
                   --title "$title" \
                   --textbox "$file" \
                   $MENU_HEIGHT $MENU_WIDTH
            ;;
        whiptail)
            whiptail --backtitle "$MENU_BACKTITLE" \
                     --title "$title" \
                     --textbox "$file" \
                     $MENU_HEIGHT $MENU_WIDTH
            ;;
        text)
            echo ""
            echo "=== $title ==="
            echo ""
            cat "$file"
            echo ""
            read -r -p "Press Enter to continue..."
            ;;
    esac
}

# Clear screen
menu_clear() {
    case "$MENU_BACKEND" in
        dialog|whiptail)
            clear
            ;;
        text)
            printf '\033c'
            ;;
    esac
}

# Show a wait/processing screen
# Arguments:
#   $1 - Message
show_wait() {
    local message="$1"
    info_box "Please Wait" "$message"
}

# Password input
# Arguments:
#   $1 - Title
#   $2 - Prompt
# Returns: Password via stdout
password_box() {
    local title="$1"
    local prompt="$2"
    local result

    case "$MENU_BACKEND" in
        dialog)
            result=$(dialog --backtitle "$MENU_BACKTITLE" \
                           --title "$title" \
                           --insecure \
                           --passwordbox "$prompt" \
                           10 $MENU_WIDTH \
                           3>&1 1>&2 2>&3)
            echo "$result"
            ;;
        whiptail)
            result=$(whiptail --backtitle "$MENU_BACKTITLE" \
                             --title "$title" \
                             --passwordbox "$prompt" \
                             10 $MENU_WIDTH \
                             3>&1 1>&2 2>&3)
            echo "$result"
            ;;
        text)
            echo ""
            echo "=== $title ==="
            echo ""
            read -r -s -p "$prompt: " result
            echo ""
            echo "$result"
            ;;
    esac
}

# Radiolist (single selection from marked items)
# Arguments:
#   $1 - Title
#   $2 - Prompt
#   $3... - Items as "tag" "description" "status" triplets
# Returns: Selected tag via stdout
menu_radiolist() {
    local title="$1"
    local prompt="$2"
    shift 2
    local items=("$@")
    local result

    case "$MENU_BACKEND" in
        dialog)
            result=$(dialog --backtitle "$MENU_BACKTITLE" \
                           --title "$title" \
                           --radiolist "$prompt" \
                           $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
                           "${items[@]}" \
                           3>&1 1>&2 2>&3)
            local exit_code=$?
            echo "$result"
            return $exit_code
            ;;
        whiptail)
            result=$(whiptail --backtitle "$MENU_BACKTITLE" \
                             --title "$title" \
                             --radiolist "$prompt" \
                             $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
                             "${items[@]}" \
                             3>&1 1>&2 2>&3)
            local exit_code=$?
            echo "$result"
            return $exit_code
            ;;
        text)
            # For text mode, convert to simple menu
            local simple_items=()
            while [[ ${#items[@]} -gt 0 ]]; do
                simple_items+=("${items[0]}" "${items[1]}")
                items=("${items[@]:3}")
            done
            _text_menu "$title" "$prompt" "${simple_items[@]}"
            return $?
            ;;
    esac
}
