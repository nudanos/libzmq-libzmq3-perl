# Makefile.PL runs this with do, to name the Module::Install modules a git
# checkout lacks.
package main;

use strict;
use warnings;

# Okay, so some people wanting to check out the latest and greatest
# version from github is getting stuck not knowing what M::I modules
# to install. So do the check here
my @modules = qw(
  inc::Module::Install
  Module::Install::AuthorTests
  Module::Install::CheckLib
  Module::Install::XSUtil
);

my @missing;
foreach my $module (@modules) {
    ( my $file = "$module.pm" ) =~ s{::}{/}gx;
    push @missing, $module if !eval { require $file; 1 };
}
if (@missing) {
    print STDERR <<"EOM";

**** Missing Developer Tools! ****

Whoa there, you don't have the required modules to run this Makefile.PL!
This probably means you cloned the repository from github (if you
encounter this from a tarball uploaded to CPAN, it's a bug, so please
report it).

If you are running from a cloned git repository, install the following
modules first:
EOM
    foreach my $module (@missing) {
        $module =~ s/^inc:://x;
        print STDERR "    * $module\n";
    }
    print STDERR <<"EOM";
and try again.

While you're at it, install these modules as they are needed to run
the tests:

* Test::Fatal
* Test::Requires
* Test::TCP
* Devel::CheckLib

EOM
    exit 0;
}
Module::Install->import;

1;
