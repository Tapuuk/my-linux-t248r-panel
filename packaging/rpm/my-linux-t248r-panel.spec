# One noarch package for Fedora and openSUSE. Build with `make rpm`.
# No %%{?dist} in Release, because the same file installs on both.

Name:           my-linux-t248r-panel
Version:        0.1.0
Release:        1
Summary:        Set up, test and tune the Thrustmaster T248R racing wheel
License:        MIT AND OFL-1.1 AND Apache-2.0
URL:            https://github.com/Tapuuk/my-linux-t248r-panel
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  make
BuildRequires:  desktop-file-utils

Requires:       python3 >= 3.10
# PySide6 and evdev must come from the same Python. Fedora packages them for python3;
# openSUSE builds PySide6 for a single flavour (python313 today).
Requires:       ((python3dist(pyside6) and python3dist(evdev)) or (python313-pyside6 and python313-evdev) or (python314-pyside6 and python314-evdev))
Requires:       (qt6-qtdeclarative or qt6-declarative-imports)
Requires:       polkit
Requires:       /usr/bin/pkexec
Requires:       git-core
Recommends:     (qt6-qtsvg or libQt6Svg6)

%description
My Linux T248R Panel gets a Thrustmaster T248R racing wheel working on Linux,
force feedback included, and then lets you test and tune it. It installs the
hid-tmff2 driver through DKMS, switches the wheel to PC mode, shows steering,
pedals and buttons live, and tests TH8A/TH8S shifters.

%prep
%setup -q

%build

%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix} LICENSEDIR=%{_datadir}/licenses/%{name}

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/io.github.tapuuk.T248RPanel.desktop

%files
%license %{_datadir}/licenses/%{name}/LICENSE
%{_bindir}/%{name}
%{_prefix}/lib/%{name}/
%{_datadir}/applications/io.github.tapuuk.T248RPanel.desktop
%{_datadir}/icons/hicolor/scalable/apps/io.github.tapuuk.T248RPanel.svg
%{_datadir}/metainfo/io.github.tapuuk.T248RPanel.metainfo.xml
%{_datadir}/polkit-1/actions/io.github.tapuuk.T248RPanel.policy

%changelog
* Sun Oct 25 2026 Tapuuk <tapuuk@users.noreply.github.com> - 0.1.0-1
- First release
