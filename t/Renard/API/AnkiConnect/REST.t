#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Renard::API::AnkiConnect::REST;
use IO::Async::Loop;
use Net::Async::HTTP;

use lib 't/lib';

my $ankiconnect_url = 'https://raw.githubusercontent.com/FooSoft/anki-connect/master/AnkiConnect.py';
my $ankiconnect_addon_id = '2055492159';
my $unix_path = path('~/.local/share/Anki2/addons21');
my $addon_directory = $unix_path->child($ankiconnect_addon_id);
my $addon_python = $addon_directory->child('__init__.py');
if( -d $unix_path && ! -f $addon_python ) {
	use HTTP::Tiny;
	$addon_python->parent->mkpath;
	my $response = HTTP::Tiny->new->get($ankiconnect_url);
	die "Unable to install addon!\n" unless $response->{success};
	$addon_python->spew_utf8($response->{content});

	$addon_directory->child('meta.json')->spew_utf8(qq|{"name": "AnkiConnect", "mod": @{[ time() ]}}|);
}

# Start Anki
my $pid = fork;
if( defined $pid && $pid == 0 ) {
	close STDERR;
	close STDOUT;
	exec(qw(anki));
} else {
	sleep 1;
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
	});

	$loop->await($future);
};

done_testing;
