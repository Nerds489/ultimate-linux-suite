# Bash completion for ultimate-linux-suite
# Ultimate Linux Suite

_ultimate_linux_suite_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands/options
    opts="--help --version --tui --cli --optimize --apps --drivers --recovery --info --config"

    # Subcommands
    local optimize_opts="auto desktop server laptop vm gaming minimal custom"
    local apps_opts="install remove search list presets queue"
    local drivers_opts="detect auto install remove dkms vault"
    local recovery_opts="health repair backup restore bootloader network"
    local info_opts="hardware system packages"

    case "${prev}" in
        ultimate-linux-suite)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        --optimize|-o)
            COMPREPLY=( $(compgen -W "${optimize_opts}" -- ${cur}) )
            return 0
            ;;
        --apps|-a)
            COMPREPLY=( $(compgen -W "${apps_opts}" -- ${cur}) )
            return 0
            ;;
        --drivers|-d)
            COMPREPLY=( $(compgen -W "${drivers_opts}" -- ${cur}) )
            return 0
            ;;
        --recovery|-r)
            COMPREPLY=( $(compgen -W "${recovery_opts}" -- ${cur}) )
            return 0
            ;;
        --info|-i)
            COMPREPLY=( $(compgen -W "${info_opts}" -- ${cur}) )
            return 0
            ;;
        install)
            # Application names for install
            local apps="firefox chromium vlc gimp inkscape blender kdenlive obs-studio steam lutris vscode"
            COMPREPLY=( $(compgen -W "${apps}" -- ${cur}) )
            return 0
            ;;
        presets)
            # Available presets
            local presets="minimal developer creator gaming office server"
            COMPREPLY=( $(compgen -W "${presets}" -- ${cur}) )
            return 0
            ;;
        detect|auto)
            # No additional completions
            return 0
            ;;
        dkms)
            local dkms_opts="list rebuild status"
            COMPREPLY=( $(compgen -W "${dkms_opts}" -- ${cur}) )
            return 0
            ;;
        backup)
            local backup_opts="config packages system grub list"
            COMPREPLY=( $(compgen -W "${backup_opts}" -- ${cur}) )
            return 0
            ;;
        restore)
            # List backup files in ~/.suite-backups
            if [[ -d "$HOME/.suite-backups" ]]; then
                local backups=$(ls -1 "$HOME/.suite-backups" 2>/dev/null | grep -E '\.(tar\.gz|txt)$')
                COMPREPLY=( $(compgen -W "${backups}" -- ${cur}) )
            fi
            return 0
            ;;
        repair)
            local repair_opts="packages initramfs dkms permissions"
            COMPREPLY=( $(compgen -W "${repair_opts}" -- ${cur}) )
            return 0
            ;;
        bootloader)
            local boot_opts="status update reinstall backup"
            COMPREPLY=( $(compgen -W "${boot_opts}" -- ${cur}) )
            return 0
            ;;
        network)
            local net_opts="status repair restart dns"
            COMPREPLY=( $(compgen -W "${net_opts}" -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
    esac
}

complete -F _ultimate_linux_suite_completions ultimate-linux-suite
