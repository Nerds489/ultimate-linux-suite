#compdef ultimate-suite
# Zsh completion for ultimate-suite
# Ultimate Linux Suite

_ultimate_suite() {
    local -a main_opts optimize_opts apps_opts drivers_opts recovery_opts info_opts

    main_opts=(
        '--help[Show help message]'
        '--version[Show version]'
        '--tui[Start interactive TUI mode]'
        '--cli[Use command-line mode]'
        '--optimize[System optimization]:optimization mode:->optimize'
        '--apps[Application management]:apps command:->apps'
        '--drivers[Driver management]:drivers command:->drivers'
        '--recovery[Recovery tools]:recovery command:->recovery'
        '--info[System information]:info command:->info'
        '--config[Configuration]:config option:->config'
    )

    optimize_opts=(
        'auto:Automatic optimization based on hardware'
        'desktop:Desktop workstation profile'
        'server:Server optimization profile'
        'laptop:Laptop/power-saving profile'
        'vm:Virtual machine profile'
        'gaming:Gaming performance profile'
        'minimal:Minimal changes profile'
        'custom:Custom optimization'
    )

    apps_opts=(
        'install:Install applications'
        'remove:Remove applications'
        'search:Search for applications'
        'list:List installed applications'
        'presets:Install application presets'
        'queue:Manage installation queue'
    )

    drivers_opts=(
        'detect:Detect hardware and drivers'
        'auto:Auto-install recommended drivers'
        'install:Install specific driver'
        'remove:Remove driver'
        'dkms:DKMS module management'
        'vault:Driver vault management'
    )

    recovery_opts=(
        'health:System health check'
        'repair:Repair tools'
        'backup:Backup system'
        'restore:Restore from backup'
        'bootloader:Bootloader tools'
        'network:Network repair'
    )

    info_opts=(
        'hardware:Hardware information'
        'system:System information'
        'packages:Package information'
    )

    _arguments -C \
        '1: :->command' \
        '*:: :->args'

    case $state in
        command)
            _describe -t commands 'ultimate-suite commands' main_opts
            ;;
        args)
            case $words[1] in
                --optimize|-o)
                    _describe -t optimize 'optimization modes' optimize_opts
                    ;;
                --apps|-a)
                    _describe -t apps 'apps commands' apps_opts
                    ;;
                --drivers|-d)
                    _describe -t drivers 'drivers commands' drivers_opts
                    ;;
                --recovery|-r)
                    _describe -t recovery 'recovery commands' recovery_opts
                    ;;
                --info|-i)
                    _describe -t info 'info commands' info_opts
                    ;;
                install)
                    local -a applications
                    applications=(
                        'firefox:Mozilla Firefox browser'
                        'chromium:Chromium browser'
                        'vlc:VLC media player'
                        'gimp:GNU Image Manipulation Program'
                        'inkscape:Vector graphics editor'
                        'blender:3D creation suite'
                        'kdenlive:Video editor'
                        'obs-studio:Open Broadcaster Software'
                        'steam:Steam gaming platform'
                        'lutris:Game manager'
                        'vscode:Visual Studio Code'
                    )
                    _describe -t applications 'applications' applications
                    ;;
                presets)
                    local -a presets
                    presets=(
                        'minimal:Essential utilities'
                        'developer:Development tools'
                        'creator:Content creation tools'
                        'gaming:Gaming applications'
                        'office:Office productivity'
                        'server:Server utilities'
                    )
                    _describe -t presets 'presets' presets
                    ;;
                backup)
                    local -a backup_opts
                    backup_opts=(
                        'config:Backup configurations'
                        'packages:Backup package list'
                        'system:Backup system files'
                        'grub:Backup GRUB config'
                        'list:List backups'
                    )
                    _describe -t backup 'backup options' backup_opts
                    ;;
                restore)
                    # Complete backup files
                    local backup_dir="${HOME}/.suite-backups"
                    if [[ -d "$backup_dir" ]]; then
                        _files -g '*.(tar.gz|txt)' -W "$backup_dir"
                    fi
                    ;;
                repair)
                    local -a repair_opts
                    repair_opts=(
                        'packages:Repair package manager'
                        'initramfs:Regenerate initramfs'
                        'dkms:Rebuild DKMS modules'
                        'permissions:Fix permissions'
                    )
                    _describe -t repair 'repair options' repair_opts
                    ;;
                dkms)
                    local -a dkms_opts
                    dkms_opts=(
                        'list:List DKMS modules'
                        'rebuild:Rebuild all modules'
                        'status:Show DKMS status'
                    )
                    _describe -t dkms 'dkms options' dkms_opts
                    ;;
                bootloader)
                    local -a boot_opts
                    boot_opts=(
                        'status:Check bootloader status'
                        'update:Update GRUB config'
                        'reinstall:Reinstall GRUB'
                        'backup:Backup GRUB config'
                    )
                    _describe -t bootloader 'bootloader options' boot_opts
                    ;;
                network)
                    local -a net_opts
                    net_opts=(
                        'status:Network status'
                        'repair:Full network repair'
                        'restart:Restart network'
                        'dns:Flush DNS cache'
                    )
                    _describe -t network 'network options' net_opts
                    ;;
            esac
            ;;
    esac
}

_ultimate_suite "$@"
