use Renard::Incunabula::Common::Setup;
package Renard::API::AnkiConnect::REST;
# ABSTRACT: REST API for AnkiConnect

=for Pod::Coverage uri net_async_http api

=cut

use Mu;
use Function::Parameters;
use JSON::MaybeXS;
use Renard::Incunabula::Common::Types qw(InstanceOf Uri);
use namespace::clean;

use constant API_VERSION => 6;

=attr uri

A L<URI> for the AnkiConnect HTTP server.

=cut
has uri => (
	is => 'ro',
	isa => Uri,
	default => sub { URI->new('http://localhost:8765') }
);

=attr net_async_http

(required)

An instance of L<Net::Async::HTTP> that is used to retrieve the API endpoints.

=cut
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

api addNote => ();
api addNotes => ();
api addTags => ();
api areDue => ();
api areSuspended => ();
api canAddNotes => ();
api cardReviews => ();
api cardsInfo => ();
api cardsToNotes => ();
api changeDeck => ();
api cloneDeckConfigId => ();
api createDeck => ();
api createModel => ();
api deckNames => ();
api deckNamesAndIds => ();
api deleteDecks => ();
api deleteMediaFile => ();
api deleteNotes => ();
api exportPackage => ();
api findCards => ();
api findNotes => ();
api getCollectionStatsHTML => ();
api getDeckConfig => ();
api getDecks => ();
api getEaseFactors => ();
api getIntervals => ();
api getLatestReviewID => ();
api getNumCardsReviewedToday => ();
api getProfiles => ();
api getTags => ();
api guiAddCards => ();
api guiAnswerCard => ();
api guiBrowse => ();
api guiCurrentCard => ();
api guiDeckBrowser => ();
api guiDeckOverview => ();
api guiDeckReview => ();
api guiExitAnki => ();
api guiShowAnswer => ();
api guiShowQuestion => ();
api guiStartCardTimer => ();
api importPackage => ();
api insertReviews => ();
api loadProfile => ();
api modelFieldNames => ();
api modelFieldsOnTemplates => ();
api modelNames => ();
api modelNamesAndIds => ();
api modelStyling => ();
api modelTemplates => ();
api multi => ();
api notesInfo => ();
api reloadCollection => ();
api removeDeckConfigId => ();
api removeTags => ();
api retrieveMediaFile => ();
api saveDeckConfig => ();
api setDeckConfigId => ();
api setEaseFactors => ();
api storeMediaFile => ();
api suspend => ();
api sync => ();
api unsuspend => ();
api updateCompleteDeck => ();
api updateModelStyling => ();
api updateModelTemplates => ();
api updateNoteFields => ();
api version => ();


1;
