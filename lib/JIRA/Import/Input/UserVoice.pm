package JIRA::Import::Input::UserVoice;

use Moose;

with 'JIRA::Import::Input';


has 'api' => (is => 'ro', isa => 'WWW::UserVoice::API');
has 'forum' => (is => 'ro', isa => 'Int');

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    
    my %args;
    if (ref $_[0] eq 'HASH') {
        %args = %{$_[0]};
    } else {
        %args = @_;
    }    
    # Now we need to hax0rs %args a bit

    my %new_args;
    # Yuck, this is ugly :p
    $new_args{forum} = delete($args{forum});
    Class::MOP::load_class('WWW::UserVoice::API');
    $new_args{api} = WWW::UserVoice::API->new(%args);
    
    $class->$orig(%new_args);
};


sub read_input {
    my $self = shift;
    $self->api->forum(id => $self->forum)->list_suggestions();
}
1;