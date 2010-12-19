package I18N::Handle;
use warnings;
use strict;
use Moose;
use I18N::Handle::Base;
use File::Find::Rule;
use Locale::Maketext::Lexicon ();

our $VERSION = '0.01';

has base => ( is => 'rw' );

has accept_langs => (
    is => 'rw',
    isa => 'ArrayRef',
    traits => [ 'Array' ],
    handles => { 
        'add_accept' => 'push',
        'accepted' => 'elements'
    },
    default => sub { [] } );

has langs => ( 
    is => 'rw' , 
    isa => 'ArrayRef' , 
    traits => [ 'Array' ],
    handles => { 
        add_lang => 'push',
        can_speak => 'elements'
    },
    default => sub { [] }
    );  # can speaks

has current => ( is => 'rw' );  # current language

our $singleton;

sub BUILDARGS {
    my $self = shift;
    my %args = @_;
    return \%args;
}

sub BUILD {
    my $self = shift;
    my %args = %{ +shift };

    my %import;
    if( $args{po} ) {
        # XXX: check po for ref
        $args{po} = ( ref $args{po} eq 'ARRAY' ) ? $args{po} : [ $args{po} ];

        my %langs = $self->_scan_po_files( $args{po} );

        # $self->{_langs} = [ keys %langs ];

        $self->add_lang( keys %langs );

        %import = ( %import, %langs );
    }

    if( $args{locale} ) {
        $args{locale} = ( ref $args{po} eq 'ARRAY' ) ? $args{locale} : [ $args{locale} ];
        my %langs = $self->_scan_locale_files( $args{locale} );

        # $self->{_langs} = [ keys %langs ];

        $self->add_lang( keys %langs );

        %import = ( %import, %langs );
    }

    %import = ( %import, %{ $args{import} } ) if( $args{import} );

    for my $format ( qw(Gettext Msgcat Slurp Tie) ) {
        next unless $args{ $format };
        my $list = $args{ $format };
        while ( my ($tag,$arg) = each %$list ) {

            $tag = $self->_unify_langtag( $tag );

            if ( ! ref $arg ) {
                $import{ $tag } = [ $format => $arg ]
            }
            elsif ( ref $arg eq 'ARRAY' ) {
                $import{ $tag } = [ map { $format => $_ } @$arg ]
            }

            # push @{ $self->{_langs} }, $self->_unify_langtag( $tag );
            $self->add_lang( $tag );
        }
    }

    $import{_style} = $args{style} if( $args{style} );

    $self->base( I18N::Handle::Base->new( \%import ) );
    $self->base->init;

    my $loc_name = $args{'loc'} || '_';

    __PACKAGE__->install_global_loc( $loc_name , $self->base->get_dynamicLH );
    return $self;
}

sub singleton {
    my ($class,%args) = @_;
    return $singleton ||= $class->new( %args );
}

# translate zh_TW => zh-tw
# see Locale::Maketext , 
#      ·   $lh = YourProjClass->get_handle( ...langtags... ) || die "lg-handle?";
#          This tries loading classes based on the language-tags you give (like "("en-US", "sk", "kon", "es-MX", "ja", "i-klingon")",
#          and for the first class that succeeds, returns YourProjClass::language->new().

sub _unify_langtag {
    my ($self,$tag) = @_;
    $tag =~ tr<_A-Z><-a-z>; # lc, and turn _ to -
    $tag =~ tr<-a-z0-9><>cd;  # remove all but a-z0-9-
    return $tag;
}

sub _scan_po_files {
    my ($self,$dir) = @_;
    my @files = File::Find::Rule->file->name("*.po")->in(@$dir);
    my %langs;
    for my $file ( @files ) {
        my ($tag) = ($file =~ m{([a-z]{2}(?:_[a-zA-Z]{2})?)\.po$}i );
        $langs{ $self->_unify_langtag($tag )  } = [ Gettext => $file ];
    }
    return %langs;
}

sub _scan_locale_files {
    my ($self,$dir) = @_;
    my @files = File::Find::Rule->file->name("*.mo")->in( @$dir );
    my %langs;
    for my $file ( @files ) {
        my ($tag) = ($file =~ m{([a-z]{2}(?:_[a-zA-Z]{2})?)/LC_MESSAGES/}i );
        $langs{ $self->_unify_langtag($tag )  } = [ Gettext => $file ];
    }
    return %langs;
}

sub speak {
    my ($self,$lang) = @_;
    if( grep { $lang eq $_ } $self->can_speak ) {
        $self->current( $lang );
        $self->base->speak( $lang );
    }
}

sub accept {
    my ($self,@langs) = @_;
    for my $lang ( map { $self->_unify_langtag( $_ ) } @langs ) { 
        if( grep { $lang eq $_ } $self->can_speak ) {
            $self->add_accept( $lang );
        } else {
            warn "Not accept language $lang..";
        }
    }
    return $self;
}


sub install_global_loc {
    my ($class, $loc_name , $dlh) = @_;

    my $loc_method = sub {

        # Retain compatibility with people using "-e _" etc.
        return \*_ unless @_; # Needed for perl 5.8

        # When $_[0] is undef, return undef.  When it is '', return ''.
        no warnings 'uninitialized';
        return $_[0] unless (length $_[0]);

        local $@;
        # Force stringification to stop Locale::Maketext from choking on
        # things like DateTime objects.
        my @stringified_args = map {"$_"} @_;
        my $result = eval { ${$dlh}->maketext(@stringified_args) };
        if ($@) {
            warn $@;
            # Sometimes Locale::Maketext fails to localize a string and throws
            # an exception instead.  In that case, we just return the input.
            return join(' ', @stringified_args);
        }
        return $result;
    };

    {
        no strict 'refs';
        no warnings 'redefine';
        # *_ = $loc_method;
        *{ '::'.$loc_name } = $loc_method;
    }
}


__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

I18N::Handle - A common i18n handler for web frameworks and applications.

=head1 ***THIS MODULE IS STILL IN DEVELOPMENT***

=head1 DESCRIPTION

L<I18N::Handle> is a common handler for web frameworks and applications.

You can use L<App::I18N> to generate po/mo files, then use this module 

to handle these languages.

=head1 SYNOPSIS

Ideas are welcome. just drop me a line.

option C<import> takes the same arguments as L<Locale::Maketext::Lexicon> takes.
it's I<language> => [ I<format> => I<source> ].
    
    use I18N::Handle;
    my $handle = I18N::Handle->new( 
                import => {
                        en => [ Gettext => 'po/en.po' ],
                        fr => [ Gettext => 'po/fr.po' ],
                        jp => [ Gettext => 'po/jp.po' ],
                })->accept( qw(en fr) )->speak( 'en' );

Or a simple way to import gettext po files:
This will transform the args to the args that C<import> option takes:

    use I18N::Handle;
    my $handle = I18N::Handle->new( 
                Gettext => {
                        en => 'po/en.po',
                        fr => 'po/fr.po',
                        jp => [ 'po/jp.po' , 'po2/jp.po' ],
                })->accept( qw(en fr) )->speak( 'en' );


    print _('Hello world');

    $handle->speak( 'fr' );
    $handle->speak( 'jp' );
    $handle->speaking;  # return 'jp'

    my @langs = $handle->can_speak();  # return 'en', 'fr', 'jp'

or

    $handle = I18N::Handle->new( 
            po => 'path/to/po',
            style => 'gettext'          # use gettext style format (default)
                )->speak( 'en' );

    print _('Hello world');





If you need to bind the locale directory structure like this:

    po/en/LC_MESSAGES/app.po
    po/en/LC_MESSAGES/app.mo
    po/zh_tw/LC_MESSAGES/app.po
    po/zh_tw/LC_MESSAGES/app.mo

You can just pass the C<locale> option:

    $handle = I18N::Handle->new(
            locale => 'path/to/locale'
            )->speak( 'en_US' );





If you need a singleton L<I18N::Handle>, this is a helper function to return
the singleton object:

    $hl = I18N::Handle->singleton( locale => 'path/to/locale' );




Connect to a translation server:

    $handle = I18N::Handle->new( 
            server => 'translate.me' )->speak( 'en_US' );

Connect to a database:

    $handle = I18N::Handle->new(
            dsn => 'DBI:mysql:database=$database;host=$hostname;port=$port;'
            );

Connect to google translation:

    $handle = I18N::Handle->new( google => "" );


=head1 OPTIONS

=over 4 

=item I<format> => { I<language> => I<source> , ... }

Format could be I<Gettext | Msgcat | Slurp | Tie>.

    use I18N::Handle;
    my $hl = I18N::Handle->new( 
                Gettext => {
                        en => 'po/en.po',
                        fr => 'po/fr.po',
                        jp => [ 'po/jp.po' , 'po2/jp.po' ],
                });
    $hl->speak( 'en' );

=item po => 'I<path>' | [ I<path1> , I<path2> ]

Suppose you have these files:

    po/en.po
    po/zh_TW.po

When using:

    I18N::Handle->new( po => 'po' );

will be found. can you can get these langauges:

    [ en , zh-tw ]

=item locale => 'path' | [ path1 , path2 ]


=item import => Arguments to L<Locale::Maketext::Lexicon>


=back

=head1 OPTIONAL OPTIONS

=over 4

=item style => I<style>  ... (Optional)

The style could be C<gettext>.

=item loc => I<global loc function name>  (Optional)

The default loc function name is C<_>.

=back

=head1 PUBLIC METHODS 

=head2 new

=head2 singleton( I<options> )

If you need a singleton L<I18N::Handle>, this is a helper function to return
the singleton object.

=head2 speak( I<language> )

setup current language. I<language>, can be C<en>, C<fr> and so on..

=head2 speaking()

get current speaking language name.

=head2 can_speak()

return a list that currently supported.

=head2 accept( I<language name list> )

setup accept languages.

    $hl->accpet( qw(en fr) );

=head2 fallback( I<language> )

setup fallback language. when speak() fails , fallback to this language.

    $hl->fallback( 'en' );

=head1 PRIVATE METHODS

=head2 _unify_langtag

=head2 _scan_po_files

=head2 _scan_locale_files

=head1 AUTHOR

Yoan Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<App::I18N>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
