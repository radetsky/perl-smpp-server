# This is spec file for common NetSDS frameworks

%define module NetSDS-SMPPD2
%define m_distro NetSDS-SMPPD2
%define m_name NetSDS::SMPPD2
%define _enable_test 1
%def_without test


Name: NetSDS-SMPPD2
Version: 2.101
Release: alt1

Summary: NetSDS-SMPPD2 - is an 

License: GPL

Group: Networking/Other
Url: http://www.netstyle.com.ua/

Packager: Dmitriy Kruglikov <dkr@netstyle.com.ua>

BuildArch: noarch
Source0: %module-%version.tar


# Automatically added by buildreq on Mon Mar 08 2010 (-bi)
BuildRequires: perl-libwww 
BuildRequires: perl-NetSDS
BuildRequires: perl-CGI 
BuildRequires: perl-HTML-Template-Pro 
BuildRequires: perl-JSON 
BuildRequires: perl-JSON-XS 
BuildRequires: perl-Locale-gettext
BuildRequires: perl-Module-Build

Requires: perl-libwww 
Requires: perl-NetSDS
Requires: monit-base

%description
NetSDS-SMPPD2 is an 

%package contrib
Summary: contrib files and scripts for NetSDS SMPP server
Group: Networking/Other
Requires: %name = %version-%release

%description contrib
%summary


%add_findreq_skiplist */*template*/*pl

%prep
%setup -q -n %m_distro-%version

%build
%perl_vendor_build

%install
%perl_vendor_install
mkdir -p %buildroot%_sbindir
mkdir -p %buildroot%_initdir
mkdir -p %buildroot%_sysconfdir/{monit.d,NetSDS}
mkdir -p %buildroot%_datadir/NetSDS/smppserver
install -m 755 smppserver %buildroot%_sbindir/smppserver
install -m 755 smppserver_safe_start.sh %buildroot%_sbindir/smppserver_safe_start.sh
install -m 755 smppserver.init %buildroot%_initdir/smppserver
install -m 755 smppserver.monit %buildroot%_sysconfdir/monit.d/smppserver
install -m 640 smppserver.conf %buildroot%_sysconfdir/NetSDS/smppserver.conf
cp -r contrib %buildroot%_datadir/NetSDS/smppserver
cp -r sql %buildroot%_datadir/NetSDS/smppserver

%post
%post_service smppserver

%preun
%preun_service smppserver

%files
%perl_vendor_privlib/NetSDS*
%_sbindir/smppserver
%_sbindir/smppserver_safe_start.sh
%_bindir/*
%_datadir/NetSDS/smppserver/sql
%config(noreplace) %_sysconfdir/NetSDS/smppserver.conf
%config(noreplace) %_initdir/smppserver
%config(noreplace) %_sysconfdir/monit.d/smppserver
%doc doc/*

%files contrib
%_datadir/NetSDS/smppserver/contrib

%changelog
* Mon Oct 17 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 2.101-alt1
- Initial build
