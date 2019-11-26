use Renard::Incunabula::Common::Setup;
package Renard::API::AnkiConnect::REST;
# ABSTRACT: REST API for AnkiConnect

use Mu;
use Function::Parameters;
use JSON::MaybeXS;
use Renard::Incunabula::Common::Types qw(InstanceOf Uri);
use namespace::clean;

use constant API_VERSION => 6;

has uri => (
	is => 'ro',
	isa => Uri,
	default => sub { URI->new('http://localhost:8765') }
);
has net_async_http => (
	is => 'ro',
	isa => InstanceOf['Net::Async::HTTP'],
	required => 1
);

fun api($name, %options) {
	no strict 'refs'; ## no critic
	*{$name} = sub {
		my ($self, $params) = @_;
		my $future = $self->net_async_http->do_request(
			uri => $self->uri,
			method => 'POST',
			content_type => 'application/json',
			content => encode_json({
				action => $name,
				( params => $params ) x !!( defined $params ),
				version => API_VERSION
			}),
		)->transform(
			done => sub {
				my ($response) = @_;
				my $api_response = decode_json($response->decoded_content);
			}
		);
	};
}

api version => ();
api upgrade => ();
api sync => ();
api loadProfile => ();
api multi => ();
api deckNames => ();
api deckNamesAndIds => ();
api getDecks => ();
api createDeck => ();
api changeDeck => ();
api deleteDecks => ();
api getDeckConfig => ();
api saveDeckConfig => ();
api setDeckConfigId => ();
api cloneDeckConfigId => ();
api removeDeckConfigId => ();
api modelNames => ();
api modelNamesAndIds => ();
api modelFieldNames => ();
api modelFieldsOnTemplates => ();
api createModel => ();
api addNote => ();
api addNotes => ();
api canAddNotes => ();
api updateNoteFields => ();
api addTags => ();
api removeTags => ();
api getTags => ();
api findNotes => ();
api notesInfo => ();
api deleteNotes => ();
api suspend => ();
api unsuspend => ();
api areSuspended => ();
api areDue => ();
api getIntervals => ();
api findCards => ();
api cardsToNotes => ();
api cardsInfo => ();
api storeMediaFile => ();
api retrieveMediaFile => ();
api deleteMediaFile => ();
api guiBrowse => ();
api guiAddCards => ();
api guiCurrentCard => ();
api guiStartCardTimer => ();
api guiShowQuestion => ();
api guiShowAnswer => ();
api guiAnswerCard => ();
api guiDeckOverview => ();
api guiDeckBrowser => ();
api guiDeckReview => ();
api guiExitAnki => ();


1;
