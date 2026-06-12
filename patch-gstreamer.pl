#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use File::Copy;

my ($ROOT, $BUILD_DIR, $INSTALL_DIR) = @ARGV;

print "Patch gstreamer\n";
print "Copy $ROOT/patch-gstreamer.patch to $BUILD_DIR/gstreamer-1.24/subprojects/gst-libav/ext/libav/patch-gstreamer.patch\n"; 
copy("$ROOT/patch-gstreamer.patch", "$BUILD_DIR/gstreamer-1.24/subprojects/gst-libav/ext/libav/patch-gstreamer.patch") or die "Copy failed: $!";
chdir ("$BUILD_DIR/gstreamer-1.24/subprojects/gst-libav/ext/libav/");

print "Patching emotion\n";
system("patch -N -i ./patch-gstreamer.patch");