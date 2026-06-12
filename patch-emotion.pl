#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use File::Copy;

my ($ROOT, $BUILD_DIR, $INSTALL_DIR) = @ARGV;

print "Patch Emotion so that mp4 is played without syncing and so without laggs\n";
print "Copy $ROOT/patch-emotion.patch to $BUILD_DIR/efl-1.28.1/src/modules/emotion/gstreamer1/patch-emotion.patch\n"; 
copy("$ROOT/patch-emotion.patch", "$BUILD_DIR/efl-1.28.1/src/modules/emotion/gstreamer1/patch-emotion.patch") or die "Copy failed: $!";
chdir ("$BUILD_DIR/efl-1.28.1/src/modules/emotion/gstreamer1/");

print "Patching emotion\n";
system("patch -N -i ./patch-emotion.patch");