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

# For clickable hardcoded pathes are not allowed!
# Important for libertine we have to uncomment this patch :-( very complicated...
print "Patch hardcorded pathes in Perl";
my @files = (
	"$INSTALL_DIR/opt/click.ubuntu.com/emedia.maxperl/current/lib/perl5/5.38.2/aarch64-linux/Config.pm",
	"$INSTALL_DIR/opt/click.ubuntu.com/emedia.maxperl/current/lib/perl5/5.38.2/aarch64-linux/Config_heavy.pl");

foreach my $file (@files) {
	#system("perl -pi.back -e '!\'/opt/click.ubuntu.com/emedia.maxperl/current/!\$ENV{APP_DIR}\.\'!g' $f");
	my $bak_file = $file . ".bak";
	
	rename($file, $bak_file);
	open(my $in, '<' . $bak_file) or die $!;
	open(my $out, '>' . $file) or die $!;
	while(<$in>)
	{
    	$_ =~ s!\'/opt/click.ubuntu.com/emedia.maxperl/current!\$ENV{APP_DIR}\.\'!g;
    	print $out $_;
	}
	close($in);
	close($out);
	unlink($bak_file) or die "Could not delete backup file $bak_file:$!\n";
}

my @del_files = (
	"$INSTALL_DIR/opt/click.ubuntu.com/emedia.maxperl/current/lib/perl5/5.38.2/aarch64-linux/CORE/config.h",
	"$INSTALL_DIR/opt/click.ubuntu.com/emedia.maxperl/current/lib/perl5/5.38.2/aarch64-linux/.packlist"
	);

# CORE/config.h is only necessary for compiling modules, not for running
foreach my $f (@del_files) {
	unlink($f) or die "Could not unlink $f: $!\n";
}
