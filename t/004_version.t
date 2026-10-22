#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok "ZMQ::LibZMQ3";

{
    my $version = ZMQ::LibZMQ3::zmq_version();
    ok $version, "zmq_version returns a version";
    like $version, qr/^\d+\.\d+\.\d+$/x, "dotted version string";

    my ( $major, $minor, $patch ) = ZMQ::LibZMQ3::zmq_version();

    is join( '.', $major, $minor, $patch ), $version, "list and scalar context";
}

done_testing;
