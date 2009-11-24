package JIRA::Import::Input;

use Moose::Role;


requires 'read_input';


=pod

This is the old input code, should probably be in a Input::STDIN and a Input::File
sub read_input {
    my ($self) = @_;
    
    my $s = IO::Select->new();
    $s->add(\*STDIN);
    my $fname = $self->input;

    if ($fname) {
        open IN, "<", $fname or die "Cannot read $fname: $!";
        $s->add(\*IN);
        $s->remove(\*STDIN);
    }

    my @handles = $s->can_read(1);

    unless (@handles) {
        die "Cannot read from any handles :/ Either send something on STDIN or pass a --input paramter";
    }

    my $handle = shift(@handles);
    my $str = do { local $/; <$handle>; };
    return JSON->new->utf8->decode($str);
}
=cut

1;
