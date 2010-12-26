#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 2;
use I18N::Handle;

$h = I18N::Handle->new( po => 't/i18n/po' , no_install_loc => 1);
ok( $h );

$m = *{ "::_" };
ok( $m );
