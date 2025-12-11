Name:           ultimate-linux-suite
Version:        1.0.0
Release:        1%{?dist}
Summary:        Comprehensive Linux system optimization and management toolkit

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
Ultimate Linux Suite is a modular, distribution-agnostic toolkit for
Linux system optimization, application management, driver installation,
and system recovery.

Features include:
* Multi-distribution support (Debian, Ubuntu, Fedora, Arch, openSUSE)
* Hardware detection and optimization
* System performance tuning
* Application installation with queue management
* Driver management (Realtek, Broadcom, GPU guidance)
* System recovery and repair tools
* Backup and restore functionality

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
- Initial release
- Core system optimization engine
- Multi-distribution support
- Hardware detection and profiling
- System performance tuning
- Application installer with queue management
- Flatpak and Snap integration
- Driver management for Realtek and Broadcom
- GPU driver guidance
- DKMS module management
- System recovery and repair tools
- Package manager repair utilities
- Initramfs regeneration support
- Bootloader management
- Network repair tools
- System health checks
- Backup and restore functionality
