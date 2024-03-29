use strict;
use warnings;
use open qw( :std :utf8 );

use utf8;
use Test::Mojo;
use Test::More;

package TestApp;

use Unicode::Normalize;
use Mojolicious::Lite;
use Test::More;

get '/' => sub {
    my $self = shift;
    my $name = $self->param( 'name' );
    my $desc = $self->param( 'desc' ) // "$name matches Na\N{U+00EF}ve";
    my $form = $self->param( 'form' ) // 'NFC';
    is $name, Unicode::Normalize->can( $form )->( 'Naïve' ), $desc;
    $self->render( text => 'Okay' );
};

package main;
use Unicode::Normalize;

exit main( @ARGV );

sub main {
    my $t = Test::Mojo->new( 'TestApp' );
    binmode Test::More->builder->output,         ':utf8';
    binmode Test::More->builder->failure_output, ':utf8';

    $t->get_ok( '/', form => { name => "Naïve", desc => 'composed' },
        charset => 'UTF-8')->content_is( 'Okay' );
    $t->get_ok( "/?name=Na\x{ef}ve&desc=single+\\x{}",     charset => 'UTF-8' );
    $t->get_ok( "/?name=Na\N{U+00EF}ve&desc=single+\\N{}", charset => 'UTF-8' );

    $t->get_ok( '/', form => get_form( 'NFC'  ), charset => 'UTF-8' );
    $t->get_ok( '/', form => get_form( 'NFD'  ), charset => 'UTF-8' );
    $t->get_ok( '/', form => get_form( 'NFKC' ), charset => 'UTF-8' );
    $t->get_ok( '/', form => get_form( 'NFKD' ), charset => 'UTF-8' );

    done_testing;
    return 0;
}

sub get_form {
    my $form       = shift;
    my $normalizer = __PACKAGE__->can( $form );
    return {
        name => $normalizer->( "Naïve" ),
        desc => "$form normalizer",
        form => $form,
    };
}
