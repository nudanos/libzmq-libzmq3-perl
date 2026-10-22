#!/usr/bin/env perl
# Makefile.PL runs this with do: the ZMQ_* values it finds are left in %ENV
# for Makefile.PL, so they are set, not localised.
use strict;
use warnings;
use File::Spec;

## no critic (Variables::RequireLocalizedPunctuationVars) reason: the results are %ENV, for Makefile.PL

# probe env vars first, as you may have wanted to override
# any auto-discoverable values
probe_envvars();
probe_alienzmq();
probe_pkgconfig();

sub probe_envvars {
    print "Probing environment variables:\n";
    my $home = $ENV{ZMQ_HOME};

    if ( !$ENV{ZMQ_INCLUDES} ) {
        my @incpaths;
        if ( $ENV{INCLUDES} ) {
            print " + Detected ZMQ_INCLUDES from INCLUDES (deprecated)...\n";
            push @incpaths, $ENV{INCLUDES};
        }

        if ($home) {
            my $zmq_inc = File::Spec->catdir( $home, 'include' );
            if ( -e $zmq_inc ) {
                print " + Detected ZMQ_INCLUDES from ZMQ_HOME...\n";
                push @incpaths, $zmq_inc;
            }
        }

        if (@incpaths) {
            $ENV{ZMQ_INCLUDES} = join ' ', @incpaths;
        }
    }

    if ( !$ENV{ZMQ_H} ) {
        if ($home) {
            my $zmq_header = File::Spec->catfile( $home, 'include', 'zmq.h' );
            if ( -f $zmq_header ) {
                print " + Detected ZMQ_H from ZMQ_HOME...\n";
                $ENV{ZMQ_H} = $zmq_header;
            }
        }
    }

    if ( !$ENV{ZMQ_LIBS} ) {
        my @libs;
        if ( $ENV{LIBS} ) {
            print " + Detected ZMQ_LIBS from LIBS (deprecated)...\n";
            push @libs, $ENV{LIBS};
        }

        if ($home) {
            my $zmq_lib = File::Spec->catdir( $home, 'lib' );
            if ( -e $zmq_lib ) {
                print " + Detected ZMQ_LIBS from ZMQ_HOME...\n";
                push @libs, sprintf '-L%s', $zmq_lib;
            }
        }

        if (@libs) {
            $ENV{ZMQ_LIBS} = join ' ', @libs;
        }
    }
    return;
}

sub probe_alienzmq {
    if ( !eval { require Alien::ZMQ; 1 } ) {
        print "Alien::ZMQ not found\n";
        return;
    }
    print "Probing libzmq via Alien::ZMQ\n";
    $ENV{ZMQ_H}        ||= File::Spec->catfile( &Alien::ZMQ::inc_dir, "zmq.h" );
    $ENV{ZMQ_INCLUDES} ||= &Alien::ZMQ::inc_dir;
    $ENV{ZMQ_LIBS}     ||= join( " ", &Alien::ZMQ::libs );
    return;
}

# Note: At this point probe_envvars should have taken care merging
# deprecated INCLUDES/LIBS into %ENV
sub probe_pkgconfig {
    my $pkg_config = $ENV{PKGCONFIG_CMD} || 'pkg-config';
    foreach my $pkg (qw(libzmq zeromq3)) {
        print "Probing $pkg via $pkg_config ...\n";
        my $version = command_output("$pkg_config --modversion $pkg");
        chomp $version;
        if ( !$version ) {
            print " - No $pkg found...\n";
            next;
        }

        print " + found $pkg $version\n";

        if ( !$ENV{ZMQ_INCLUDES} ) {
            if ( my $cflags = command_output("$pkg_config --cflags-only-I $pkg") ) {
                chomp $cflags;
                print " + Detected ZMQ_INCLUDES from $pkg_config...\n";
                my @paths = map { s/^-I//xr } split /\s+/x, $cflags;
                $ENV{ZMQ_INCLUDES} = join ' ', @paths;
                if ( !$ENV{ZMQ_H} ) {
                    my $zmq_h = find_zmq_h(@paths);
                    if ($zmq_h) {
                        print " + Detected ZMQ_H from $pkg_config...\n";
                        $ENV{ZMQ_H} = $zmq_h;
                    }
                }
            }
        }

        if ( !$ENV{ZMQ_LIBS} ) {
            if ( my $libs = command_output("$pkg_config --libs $pkg") ) {
                chomp $libs;
                print " + Detected ZMQ_LIBS from $pkg_config...\n";
                $ENV{ZMQ_LIBS} = $libs;
            }
        }

        last;
    }
    return;
}

# the first zmq.h in the include paths
sub find_zmq_h {
    my @paths = @_;
    foreach my $path (@paths) {
        my $zmq_h = File::Spec->catfile( $path, 'zmq.h' );
        return $zmq_h if -f $zmq_h;
    }
    return;
}

# the output of a shell command line (PKGCONFIG_CMD may carry options)
sub command_output {
    my ($cmd) = @_;
    open( my $fh, '-|', $cmd ) or return q{};
    my $out = do { local $/ = undef; <$fh> }
      // q{};
    close $fh;
    return $out;
}
