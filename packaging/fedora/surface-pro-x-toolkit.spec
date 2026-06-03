Name:           surface-pro-x-toolkit
Version:        0.1.0
Release:        1%{?dist}
Summary:        Starter tooling for Surface Pro X Linux enablement
License:        MIT
BuildArch:      noarch

%description
Starter documentation and scripts for building and validating Linux images for
the Microsoft Surface Pro X.

%prep

%build

%install
mkdir -p %{buildroot}%{_datadir}/surface-pro-x-linux-docs
cp -a %{spx_repo_root}/README.md %{buildroot}%{_datadir}/surface-pro-x-linux-docs/
cp -a %{spx_repo_root}/LICENSE %{buildroot}%{_datadir}/surface-pro-x-linux-docs/
cp -a %{spx_repo_root}/Makefile %{buildroot}%{_datadir}/surface-pro-x-linux-docs/
cp -a %{spx_repo_root}/config %{buildroot}%{_datadir}/surface-pro-x-linux-docs/
cp -a %{spx_repo_root}/docs %{buildroot}%{_datadir}/surface-pro-x-linux-docs/
cp -a %{spx_repo_root}/scripts %{buildroot}%{_datadir}/surface-pro-x-linux-docs/
cp -a %{spx_repo_root}/tests %{buildroot}%{_datadir}/surface-pro-x-linux-docs/

%files
%license %{_datadir}/surface-pro-x-linux-docs/LICENSE
%{_datadir}/surface-pro-x-linux-docs

%changelog
* Wed Jun 03 2026 tjbmoose09 <tjbmoose09@users.noreply.github.com> - 0.1.0-1
- Initial starter toolkit package.
