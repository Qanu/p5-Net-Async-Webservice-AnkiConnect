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
	use Types::Path::Tiny qw/Path/;
	use Markdown::Pod;

	option 'root_path' => (
		is => 'ro',
		format => 's',
		doc => 'Root for AnkiConnect',
		default => "$FindBin::Bin/../../FooSoft/anki-connect",
		isa => Path,
		coerce => 1,
	);

	option 'lib_path' => (
		is => 'ro',
		format => 's',
		doc => 'Root for lib',
		default => "$FindBin::Bin/../lib",
		isa => Path,
		coerce => 1,
	);


	lazy readme_path => method() {
		$self->root_path->child('README.md');
	};

	lazy action_paths => method() {
		my $markdown = $self->readme_path->slurp_utf8;

		# Start processing from after the "Supported Actions" header.
		$markdown =~ s/.*\Q### Supported Actions\E//s;

		my @actions = $markdown =~ m,(actions/[^)]+),g;

		return [ map { $self->root_path->child($_) } @actions ];
	};

	method fix_spell($markdown) {
		$markdown =~ s{Invoking the action mutliple times}{Invoking the action multiple times}msg or die "Not replaced";
		$markdown =~ s{configured by user in anki}{configured by user in Anki}msg or die "Not replaced";

		$markdown;
	}

	method run() {
		$self->action_paths;

		my $markdown = join "\n", map { $_->slurp_utf8 } @{ $self->action_paths };
		$markdown = $self->fix_spell($markdown);

		# Remove the GitHub-Markdown syntax tag for code blocks.
		$markdown =~ s/```json/```/msg;

		# Change the list of API calls into H2
		$markdown =~ s/^\* \s+ \Q**\E (?<api>.*) \Q**\E/## `$+{api}`/mgx;
		$markdown =~ s/^(\ {4}|\t)//mgx;

		# Patch to fix codeblock
		$markdown =~ s/(^\s*\Q"vers":[\E\n)\n/$1/ms;
		$markdown =~ s/(^\s*\Q"media":[\E\n)\n/$1/mgs;
		$markdown =~ s/(^\s*\Q"tags":[\E\n)\n/$1/ms;
		$markdown =~ s/(^\s*\Q[\E\n)\n/$1/ms;
		#binmode STDOUT, ':encoding(UTF-8)'; say $markdown;

		my $m2p = Markdown::Pod->new;
		my $pod = $m2p->markdown_to_pod(
			markdown => $markdown,
			encoding => 'utf8',
		);
		utf8::decode($pod);

		substr($pod, 0, 0) = <<EOF;
# PODNAME: Net::Async::WebService::AnkiConnect::REST

1;

=for Pod::Coverage uri net_async_http api

=cut

EOF

		my $output = $self->lib_path->child(qw(Net Async WebService AnkiConnect REST.pod));
		$output->parent->mkpath;
		$output->spew_utf8($pod);
	}
}

AnkiConnect::API::Extract->new_with_options->run;

1;
