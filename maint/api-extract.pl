#!/usr/bin/env perl
# PODNAME: api-extract
# ABSTRACT: Extract API documentation from Markdown

use Modern::Perl;

package AnkiConnect::API::Extract {
	use FindBin;
	use Mu;
	use CLI::Osprey;
	use Function::Parameters;
	use Path::Tiny;
	use Markdown::Pod;

	option 'root_path' => (
		is => 'ro',
		format => 's',
		doc => 'Root for AnkiConnect',
		default => "$FindBin::Bin/../../FooSoft/anki-connect"
	);

	option 'lib_path' => (
		is => 'ro',
		format => 's',
		doc => 'Root for lib',
		default => "$FindBin::Bin/../lib"
	);


	lazy readme_path => method() {
		path($self->root_path)->child('README.md');
	};

	method run() {
		my $markdown = $self->readme_path->slurp_utf8;
		$markdown =~ s/```json/```/msg;

		# Start processing from after the "Supported Actions" header.
		$markdown =~ s/.*\Q### Supported Actions ###\E//s;

		# The first heading at level 4
		$markdown =~ s/.*?(\Q#### \E)/$1/s;

		# Change the headings from H4 into H2.
		$markdown =~ s/^####/##/mg;

		# Change the list of API calls into H3
		$markdown =~ s/^\* \s+ \Q**\E (?<api>.*) \Q**\E/### `$+{api}`/mgx;
		$markdown =~ s/^(\ {4}|\t)//mgx;

		# Patch to fix codeblock
		$markdown =~ s/(^\s*\Q"vers":[\E\n)\n/$1/ms;
		$markdown =~ s/(^\s*\Q"media":[\E\n)\n/$1/mgs;
		$markdown =~ s/(^\s*\Q"tags":[\E\n)\n/$1/ms;
		$markdown =~ s/(^\s*\Q[\E\n)\n/$1/ms;
		#say $markdown;

		my $m2p = Markdown::Pod->new;
		my $pod = $m2p->markdown_to_pod(
			markdown => $markdown,
			encoding => 'utf8',
		);
		utf8::decode($pod);

		substr($pod, 0, 0) = <<EOF;
# PODNAME: Renard::API::AnkiConnect::REST

=for Pod::Coverage uri net_async_http api

=cut

EOF

		my $output = path($self->lib_path)->child(qw(Renard API AnkiConnect REST.pod));
		$output->parent->mkpath;
		$output->spew_utf8($pod);
	}
}

AnkiConnect::API::Extract->new_with_options->run;

1;
