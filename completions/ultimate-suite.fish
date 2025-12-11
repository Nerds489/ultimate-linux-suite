# Fish completion for ultimate-suite
# Ultimate Linux Suite

# Disable file completions
complete -c ultimate-suite -f

# Main options
complete -c ultimate-suite -l help -d 'Show help message'
complete -c ultimate-suite -l version -d 'Show version'
complete -c ultimate-suite -l tui -d 'Start interactive TUI mode'
complete -c ultimate-suite -l cli -d 'Use command-line mode'
complete -c ultimate-suite -l optimize -d 'System optimization'
complete -c ultimate-suite -l apps -d 'Application management'
complete -c ultimate-suite -l drivers -d 'Driver management'
complete -c ultimate-suite -l recovery -d 'Recovery tools'
complete -c ultimate-suite -l info -d 'System information'
complete -c ultimate-suite -l config -d 'Configuration'

# Optimization modes
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'auto' -d 'Automatic optimization'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'desktop' -d 'Desktop profile'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'server' -d 'Server profile'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'laptop' -d 'Laptop profile'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'vm' -d 'Virtual machine profile'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'gaming' -d 'Gaming profile'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'minimal' -d 'Minimal changes'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --optimize' -a 'custom' -d 'Custom optimization'

# Apps commands
complete -c ultimate-suite -n '__fish_seen_subcommand_from --apps' -a 'install' -d 'Install applications'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --apps' -a 'remove' -d 'Remove applications'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --apps' -a 'search' -d 'Search applications'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --apps' -a 'list' -d 'List installed'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --apps' -a 'presets' -d 'Application presets'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --apps' -a 'queue' -d 'Installation queue'

# Drivers commands
complete -c ultimate-suite -n '__fish_seen_subcommand_from --drivers' -a 'detect' -d 'Detect hardware'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --drivers' -a 'auto' -d 'Auto-install drivers'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --drivers' -a 'install' -d 'Install driver'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --drivers' -a 'remove' -d 'Remove driver'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --drivers' -a 'dkms' -d 'DKMS management'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --drivers' -a 'vault' -d 'Driver vault'

# Recovery commands
complete -c ultimate-suite -n '__fish_seen_subcommand_from --recovery' -a 'health' -d 'Health check'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --recovery' -a 'repair' -d 'Repair tools'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --recovery' -a 'backup' -d 'Backup system'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --recovery' -a 'restore' -d 'Restore backup'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --recovery' -a 'bootloader' -d 'Bootloader tools'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --recovery' -a 'network' -d 'Network repair'

# Info commands
complete -c ultimate-suite -n '__fish_seen_subcommand_from --info' -a 'hardware' -d 'Hardware info'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --info' -a 'system' -d 'System info'
complete -c ultimate-suite -n '__fish_seen_subcommand_from --info' -a 'packages' -d 'Package info'

# Application presets
complete -c ultimate-suite -n '__fish_seen_subcommand_from presets' -a 'minimal' -d 'Essential utilities'
complete -c ultimate-suite -n '__fish_seen_subcommand_from presets' -a 'developer' -d 'Development tools'
complete -c ultimate-suite -n '__fish_seen_subcommand_from presets' -a 'creator' -d 'Content creation'
complete -c ultimate-suite -n '__fish_seen_subcommand_from presets' -a 'gaming' -d 'Gaming applications'
complete -c ultimate-suite -n '__fish_seen_subcommand_from presets' -a 'office' -d 'Office productivity'
complete -c ultimate-suite -n '__fish_seen_subcommand_from presets' -a 'server' -d 'Server utilities'

# Backup subcommands
complete -c ultimate-suite -n '__fish_seen_subcommand_from backup' -a 'config' -d 'Backup configurations'
complete -c ultimate-suite -n '__fish_seen_subcommand_from backup' -a 'packages' -d 'Backup package list'
complete -c ultimate-suite -n '__fish_seen_subcommand_from backup' -a 'system' -d 'Backup system files'
complete -c ultimate-suite -n '__fish_seen_subcommand_from backup' -a 'grub' -d 'Backup GRUB config'
complete -c ultimate-suite -n '__fish_seen_subcommand_from backup' -a 'list' -d 'List backups'

# Repair subcommands
complete -c ultimate-suite -n '__fish_seen_subcommand_from repair' -a 'packages' -d 'Repair package manager'
complete -c ultimate-suite -n '__fish_seen_subcommand_from repair' -a 'initramfs' -d 'Regenerate initramfs'
complete -c ultimate-suite -n '__fish_seen_subcommand_from repair' -a 'dkms' -d 'Rebuild DKMS'
complete -c ultimate-suite -n '__fish_seen_subcommand_from repair' -a 'permissions' -d 'Fix permissions'

# DKMS subcommands
complete -c ultimate-suite -n '__fish_seen_subcommand_from dkms' -a 'list' -d 'List modules'
complete -c ultimate-suite -n '__fish_seen_subcommand_from dkms' -a 'rebuild' -d 'Rebuild modules'
complete -c ultimate-suite -n '__fish_seen_subcommand_from dkms' -a 'status' -d 'Show status'

# Bootloader subcommands
complete -c ultimate-suite -n '__fish_seen_subcommand_from bootloader' -a 'status' -d 'Check status'
complete -c ultimate-suite -n '__fish_seen_subcommand_from bootloader' -a 'update' -d 'Update config'
complete -c ultimate-suite -n '__fish_seen_subcommand_from bootloader' -a 'reinstall' -d 'Reinstall GRUB'
complete -c ultimate-suite -n '__fish_seen_subcommand_from bootloader' -a 'backup' -d 'Backup config'

# Network subcommands
complete -c ultimate-suite -n '__fish_seen_subcommand_from network' -a 'status' -d 'Network status'
complete -c ultimate-suite -n '__fish_seen_subcommand_from network' -a 'repair' -d 'Full repair'
complete -c ultimate-suite -n '__fish_seen_subcommand_from network' -a 'restart' -d 'Restart services'
complete -c ultimate-suite -n '__fish_seen_subcommand_from network' -a 'dns' -d 'Flush DNS cache'

# Common applications for install command
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'firefox' -d 'Mozilla Firefox'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'chromium' -d 'Chromium browser'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'vlc' -d 'VLC media player'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'gimp' -d 'GNU Image Manipulation'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'inkscape' -d 'Vector graphics'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'blender' -d '3D creation suite'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'kdenlive' -d 'Video editor'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'obs-studio' -d 'Streaming/recording'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'steam' -d 'Gaming platform'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'lutris' -d 'Game manager'
complete -c ultimate-suite -n '__fish_seen_subcommand_from install' -a 'vscode' -d 'Visual Studio Code'
