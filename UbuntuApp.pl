# Based on the multimedia tutorial code
# see https://www.enlightenment.org/develop/legacy/tutorial/multimedia_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use lib("./perl5");

use pEFL::Evas;
use pEFL::Elm;
use pEFL::Elm::App;
use pEFL::Emotion;
use Protocol::DBus;
use Protocol::DBus::Client;
use pEFL::Ecore;

use vKbd;

use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);

my $info = 0;

#########################################
# APP INFORMATION
my $app_name = "emedia.maxperl";
my $app_title = "emedia";
my $app_version = "1.0.0";
##########################################

##########################################
# APP DIRECTORIES
my $app_home = "/home/phablet/.local/share/$app_name";
my $app_config = "/home/phablet/.config/$app_name";
my $app_cache = "/home/phablet/.cache/$app_name";
################################################


#######################################################
# Important: We have to create the for efl necessary directories first
######################################################
if (! -e "$app_config/elementary/.config") {
	make_path("$app_config/elementary/.config") or die "Path creation failed: $!\n";
}

if (! -e "$app_cache/.cache/efreet") {
	make_path("$app_cache/.cache/efreet") or die "Path creation failed: $!\n";
}

if (! -e "$app_cache/run") {
	make_path("$app_cache/run") or die "Path creation failed: $!\n";
}

if (! -e "$app_cache/imported_files") {
	make_path("$app_cache/imported_files") or die "Path creation failed: $!\n";
}

if (! -e "/run/user/32011/.cache/efreet") {
	make_path("/run/user/32011/.cache/efreet") or die "Path creation failed: $!\n";
}

my $pid =fork();

if (!defined($pid)) {
	die "Fork fehlgeschlagen: $!\n";
}

my $win; my $video; my $nav; my $vkbd; my $player;

if ($pid ==0) {
	# Later we can here open content hub helpers 
	# For import/export (see Min Browser for example)
	#sleep(1);
	#my $programm = "qmlscene";
	#my $qml_datei = "content_hub.qml";
	
	# Important: Don't use the shell!!
	#exec($program, $qml_datei);
}
else {
# Check for Content Hub
my $open_file = "";
my $path;
if (-d "$app_cache/HubIncoming") {
	opendir(my $dh, "$app_cache/HubIncoming") || die "Can't opendir: $!";
	($path) = grep { !/^\./ &&  -d "$app_cache/HubIncoming/$_" } readdir($dh);
	closedir $dh;
}
if ($path) {
	$open_file = _import_content_hub_dir("$app_cache/HubIncoming/$path");
}


pEFL::Elm::init($#ARGV, \@ARGV);
pEFL::Elm::App::name_set($app_name);

pEFL::Elm::Config::profile_set("mobile");
if ($ENV{QTWEBKIT_DPR}) {
	my $scale = $ENV{QTWEBKIT_DPR} * 1.5;
	pEFL::Elm::Config::scale_set($scale);
}
elsif ($ENV{GRID_UNIT_PX}) {
	my $scale = $ENV{GRID_UNIT_PX} * 1.5 / 10;
	pEFL::Elm::Config::scale_set($scale);	
}
else {
	pEFL::Elm::Config::scale_set(3.0);
}

pEFL::Elm::Theme::overlay_add("./default.edj");

$win = pEFL::Elm::Win->util_standard_add($app_name, $app_name);
$win->show();

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
$win->autodel_set(1);
my $big_box = pEFL::Elm::Box->add($win);
$big_box->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
$big_box->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);

$nav = pEFL::Elm::Naviframe->add($big_box);
$nav->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$nav->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);

$big_box->pack_end($nav);

$vkbd = vKbd->new($big_box);

$win->resize_object_add($big_box);
$nav->show();
$big_box->show();

$video = _push_video($nav);	
if ($open_file) {
	$video->file_set($open_file);
	$video->play();
} 
else {
	_push_fs($nav);
}

#######################################################
# Important: We have to make the app fullscreen!!!!
######################################################
my ($x, $y, $w, $h) = $win->screen_size_get();
$win->resize($w,$h);
$win->maximized_set(1);

if (-e "$app_cache/HubIncoming") {
	my $monitor = pEFL::Ecore::FileMonitor->add(
    	"$app_cache/HubIncoming",
    	\&_look_for_imports,
    	$video
	);
}
else {
	# das HubIncoming Verzeichnis existiert noch nicht.
	# Wir können den FileMonitor erst aktivieren, wenn 
	# es durch den Content Hub erstellt wurd!
	my $monitor = pEFL::Ecore::FileMonitor->add(
    	$app_cache,
    	\&_register_hub_incoming_watcher,
    	$video
	);
}

pEFL::Elm::run();

pEFL::Elm::shutdown();

remove_tree("$app_cache/imported_files") or die "Could not remove imported files: $!\n";

}

sub _register_hub_incoming_watcher {
	my ($video, $monitor_obj, $event, $path) = @_;
	
	# Directory created!!!
	if ($event == 2 && $path eq "$app_cache/HubIncoming") {
		
		# Wir müssen den ersten Import manuell durchführen, weil der File Monitor
		# ja erst nach der Erstellung des HubIncoming Directories (inklusive des ersten
		# Content Hub File exchange startet)
		opendir(my $dh, "$app_cache/HubIncoming") || die "Can't opendir: $!";
		my ($path) = grep { !/^\./ &&  -d "$app_cache/HubIncoming/$_" } readdir($dh);
		closedir $dh;
		
		if ($path) {
			$video->stop();
			my $new_file =  _import_content_hub_dir("$app_cache/HubIncoming/$path");		
			$video->file_set("$new_file");
			$video->play();
		}
		
		my $monitor = pEFL::Ecore::FileMonitor->add(
    	"$app_cache/HubIncoming",
    	\&_look_for_imports,
    	$video # Landet im ersten Argument ($data)
		);
		$monitor_obj->del();
	}
	
}

sub _look_for_imports {
	my ($video, $monitor_obj, $event, $path) = @_;
	
	# Directory created!!!
	if ($event == 2) {
		
		$video->stop();
		my $new_file =  _import_content_hub_dir($path);		
		$video->file_set("$new_file");
		$video->play();
	}
}

sub _import_content_hub_dir {
	my ($path) = @_;
	
	my ($transfer_id) = $path =~ /(\d+)$/;
	
		my $app_id = "$app_name"."_$app_title"."_$app_version";
		
		# Im DBus Path sind Sonderzeichen verboten
		my $encoded_app_id = $app_id;
		$encoded_app_id =~ s/([^a-zA-Z0-9])/sprintf("_%02x", ord($1))/eg;
		my $service   = "com.lomiri.content.dbus.Service";
		my $dbus_path = "/transfers/$encoded_app_id/import";
		my $interface = "com.lomiri.content.dbus.Transfer";
			
		my $dbus = Protocol::DBus::Client::login_session();
		$dbus->initialize();
		
		# Send collect an das DBus Interface
		$dbus->send_call(
    		path => "$dbus_path/$transfer_id",
    		interface => $interface,
    		member => 'Collect',
    		destination => $service,
		);
		
		# Auf Collect folgt wohl keine Antwort!
		#my $msg = $dbus->get_message();
		
		opendir(my $dh, $path) || die "Can't opendir $path: $!";
		my @files = grep { !/^\./ &&  -e "$path/$_" } readdir($dh);
		closedir $dh;
		
		my $file = $files[0];

		my $new_path = "$app_cache/imported_files"; 
		make_path("$new_path/$transfer_id") if (! -e "$new_path/$transfer_id");
		copy("$path/$file", "$new_path/$transfer_id/$file") or die "Copy Hub file to import dir failed: $!";
		
		my $got_response;
		$dbus->send_call(
    		path => "$dbus_path/$transfer_id",
    		interface => $interface,
    		member => 'Finalize',
    		destination => $service
		)->then( sub {
        	$got_response = 1;
    	});
		$dbus->get_message() while !$got_response;
		
		return "$new_path/$transfer_id/$file";
	
}

sub _push_fs {
	my ($nav) = @_;
	
	my $vbox = pEFL::Elm::Box->add($nav);
	$vbox->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$vbox->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
	$vbox->show();

	my $fs = pEFL::Elm::Fileselector->add($nav);
	$fs->style_set("base");
	$fs->expandable_set(0);
	$fs->path_set("/home/phablet/Videos");

	$fs->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$fs->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
	$fs->show();
	$vbox->pack_end($fs);
	
	#my $vkbd = vKbd->new($vbox);
	#$vbox->pack_end($vkbd->elm_box());
	
	my $en1 = $fs->part_content_get("elm.swallow.search");
	$en1->smart_callback_add("clicked" => \&toggle_keyboard, $vkbd);
	
	my $it = $nav->item_push("Select File",undef,undef,$vbox,undef);
	#$it->title_enabled_set(0,0);
	
	$fs->smart_callback_add("done", \&_fs_done, $nav);
	$fs->smart_callback_add("activated", \&_fs_done, $nav);
}

sub _fs_done {

	my ($data, $obj, $ev_info) = @_;
	
	if ($ev_info) {
		my $selected = pEFL::ev_info2s($ev_info);
		$data->item_pop();
		$video->file_set($selected);
		$video->play();
	}
	else {
		$data->item_pop();
	}

}

sub toggle_keyboard {
	my ($vkbd, $object, $ev_info) = @_;
	bless($object,"pEFL::Elm::Entry");
	
	$vkbd->elm_target($object);
	if (!$vkbd->is_visible()) {
		$vkbd->show_keyboard();
	}
}

sub _push_video {
	my ($nav) = @_;
	
	my $video = pEFL::Elm::Video->add($win);
	$video->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$video->show();
    
	$player = pEFL::Elm::Player->add($win);
	
	my $emotion = $video->emotion_get();
	
	$emotion->priority_set(1);
	
	$player->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$player->content_set($video);
	$player->smart_callback_add("info,clicked",\&_player_info_cb,$video);
	$player->smart_callback_add("quality,clicked",\&_player_stop_cb,$video);
	$player->show();

	my $btn = pEFL::Elm::Button->add($nav);
	$btn->text_set("Select File");
	$btn->smart_callback_add("clicked"=>\&_push_fs, $nav);
	my $it = $nav->item_push("Video",undef,$btn,$player,undef);
	
	return $video;
	
}

sub _player_stop_cb {
	my ($video, $obj, $event_info) = @_;
	$video->stop();
}

sub _player_info_cb {
	my ($video, $obj, $event_info) = @_;
	
	my $emotion = $video->emotion_get();
	$info = 1;
	
	my $table = pEFL::Elm::Table->add($obj);
	$table->padding_set(8,8);
	$table->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$table->show();
	
	# display the playing status in label
	my $label = pEFL::Elm::Label->add($table);
	$label->show();
	_player_info_status_update($label,$emotion,undef);
	$table->pack($label,0,0,2,1);
	$emotion->smart_callback_add("playback_finished", \&_player_info_status_update,$label);
	
	# * get the file name and location
	# set the file label
	my $flabel = pEFL::Elm::Label->add($table);
	$flabel->text_set("File:");
	$flabel->show();
	$table->pack($flabel,0,1,1,1);
	
	# set the file name label
	my $fname = $emotion->file_get();
	my $fnlabel = pEFL::Elm::Label->add($table);
	$fnlabel->text_set($fname);
	$fnlabel->show();
	$table->pack($fnlabel,1,1,1,1);
	
	# TODO: PATH LABEL
	
	# * get video position and duration
	# set time label
	my $tlabel = pEFL::Elm::Label->add($table);
	$tlabel->text_set("Time:");
	$tlabel->show();
	$table->pack($tlabel,0,3,1,1);
	
	# set position-duration label
	my $pdlabel = pEFL::Elm::Label->add($table);
	my $position = $video->play_position_get();
	my $duration = $video->play_length_get();
	
	my $psec = $position % 60;
	my $pmin = $position / 60;
	my $phour = $position / 3600;
	my $dsec = $duration % 60;
	my $dmin = $duration / 60;
	my $dhour = $duration / 3600;
	
	$pdlabel->text_set(sprintf("%02d:%02d:%02d / %02d:%02d:%02d", $phour,$pmin,$psec,$dhour,$dmin,$dsec));
	$table->pack($pdlabel,1,3,1,1);
	$pdlabel->show();
	
	$emotion->smart_callback_add("position_update",\&_player_info_time_update,$pdlabel);
	$emotion->smart_callback_add("length_change",\&_player_info_time_update,$pdlabel);
	
	# get the video dimensions
	my $dlabel = pEFL::Elm::Label->add($table);
	$dlabel->text_set("Size: ");
	$dlabel->show();
	$table->pack($dlabel, 0,4,1,1);
	
	my $dimlabel = pEFL::Elm::Label->add($table);
	my ($w,$h) = $emotion->size_get();
	$dimlabel->text_set("$w x $h");
	$dimlabel->show();
	$table->pack($dimlabel,1,4,1,1);
	
	# push info in a seperate naviframe item
	my $it = $nav->item_push("Information",undef,undef,$table,undef);
	$it->pop_cb_set(\&_player_info_del_cb, undef)
	
}

sub _player_info_status_update {
	my ($label, $emotion, $event_info) = @_;
	
	# switch on main item
	if (!$info) {
		$emotion->smart_callback_del("playback_finished", \&_player_info_status_update);
		return;
	}
	
	# update
	my $position = $emotion->position_get();
	my $duration = $emotion->play_length_get();
	
	if ($emotion->play_get()) {
		$label->text_set("<b>Playing</b>");
	}
	elsif ($position < $duration) {
		$label->text_set("<b>Paused</b>");
	}
	else {
		$label->text_set("<b>Ended</b>");
	}
	
}

sub _player_info_time_update {
	my ($label, $emotion, $event_info) = @_;
	
	# switch on main item
	if (!$info) {
		$emotion->smart_callback_del("position_update",\&_player_info_time_update);
		$emotion->smart_callback_del("length_change",\&_player_info_time_update);
		return;
	}
	else {
	# update
		my $position = $emotion->position_get();
		my $duration = $emotion->play_length_get();
	
		my $psec = $position % 60;
		my $pmin = $position / 60;
		my $phour = $position / 3600;
		my $dsec = $duration % 60;
		my $dmin = $duration / 60;
		my $dhour = $duration / 3600;
	
		$label->text_set(sprintf("%02d:%02d:%02d / %02d:%02d:%02d", $phour,$pmin,$psec,$dhour,$dmin,$dsec));
	}
}

sub _player_info_del_cb {
	my ($data, $it) = @_;

	$info = 0;
	return 1;
}
