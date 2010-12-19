package I18N::Handle::Locale;
use warnings;
use strict;
use base qw(Locale::Maketext);
use Locale::Maketext::Lexicon ();

our $loaded;

my $DynamicLH;

sub new {
    my $class = shift;
    my $args = shift || {};
    my $self = bless { } , $class;
    return $self if $loaded;

    $loaded++;

    Locale::Maketext::Lexicon->import({

        # '*' => [Gettext => 'locale/*/LC_MESSAGES/hello.mo'],
        # '*' => [Gettext => 'locale/*/LC_MESSAGES/hello.mo'],
        # 'zh-tw' => [ Gettext => 'po/zh_TW.po' ],
        # 'en' => [ Gettext => 'po/en.po' ],

        _auto   => 1,
        _decode => 1,
        _preload => 1,
        _style  => 'gettext',

        %$args,
    });
    $self->init;

    return $self;
}

sub init {
    my $self = shift;
    my $lh = $self->get_handle( );
    $DynamicLH = \$lh; 
}

sub get_dynamicLH { return $DynamicLH; }

sub speak {
    my ( $self, $lang ) = @_;
    $$DynamicLH = $self->get_handle($lang ? $lang : ()) if $DynamicLH;
    # warn $$DynamicLH; # get I18N::Handle::Locale::zh_tw,en ...
}

1;
