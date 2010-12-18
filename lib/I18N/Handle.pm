package I18N::Handle;
use warnings;
use strict;
use Moose;
use I18N::Handle::Base;
use File::Find::Rule;
use Locale::Maketext::Lexicon ();

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
    $self->base->speak( $lang );
    # $$DynamicLH = $self->get_handle($lang ? $lang : ()) if $DynamicLH;
}

sub accept {
    my ($self,@langs) = @_;
    for my $lang ( map { $self->_unify_langtag( $_ ) } @langs ) { 
        if( grep { $lang eq $_ } $self->can_speak ) {
            $self->add_accept( $lang );
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


# __PACKAGE__->meta->make_immutable();
1;
__END__

=head1 NAME

I18N::Handle - A common i18n handler for web frameworks and applications.

=head1 SYNOPSIS

***This module is under-developing***

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


=head1 OPTIONS

=for 4 

=item I<Gettext | Msgcat | Slurp | Tie> => {  language => source , ... }

=item po => 'path' | [ path1 , path2 ]

=item locale => 'path' | [ path1 , path2 ]

=item import => Arguments to L<Locale::Maketext::Lexicon>

=back

=head1 OPTIONAL OPTIONS

=for 4

=item style => 'gettext'  ... (Optional)

=item loc => 'global loc function name'  (Optional)

=back


=head1 PUBLIC METHODS 

=head2 new

=head2 speak

=head2 speaking

=head2 can_speak

=head2 accept

=head2 fallback

=head1 PRIVATE METHODS





=head1 AUTHOR

Yoan Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
