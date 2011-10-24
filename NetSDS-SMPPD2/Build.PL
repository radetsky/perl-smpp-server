#!/usr/bin/env perl

=head1 NAME

Build.PL - Build script generator for NetSDS SMPPD V2 service

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings 'all';

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'NetSDS::SMPPD2',
	dist_name          => 'NetSDS-SMPPD2',
	dist_abstract      => 'NetSDS SMPP daemon V2',
	dist_version       => '2.0',
	create_makefile_pl => 'traditional',
	dist_author        => 'Net.Style Development Team <info@netstyle.com.ua>',
	create_readme      => 1,
	license            => 'gpl',
	build_requires     => {},
	requires           => {
		'perl'        => '5.008',
		'version'     => '0.700',
		'NetSDS::App' => '0',
		'Net::SMPP'   => '0',
	},
	script_files => [
		'smppdc',
		'smppdstat',
	],
);

$build->create_build_script;

__END__

=head1 AUTHOR

Alex Radetsky  <rad@netstyle.com.ua>

=cut
