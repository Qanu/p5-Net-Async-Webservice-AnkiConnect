#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Renard::API::AnkiConnect::REST;
use IO::Async::Loop;
use Net::Async::HTTP;
use Proc::Killall;

use lib 't/lib';

my $procs = killall('HUP', 'anki');
sleep 1 if( $procs );

my $unix_path = path('~/.local/share/Anki2');
my $macos_path = path('~/Library/Application Support/Anki2');


fun install_ankiconnect( $base_dir ) {
	my $ankiconnect_url = 'https://raw.githubusercontent.com/FooSoft/anki-connect/master/AnkiConnect.py';
	my $ankiconnect_addon_id = '2055492159';

	my $addons_path = $base_dir->child('addons21');
	my $addon_directory = $addons_path->child($ankiconnect_addon_id);
	my $addon_python = $addon_directory->child('__init__.py');
	use HTTP::Tiny;
	use IO::Socket::SSL;
	use Net::SSLeay;
	$addon_python->parent->mkpath;
	my $response = HTTP::Tiny->new->get($ankiconnect_url);
	die "Unable to install addon!\n" unless $response->{success};
	$addon_python->spew_utf8($response->{content});

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

# Start Anki
my $pid = fork;
if( defined $pid && $pid == 0 ) {
	close STDERR;
	close STDOUT;
	my $anki;
	if( $^O eq 'linux' ) {
		$anki = qw(anki);
	} elsif( $^O eq 'darwin' ) {
		my $macos_anki_path = path('/Applications/Anki.app/Contents/MacOS/Anki');
		$anki = "$macos_anki_path";
	}
	exec($anki,
		qw(-b), $base_dir,
		qw(-p), $temp_user,
	);
} else {
	sleep 6;
};

subtest "Testing API creation" => fun() {
	my $loop = IO::Async::Loop->new;
	my $http = Net::Async::HTTP->new;
	$loop->add( $http );
	my $rest = Renard::API::AnkiConnect::REST->new(
		net_async_http => $http,
	);
	can_ok $rest, qw(version upgrade sync);

	my $future = $rest->version->on_done( sub {
		my ($api_response) = @_;
		is $api_response->{result}, Renard::API::AnkiConnect::REST::API_VERSION, 'check that version matches';
	})->on_fail(sub {
		fail 'could not get response';
	})->followed_by(sub {
		$rest->guiExitAnki->get;
	});

	$loop->await($future);
	waitpid $pid, 0;
};

done_testing;
