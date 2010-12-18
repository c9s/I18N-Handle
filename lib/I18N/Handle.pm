package I18N::Handle;
use strict;
use warnings;
our $VERSION = '0.01';

1;
__END__

=head1 NAME

I18N::Handle - A common i18n handler for web frameworks and applications.

=head1 SYNOPSIS

***This module is under-developing***

    use I18N::Handle;
    
    my $handle = I18N::Handle->new( 
            en => 'po/en.po', 
            fr => 'po/fr.po',
            jp => 'po/jp.po'
                )->accept( qw(en fr) )->speak( 'en' );

    print _('Hello world');

    $handle->speak( 'fr' );
    $handle->speak( 'jp' );


or

    $handle = I18N::Handle->new( 
            po => 'path/to/po'
                )->speak( 'en' );

    print _('Hello world');


or 

    $handle = I18N::Handle->new(
            locale => 'path/to/locale'
            )->speak( 'en_US' );


Connect to a translation server:

    $handle = I18N::Handle->new( 
            server => 'translate.me' )->speak( 'en_US' );

Connect to a database:

    $handle = I18N::Handle->new(
            dsn => 'DBI:mysql:database=$database;host=$hostname;port=$port;'
            );

Connect to google translation:

    $handle = I18N::Handle->new( google => "" );

=head1 DESCRIPTION

L<I18N::Handle> is a common handler for web frameworks and applications.

=head1 AUTHOR

Yoan Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
