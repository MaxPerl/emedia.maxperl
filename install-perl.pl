#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

my ($BUILD_DIR, $INSTALL_DIR) = @ARGV;

print "INSTALLING perl to $INSTALL_DIR\n\n";
chdir ($BUILD_DIR);
print "Download and extract perl\n";
system("wget https://www.cpan.org/src/5.0/perl-5.38.2.tar.gz");
system("wget https://github.com/arsv/perl-cross/releases/download/1.6.4/perl-cross-1.6.4.tar.gz");
system("tar xvf perl-5.38.2.tar.gz");

chdir("perl-5.38.2");
system("tar --strip-components=1 -zxf ../perl-cross-1.6.4.tar.gz");
system("./configure --target=aarch64-linux-gnu --prefix=/opt/click.ubuntu.com/emedia.maxperl/current -Dusethreads -Duseshrplib -Dmksymlinks -Duselargefiles");
system("make"); 
system("env DESTDIR=\"${INSTALL_DIR}\" make install");

print "Installing pEFL"