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
Summary(ru_RU.UTF-8): NetSDS-SMPPD2 - это

License: GPL

Group: Networking/Other
Url: http://www.netstyle.com.ua/

Packager: Dmitriy Kruglikov <dkr@netstyle.com.ua>

BuildArch: noarch
Source0: %module-%version.tar

BuildRequires: perl-libwww

# Automatically added by buildreq on Mon Mar 08 2010 (-bi)
BuildRequires: perl-CGI perl-HTML-Template-Pro perl-JSON perl-JSON-XS perl-Locale-gettext

Requires:  perl-NetSDS

%description
NetSDS-SMPPD2 is an 

%description -l ru_RU.UTF-8
NetSDS-SMPPD2 - это 

%add_findreq_skiplist */*template*/*pl

%prep
%setup -q -n %m_distro-%version

%build
%perl_vendor_build

%install
%perl_vendor_install

%pre

%files
%perl_vendor_privlib/NetSDS*
#%doc NetSDS-SMPPD2/doc/*

%changelog
* Mon Oct 17 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 2.101-alt1
- Initial build
