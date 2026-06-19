package ContentHub;

use strict;
use warnings;
use utf8;

use Protocol::DBus;
use Protocol::DBus::Client;
use pEFL::Ecore;

use File::Path qw(make_path);
use File::Copy qw(copy);

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

# Register Getters and Setters
BEGIN {
	foreach my $member ( qw(app_id app_name import_dir incoming_dir on_import_cb on_import_data) ) {
		no strict 'refs';
		
		*{$member} = sub {
			my ($self, $newval) = @_;
			
			my $oldval = $self->{$member};
			$self->{$member} = $newval if defined($newval);
	
			return $oldval;
		};
	}
}

sub new {
	my $class = shift;	
	
	die "odd values for parameters\n" if (@_ % 2);
	my %args = @_;
	my $app_id = $args{app_id};
	die "You have to pass at least app_id\n" unless ($app_id);
	
	my $on_import_cb = $args{on_import_cb};
	die "No callback function passed\n" unless ($on_import_cb);
	
	my $app_name;
	if ($args{app_name}) {
		$app_name = $args{app_name};
	}
	else {
		($app_name) = split(/_/, $app_id);
	}
	
	# Get index
	my $obj = {
		app_id => $app_id,
		app_name => $app_name, 
		import_dir => $args{import_dir} || "/home/phablet/.cache/$app_name/imported_files",
		incoming_dir => $args{incoming_dir} || "/home/phablet/.cache/$app_name/HubIncoming",
		on_import_cb => $on_import_cb,
		on_import_data => $args{on_import_data} || undef
		};
	
	bless($obj,$class);
	return $obj;
}

# Initialize the FileMonitors!
sub init {
	my ($self) = @_;
	
	my $incoming_dir = $self->incoming_dir();
	
	if (-e $incoming_dir) {
		my $monitor = pEFL::Ecore::FileMonitor->add(
    	$incoming_dir,
    	\&_look_for_imports,
    	$self
		);
	}
	else {
		# das HubIncoming Verzeichnis existiert noch nicht.
		# Wir können den FileMonitor erst aktivieren, wenn 
		# es durch den Content Hub erstellt wurd!
		my $app_cache = "/home/phablet/.cache/" . $self->app_name;
		my $monitor = pEFL::Ecore::FileMonitor->add(
    		$app_cache,
    		\&_register_hub_incoming_watcher,
    		$self
		);
	}	
}

sub _register_hub_incoming_watcher {
	my ($self, $monitor_obj, $event, $path) = @_;
	
	my $incoming_dir = $self->incoming_dir();
	my $app_cache = "/home/phablet/.cache/".$self->app_name;
	
	# Directory created!!!
	if ($event == 2 && $path eq $self->incoming_dir()) {
		
		# Wir müssen den ersten Import manuell durchführen, weil der File Monitor
		# ja erst nach der Erstellung des HubIncoming Directories (inklusive des ersten
		# Content Hub File exchange startet)
		my ($transfer_id, $path) = $self->get_hub_transfer();
				
		if ($path) {
			my $on_import_cb = $self->on_import_cb();
			$on_import_cb->( $self, $path, $self->on_import_data() );
		}
		
		my $monitor = pEFL::Ecore::FileMonitor->add(
    		$incoming_dir,
    		\&_look_for_imports,
    		$self
		);
		$monitor_obj->del();
	}
}

sub get_hub_transfer {
	my ($self) = @_;
	
	my $incoming_dir = $self->incoming_dir();
	
	return "" unless (-d $incoming_dir);
	
	opendir(my $dh, $incoming_dir ) || die "Can't opendir: $!";
	my ($transfer_id) = grep { !/^\./ &&  -d "$incoming_dir/$_" } readdir($dh);
	closedir $dh;
	
	my $path = $transfer_id ? $self->incoming_dir()."/$transfer_id" : undef;
	
	return ($transfer_id, $path);
}

sub _look_for_imports {
	my ($self, $monitor_obj, $event, $path) = @_;
	
	# Directory created!!!
	if ($event == 2) {
		my $on_import_cb = $self->on_import_cb();
		$on_import_cb->( $self, $path, $self->on_import_data() );
	}
}

sub import_path {
	my ($self, $path) = @_;
	
	my ($transfer_id) = $path =~ /(\d+)$/;
	
	my $app_id = $self->app_id();
		
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

	my $new_path = $self->import_dir(); 
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

return 1;
