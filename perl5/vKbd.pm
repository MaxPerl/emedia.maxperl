package vKbd;

use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);


use pEFL::Elm;
use pEFL::Evas;

our $AUTOLOAD;

sub new {
	my ($class, $box) = @_;
	
	my $layout = {
	
		"letters" => [
				"q","w","e","r","t","z",["u","ü"],"i",["o","ö"],"p", "(X)", "###",
				["a","ä"],"s","d","f","g","h","j","k","l","Del","###",
				"y","x","c","v","b","n","m",",",".", "Enter", "###",
				"Caps","Space", "?123"
		],
		"symbols_1" => [
				"1","2","3","4","5","6","7","8","9","0", "(X)", "###",
				"*","#","+","-","=","(",")","!","?","Del","###",
				"@","~","/","\\","'",";",":","-","_", "Enter", "###",
				"?abc","Space","1/2"
		],
		"symbols_2" => [
				"!", "\"", "§","\$","\%","&","{","[","]","}", "(X)", "###",
				"`","^","|","°","€","<",">","\\","?","Del","###",
				"\@","~","/","\\","'",";",":","-","_", "Enter", "###",
				"?abc","Space","2/2"
		]
	};
	
	# Get index
	my @elm_buttons = ();
	my $obj = {
		elm_buttons => \@elm_buttons,
		elm_box => undef,
		elm_kbd_box => undef,
		elm_parent => $box,
		layout => $layout,
		is_caps => 0,
		is_caps_lock => 0,
		is_symbol1 => 0,
		is_symbol2 => 0,
		is_visible => 0,
		elm_target => "",
		elm_kbd_lines_bxs => []
		};
	
	bless($obj,$class);
	return $obj;
}

######################
# Accessors 
#######################

sub AUTOLOAD {
	my ($self, $newval) = @_;
	
	die("No method $AUTOLOAD implemented\n")
		unless $AUTOLOAD =~m/elm_buttons|elm_box|elm_target|elm_parent|elm_kbd_box|layout|is_caps|is_caps_lock|is_symbol1|is_symbol2|is_visible|elm_kbd_lines_bxs/;
	
	my $attrib = $AUTOLOAD;
	$attrib =~ s/.*://;
	
	my $oldval = $self->{$attrib};
	$self->{$attrib} = $newval if defined($newval);
	
	return $oldval;
}

sub clear_keyboard {
	my ($self) = @_;
	$self->elm_kbd_box()->del();
}

sub show_keyboard {
	my ($self, $layout) = @_;
	$layout = $self->{layout}->{letters} if (!defined($layout));
	my $box = $self->elm_parent();
	
	my $keyboard_box = pEFL::Elm::Box->add($box);
	$keyboard_box->size_hint_weight_set(EVAS_HINT_EXPAND, 0.3);
	$keyboard_box->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
	$self->elm_kbd_box($keyboard_box);
	
	$self->_add_keys($layout);
	
	$self->is_visible(1);
	$box->pack_end($keyboard_box); $keyboard_box->show();
}

sub hide_keyboard {
	my ($vkbd) = @_;
	
	$vkbd->elm_kbd_box()->del();
	$vkbd->is_visible(0);	
}

sub toggle_keyboard {
	my ($vkbd) = @_;
	if ($vkbd->is_visible() == 1 ){
		$vkbd->hide_keyboard();
	}
	else {
		$vkbd->show_keyboard();	
	}
}

sub _add_keys {
	my ($self, $letters) = @_;
	my $keyboard_box = $self->elm_kbd_box();
	
	my $keyboard_line_box = pEFL::Elm::Box->add($keyboard_box);
	$keyboard_line_box->horizontal_set(1);
	$keyboard_line_box->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
	$keyboard_line_box->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);
	$keyboard_line_box->show();
	
	push(@{$self->elm_kbd_lines_bxs()}, $keyboard_line_box);
	
	foreach my $l (@$letters) {
	
	if ($l eq "###") {
		$keyboard_line_box = pEFL::Elm::Box->add($keyboard_box);
		$keyboard_line_box->horizontal_set(1);
		$keyboard_line_box->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
		$keyboard_line_box->size_hint_align_set(EVAS_HINT_FILL,EVAS_HINT_FILL);	$keyboard_line_box->show();
		push(@{$self->elm_kbd_lines_bxs()}, $keyboard_line_box);
	} 	
	else {
		# basic tutorial code
		# basic text button
		my $button = pEFL::Elm::Button->new($keyboard_line_box);
		$button->focus_allow_set(0);
		
		if (ref($l) eq "ARRAY") {
			$button->text_set($l->[0]);
			$button->autorepeat_set(1);
			# Set the initial timeout before the autorepeat event is generated.
			$button->autorepeat_initial_timeout_set(0.4);
			$button->autorepeat_gap_timeout_set(0.4);
			$button->smart_callback_add("repeated", \&_show_letters_popup, [$self, $l]);
		}
		elsif ($l eq "(X)") {
			my $icon = pEFL::Elm::Icon->add($button);

			# set the image file and the button as an icon
			$icon->standard_set("close");
			$icon->no_scale_set(1);
			$button->part_content_set("icon",$icon);
		}
		elsif ($l eq "Del") {
			my $icon = pEFL::Elm::Icon->add($button);

			# set the image file and the button as an icon
			$icon->standard_set("go-first");
			$icon->no_scale_set(1);
			$button->part_content_set("icon",$icon);
			$button->text_set("Del")
		}
		elsif ($l eq "Caps") {
			my $icon = pEFL::Elm::Icon->add($button);

			# set the image file and the button as an icon
			$icon->standard_set("go-up");
			$icon->no_scale_set(1);
			$button->part_content_set("icon",$icon);
			$button->text_set("Caps");
			# Set the initial timeout before the autorepeat event is generated.
			$button->autorepeat_set(1);
			$button->autorepeat_initial_timeout_set(0.8);
			$button->autorepeat_gap_timeout_set(0.5);
			$button->smart_callback_add("repeated", \&_do_caps_lock, $self);
		}
		elsif ($l eq "Enter") {
			my $icon = pEFL::Elm::Icon->add($button);

			# set the image file and the button as an icon
			$icon->standard_set("go-previous");
			$icon->no_scale_set(1);
			$button->part_content_set("icon",$icon);
			$button->text_set("Enter");
		}
		else {
			$button->text_set("$l");
		}
		
		if ($l eq "Space") {
			$button->size_hint_weight_set(8, EVAS_HINT_EXPAND);
			$button->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
		}
		else {
			#$button->size_hint_weight_set(0.2,EVAS_HINT_EXPAND);
			$button->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
			$button->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
		}

		$button->show();
		$keyboard_line_box->pack_end($button);		
		
		push(@{$self->elm_buttons()}, $button);
	}
	
		$keyboard_box->pack_end($keyboard_line_box);
	
	}
	
	foreach my $button (@{$self->elm_buttons()}) {
		# Click event
		$button->smart_callback_add("clicked", \&_button_click_cb, $self);
		
		if ($button->text_get() eq "Del" || $button->text_get() eq "Space") {
			# Set the initial timeout before the autorepeat event is generated.
			$button->autorepeat_set(1);
			$button->autorepeat_initial_timeout_set(0.5);
			$button->autorepeat_gap_timeout_set(0.05);
			$button->smart_callback_add("repeated", \&_button_click_cb, $self);
		}
	}
}

sub _ctxpopup_item_cb {
	my ($data, $obj, $evinfo) = @_;
	my $selected = pEFL::ev_info2obj($evinfo, "pEFL::Elm::CtxpopupItem");
	my $text = $selected->text_get();
	$obj->del();
	
	my $en = $data->[0]->elm_target();
	$en->entry_insert($text);
	
	# Wir müssen die Callbacks des Buttons wieder aktivieren, wenn das Popup gelöscht wurde
	my $self = $data->[0];
	my $l = $data->[1];
	my $button = $data->[2];
	$button->smart_callback_add("clicked", \&_button_click_cb, $self);
	$button->smart_callback_add("repeated", \&_show_letters_popup, [$self, $l]);
	
}

sub item_new {
	my ($ctxpopup, $label, $data) = @_;
	
	return $ctxpopup->item_append($label, undef, \&_ctxpopup_item_cb, $data);
}

sub _dismissed_cb {
	my ($data, $obj, $ev) = @_;
	$obj->del();
	
	# Wir müssen die Callbacks des Buttons wieder aktivieren, wenn das Popup gelöscht wurde
	my $self = $data->[0];
	my $l = $data->[1];
	my $button = $data->[2];
	$button->smart_callback_add("clicked", \&_button_click_cb, $self);
	$button->smart_callback_add("repeated", \&_show_letters_popup, [$self, $l]);
}

sub _show_letters_popup {
	my ($data, $button, $ev_info) = @_;
	
	# Solange das Popup offen ist, müssen wir die anderen Callbacks deaktivieren
	$button->smart_callback_del("clicked", \&_button_click_cb);
	$button->smart_callback_del("repeated", \&_show_letters_popup);
	
	my $self = $data->[0];
	my @letters = @{$data->[1]};
	
	my $ctxpopup = pEFL::Elm::Ctxpopup->add($self->elm_parent());
	$ctxpopup->smart_callback_add("dismissed", \&_dismissed_cb, [$self, $data->[1], $button]);
	
	foreach my $l (@letters) {
		item_new($ctxpopup, $l, [@$data, $button]);
	}	
   	my $canvas = $button->evas_get();
   	my ($x, $y) = $canvas->pointer_canvas_xy_get();
   	$ctxpopup->move($x,$y);
   	$ctxpopup->show();
   	
   	#my $selected = pEFL::ev_info2obj($ev_info, "pEFL::Elm::ListItem");
   	#$selected->selected_set(0);
}

sub _do_caps_lock {
	my ($data, $button, $event_info) = @_;
	
	# Solange das Caps_lock aktiviert ist, muss der normale Callback deaktiviert werden
	$button->smart_callback_del("clicked", \&_button_click_cb);
	$button->smart_callback_del("repeated", \&_do_caps_lock);
	
	$button->text_set("Caps lock");
	my $icon = pEFL::Elm::Icon->add($button);
	# set the image file and the button as an icon
	$icon->standard_set("go-top");
	$icon->no_scale_set(1);
	$button->part_content_set("icon",$icon);
	
	
	foreach my $b (@{$data->elm_buttons()}) {
			my $text = $b->text_get();
			
			next if (!$text || $text eq "Del" || $text eq "Caps" || $text eq "Caps lock" ||  $text eq "Enter" || $text eq "Space" || $text eq "?123" || $text eq "ß");
			next unless ($b->text_get());
			$b->text_set(uc($text));
		}
		
	$button->smart_callback_add("clicked" => \&_caps_lock_cb, $data);
}

sub _caps_lock_cb {
	my ($data, $button, $event_info) = @_;
	
	# Mit dem Repeated Event wird zugleich zum ersten Mal _caps_lock_cb aufgerufen
	# Dieser erste Aufruf würde dazu führen, dass der Caps lock sofort wieder rückgängig gemacht würde
	# Workaround ist diesen ersten Funktionsaufruf nur dazu zu nutzen die entsprechenden 
	# Variablen zuzuweisen
	if ($data->is_caps_lock() == 0) {
		$data->is_caps_lock(1);
		$data->is_caps(1);
	}
	else {
	
		$button->text_set("Caps");
		my $icon = pEFL::Elm::Icon->add($button);
		# set the image file and the button as an icon
		$icon->standard_set("go-up");
		$icon->no_scale_set(1);
		$button->part_content_set("icon",$icon);
	
		foreach my $b ( @{$data->elm_buttons()} ) {
			my $text = $b->text_get();
				
			next if (!$text || $text eq "Del" || $text eq "Caps" ||  $text eq "Enter" || $text eq "Space" || $text eq "?123" || $text eq "ß");
			$b->text_set(lc($text));
		}
	
		$data->is_caps(0);
		$data->is_caps_lock(0);
	
		# Nun müssen wir wieder den Callback _do_caps_lock deaktivieren
		$button->smart_callback_del("clicked", \&_caps_lock_cb);
		$button->smart_callback_add("clicked", \&_button_click_cb, $data);
		$button->smart_callback_add("repeated", \&_do_caps_lock, $data);
	}	
}

sub _button_click_cb {
	my ($data, $button, $event_info) = @_;
	
	my $en = $data->elm_target();
	my $buttons = $data->elm_buttons();
	
	my $icon = $button->part_content_get("icon");
	bless($icon, "pEFL::Elm::Icon") if ($icon);
	
	if ($icon && $icon->standard_get() eq "close" ) {
		$data->hide_keyboard();
	}
	elsif ($button->text_get() eq "Del") {
		$en->cursor_selection_begin();
		$en->cursor_prev();
		$en->cursor_selection_end();
		$en->selection_cut();
	}
	elsif ($button->text_get() eq "Caps") {
		if ($data->is_caps()) {
			
			foreach my $b (@$buttons) {
				my $text = $b->text_get();
			
				next if (!$text || $text eq "Del" || $text eq "Caps" ||  $text eq "Enter" || $text eq "Space" || $text eq "?123" || ($icon && $icon->standard_get() eq "close") || $text eq "ß");
				$b->text_set(lc($text));
			}
			
			$data->is_caps(0);
		
		}
		else {
			foreach my $b (@$buttons) {
				my $text = $b->text_get();
			
				next if (!$text || $text eq "Del" || $text eq "Caps" ||  $text eq "Enter" || $text eq "Space" || $text eq "?123" || ($icon && $icon->standard_get() eq "close") || $text eq "ß");
				$b->text_set(uc($text));
			}
		
			$data->is_caps(1);
		}
	}
	elsif ($button->text_get() eq "Enter") {
		$en->entry_insert("<br>");
	}
	elsif ($button->text_get() eq "?abc") {
		$data->clear_keyboard();
		$data->show_keyboard($data->layout()->{letters});
	}
	elsif ($button->text_get() eq "?123" || $button->text_get() eq "2/2") {
		$data->clear_keyboard();
		$data->show_keyboard($data->layout()->{symbols_1});
	}
	elsif ($button->text_get() eq "1/2") {
		$data->clear_keyboard();
		$data->show_keyboard($data->layout()->{symbols_2});
	}
	elsif ($button->text_get() eq "Space") {
		$en->entry_insert(" ");
	}
	else {
		$en->entry_insert($button->text_get());
		if ($data->is_caps() && ! $data->is_caps_lock()) {
			foreach my $b (@$buttons) {
				my $text = $b->text_get();
			
				next if ($text eq "Del" || $text eq "Caps" ||  $text eq "Enter" || $text eq "Space" || $text eq "?123" || ($icon && $icon->standard_get() eq "close") || $text eq "ß");
				$b->text_set(lc($text));
		}
		$data->is_caps(0);
		
		}
	}
}

sub DESTROY {

}

1;