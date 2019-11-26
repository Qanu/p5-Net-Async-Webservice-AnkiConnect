#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Renard::API::AnkiConnect::REST;
use IO::Async::Loop;
use Net::Async::HTTP;

use lib 't/lib';

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
