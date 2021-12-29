#!/usr/bin/env perl

use Test::Most;

use Renard::Incunabula::Common::Setup;
use Renard::API::AnkiConnect::REST;
use IO::Async::Loop;
use IO::Async::Function;
use Net::Async::HTTP;
use Proc::Killall;
use File::HomeDir;
use File::Which qw(which);

use lib 't/lib';

my $anki;
if( $^O eq 'linux' ) {
	$anki = qw(anki);
} elsif( $^O eq 'darwin' ) {
	my $macos_anki_path = path('/Applications/Anki.app/Contents/MacOS/Anki');
	$anki = "$macos_anki_path";
} elsif( $^O eq 'MSWin32' ) {
	my $win_anki_path = path('C:/Program Files/Anki/anki.exe');
	$anki = "$win_anki_path";
}

if( which($anki) ) {
	plan tests => 1;
} else {
	plan skip_all => 'Anki not found';
}

fun kill_anki() {
	my $procs = killall('HUP', qr/\b[aA]nki\b/);
	sleep 1 if( $procs );
}

kill_anki;

my $unix_path = path('~/.local/share/Anki2');
my $macos_path = path('~/Library/Application Support/Anki2');
my $win32_path = path(File::HomeDir->my_data)->parent->child(qw(Roaming Anki2));

fun install_ankiconnect( $base_dir ) {
	my $ankiconnect_url = 'https://github.com/FooSoft/anki-connect/archive/master.zip';
	my $ankiconnect_url_prefix = 'anki-connect-master';
	my $ankiconnect_addon_id = '2055492159';

	my $addons_path = $base_dir->child('addons21');
	my $addon_directory = $addons_path->child($ankiconnect_addon_id);
	$addon_directory->mkpath;
	use HTTP::Tiny;
	use Archive::Zip;
	use IO::Socket::SSL;
	use Net::SSLeay;
	my $response = HTTP::Tiny->new->get($ankiconnect_url);
	die "Unable to install addon!\n" unless $response->{success};

	my $addon_zip = Path::Tiny->tempfile( SUFFIX => ".zip" );
	$addon_zip->spew_raw($response->{content});
	my $zip = Archive::Zip->new( "$addon_zip" );
	$zip->extractTree( "${ankiconnect_url_prefix}/plugin", "@{[ $addon_directory->realpath ]}" );

	$addon_directory->child('meta.json')->spew_utf8(qq|{"name": "AnkiConnect", "mod": @{[ time() ]}}|);
}

fun create_anki_directory_using_setup_py($base_dir, $temp_user) {
	if( $^O eq 'linux' ) {
		system(qw(python3 maint/anki-setup.py),
			qw(--base), $base_dir,
			qw(--profile), $temp_user );
	}
}

fun create_anki_directory_using_skeleton($base_dir, $temp_user) {
	use File::Copy::Recursive qw(dircopy);
	dircopy('maint/Anki2-skel', $base_dir);
}

my $base_dir = Path::Tiny->tempdir;
#my $temp_user = "__Temporary Test User__";
my $temp_user = "User 1";

create_anki_directory_using_skeleton($base_dir, $temp_user);
install_ankiconnect($base_dir);

my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new;
$loop->add( $http );

# Start Anki
my $function = IO::Async::Function->new(
	code => sub {
		close STDIN;
		close STDOUT;
		close STDERR;
		my $exit = system(
			$anki,
			qw(-b), $base_dir,
			qw(-p), $temp_user,
		);
	},
);
$loop->add( $function );
my $anki_func_future = $function->call( args => [] );
sleep 6;

subtest "Testing API creation" => fun() {
	my $rest = Renard::API::AnkiConnect::REST->new(
		net_async_http => $http,
	);
	can_ok $rest, qw(version sync);

	my $future = $rest->version->on_done( sub {
		my ($api_response) = @_;
		is $api_response->{result}, Renard::API::AnkiConnect::REST::API_VERSION, 'check that version matches';
	})->on_fail(sub {
		fail 'could not get response';
	})->followed_by(sub {
		$rest->guiExitAnki->get;
		sleep 3;
		kill_anki;
	});

	$loop->await_all($future, $anki_func_future);
};

done_testing;
