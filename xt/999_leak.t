#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    if ( !$ENV{TEST_LEAK} ) {
        plan skip_all => "Set TEST_LEAK to run leak tests";
    }
}

use Test::Requires
  'Test::Valgrind',
  'XML::Parser',
  ;

while ( my $f = glob 't/*.t' ) {
    subtest $f => sub { do $f };
}

while ( my $f = glob 't/*.t' ) {
    for my $i ( 1 .. 10 ) {
        subtest $f => sub { do $f };
    }
}

done_testing;
