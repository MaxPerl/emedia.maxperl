#! /usr/bin/perl
use strict;
use warnings;

use lib("./perl5");

use pEFL::Evas;
use pEFL::Elm;
use pEFL::Elm::App;
use pEFL::Emotion;

use vKbd;

use File::Path qw(make_path remove_tree);

use ContentHub;

use IPC::Run qw(run);

my $info = 0;

#########################################
# APP INFORMATION
my $app_name = "emedia.maxperl";
my $app_title = "emedia";
my $app_version = "1.0.1";
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
	chmod 0700, "$app_cache/run";
}

if (! -e "$app_cache/imported_files") {
	make_path("$app_cache/imported_files") or die "Path creation failed: $!\n";
}

my $win; my $video; my $nav; my $vkbd; my $player;

# Check for Content Hub
my $content_hub = ContentHub->new(app_id => "$app_name"."_$app_title"."_$app_version",
	on_import_cb => \&_look_for_imports);
my $open_file = "";
my ($transfer_id, $path) = $content_hub->get_hub_transfer();
if ($path) {
	$open_file = $content_hub->import_path($path);
}

pEFL::Elm::init($#ARGV, \@ARGV);
pEFL::Elm::App::name_set($app_name);

pEFL::Elm::Config::profile_set("mobile");
if ($ENV{QTWEBKIT_DPR}) {
	my $scale = $ENV{QTWEBKIT_DPR} * 1.6;
	pEFL::Elm::Config::scale_set($scale);
}
elsif ($ENV{GRID_UNIT_PX}) {
	my $scale = $ENV{GRID_UNIT_PX} * 1.6 / 10;
	pEFL::Elm::Config::scale_set($scale);	
}
else {
	pEFL::Elm::Config::scale_set(3.2);
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
$content_hub->on_import_data($video);

if ($open_file) {
	$video->file_set($open_file);
	$video->play();
} 

#######################################################
# Important: We have to make the app fullscreen!!!!
######################################################
my ($x, $y, $w, $h) = $win->screen_size_get();
$win->resize($w,$h);
$win->maximized_set(1);

$content_hub->init();

pEFL::Elm::run();

pEFL::Elm::shutdown();

remove_tree("$app_cache/imported_files") or die "Could not remove imported files: $!\n";

sub _look_for_imports {
	my ($content_hub, $path, $video) = @_;
	
	$video->stop();
		
	my $new_file =  $content_hub->import_path($path);		
			
	$video->file_set("$new_file");
	$video->play();
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
	$btn->smart_callback_add("clicked"=>\&_open_import_helper, $nav);
	my $it = $nav->item_push("Player",undef,$btn,$player,undef);
	
	return $video;
	
}

sub _open_import_helper {
	my ($nav) = @_;
	my @cmd = ("qmlscene", "ImportPage.qml");
	
	my $in; my $out; my $err;
	run(\@cmd, \$in, \$out, \$err);
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
