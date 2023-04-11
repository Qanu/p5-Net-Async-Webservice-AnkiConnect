#!/usr/bin/env perl

use Test::Most tests => 2;

use Renard::Incunabula::Common::Setup;

plan skip_all => "Only test on Linux" unless $^O eq 'linux';

my $GET_API_FROM_PM=q{grep '^api' lib/Net/Async/WebService/AnkiConnect/REST.pm | sed 's/ =>.*$//'};
my $GET_API_FROM_POD=q{grep '=head2' lib/Net/Async/WebService/AnkiConnect/REST.pod  | sed 's/=head2/api/g; s/C<//; s/>//;'};

my $SORT_EXIT = system( "$GET_API_FROM_PM | sort -C" );
ok 0 == $SORT_EXIT, "Checking if API is sorted in .pm";

my $diff = `bash -c "diff -U 3 <( $GET_API_FROM_PM  ) <( $GET_API_FROM_POD | sort )"`;
my $DIFF_EXIT = $?;
ok 0 == $DIFF_EXIT, "Checking API diff" or note $diff;

done_testing;
