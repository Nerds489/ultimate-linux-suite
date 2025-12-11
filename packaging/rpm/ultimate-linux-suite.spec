Name:           ultimate-linux-suite
Version:        1.0.0
Release:        1%{?dist}
Summary:        Comprehensive Linux system optimization, application management, and recovery toolkit

License:        MIT
URL:            https://github.com/Nerds489/ultimate-linux-suite
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       bash >= 4.0
Requires:       dialog
Requires:       coreutils
Requires:       procps-ng
Requires:       util-linux

Recommends:     pciutils
Recommends:     usbutils
Recommends:     dmidecode
Recommends:     lshw
Recommends:     flatpak

Suggests:       dkms
Suggests:       kernel-devel

%description
Ultimate Linux Suite is a modular, distribution-agnostic toolkit for Linux
system optimization, application management, driver installation, and system
recovery. It provides an interactive text-based interface for managing
various aspects of your Linux system.

Core Features:
* OS detection engine with automatic distribution backend loading
* Hardware detection for CPU, GPU, storage, memory, and network devices
* Interactive TUI menu system powered by dialog

System Optimization:
* Multiple optimization profiles (desktop, server, laptop, gaming, VM)
* Automatic hardware-based optimization recommendations
* Kernel parameter tuning via sysctl
* I/O scheduler optimization for SSDs and HDDs
* CPU governor configuration

Application Management:
* Queue-based batch installation system
* Pre-configured application presets (gaming, developer, creator, minimal)
* Native package manager support (apt, dnf, pacman, zypper)
* Flatpak and Snap integration

Driver Management:
* Realtek USB network adapter support (r8152, r8821cu)
* Broadcom WiFi driver installation
* DKMS kernel module management
* GPU driver guidance for NVIDIA, AMD, and Intel
* Offline driver vault for air-gapped installations

Recovery Tools:
* System health diagnostics
* Package manager repair utilities
* Initramfs and bootloader (GRUB) management
* Network troubleshooting and repair
* Configuration and package list backup/restore

Commands:
* Primary: ultimate-linux-suite
* Alias: ultimate-suite

%prep
%setup -q

%build
# Nothing to build - pure shell scripts

%install
rm -rf %{buildroot}

# Create installation directories
install -d %{buildroot}%{_datadir}/%{name}
install -d %{buildroot}%{_datadir}/%{name}/lib
install -d %{buildroot}%{_datadir}/%{name}/modules
install -d %{buildroot}%{_datadir}/%{name}/menus
install -d %{buildroot}%{_datadir}/%{name}/backends
install -d %{buildroot}%{_datadir}/%{name}/configs
install -d %{buildroot}%{_datadir}/%{name}/drivers
install -d %{buildroot}%{_bindir}
install -d %{buildroot}%{_sysconfdir}/bash_completion.d
install -d %{buildroot}%{_datadir}/zsh/site-functions
install -d %{buildroot}%{_datadir}/fish/vendor_completions.d
install -d %{buildroot}%{_docdir}/%{name}

# Install main script
install -m 755 suite.sh %{buildroot}%{_datadir}/%{name}/suite.sh

# Create primary wrapper: /usr/bin/ultimate-linux-suite
cat > %{buildroot}%{_bindir}/ultimate-linux-suite << 'EOF'
#!/usr/bin/env bash
exec /usr/share/ultimate-linux-suite/suite.sh "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/ultimate-linux-suite

# Create alias wrapper: /usr/bin/ultimate-suite
cat > %{buildroot}%{_bindir}/ultimate-suite << 'EOF'
#!/usr/bin/env bash
exec /usr/bin/ultimate-linux-suite "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/ultimate-suite

# Install library files
install -m 644 lib/*.sh %{buildroot}%{_datadir}/%{name}/lib/

# Install modules
install -m 644 modules/*.sh %{buildroot}%{_datadir}/%{name}/modules/

# Install menus
install -m 644 menus/*.sh %{buildroot}%{_datadir}/%{name}/menus/

# Install backends
install -m 644 backends/*.sh %{buildroot}%{_datadir}/%{name}/backends/

# Install configs
cp -r configs/* %{buildroot}%{_datadir}/%{name}/configs/

# Create driver vault directories
for dir in realtek-r8152 realtek-r8821cu broadcom nvidia amd intel; do
    install -d %{buildroot}%{_datadir}/%{name}/drivers/$dir
done

# Install shell completions for primary command (ultimate-linux-suite)
if [ -f completions/ultimate-linux-suite.bash ]; then
    install -m 644 completions/ultimate-linux-suite.bash \
        %{buildroot}%{_sysconfdir}/bash_completion.d/ultimate-linux-suite
fi
if [ -f completions/ultimate-linux-suite.zsh ]; then
    install -m 644 completions/ultimate-linux-suite.zsh \
        %{buildroot}%{_datadir}/zsh/site-functions/_ultimate-linux-suite
fi
if [ -f completions/ultimate-linux-suite.fish ]; then
    install -m 644 completions/ultimate-linux-suite.fish \
        %{buildroot}%{_datadir}/fish/vendor_completions.d/ultimate-linux-suite.fish
fi

# Install shell completions for alias command (ultimate-suite)
if [ -f completions/ultimate-suite.bash ]; then
    install -m 644 completions/ultimate-suite.bash \
        %{buildroot}%{_sysconfdir}/bash_completion.d/ultimate-suite
fi
if [ -f completions/ultimate-suite.zsh ]; then
    install -m 644 completions/ultimate-suite.zsh \
        %{buildroot}%{_datadir}/zsh/site-functions/_ultimate-suite
fi
if [ -f completions/ultimate-suite.fish ]; then
    install -m 644 completions/ultimate-suite.fish \
        %{buildroot}%{_datadir}/fish/vendor_completions.d/ultimate-suite.fish
fi

# Install documentation
if [ -d docs ]; then
    cp -r docs/* %{buildroot}%{_docdir}/%{name}/
fi

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/ultimate-linux-suite
%{_bindir}/ultimate-suite
%{_datadir}/%{name}/
%config(noreplace) %{_sysconfdir}/bash_completion.d/ultimate-linux-suite
%config(noreplace) %{_sysconfdir}/bash_completion.d/ultimate-suite
%{_datadir}/zsh/site-functions/_ultimate-linux-suite
%{_datadir}/zsh/site-functions/_ultimate-suite
%{_datadir}/fish/vendor_completions.d/ultimate-linux-suite.fish
%{_datadir}/fish/vendor_completions.d/ultimate-suite.fish
%{_docdir}/%{name}/

%post
echo "Ultimate Linux Suite installed successfully."
echo "Run 'ultimate-linux-suite' or 'ultimate-suite' to start."

%changelog
* Wed Dec 11 2024 Nerds489 <support@ultimate-linux-suite.io> - 1.0.0-1
- Version 1.0.0 release
- OS detection engine with automatic backend loading
- Hardware detection (CPU, GPU, storage, memory, network)
- System optimization profiles (desktop, server, laptop, gaming, VM)
- Application installer with queue management and presets
- Flatpak and Snap integration
- Driver management (Realtek, Broadcom, GPU guidance)
- DKMS kernel module management
- Recovery tools (package repair, initramfs, GRUB, network)
- Backup and restore functionality
- Local build system (build.sh, Makefile)
- GitHub Actions packaging workflow
- Shell completions for Bash, Zsh, and Fish
