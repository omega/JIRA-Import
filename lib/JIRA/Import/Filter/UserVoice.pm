package JIRA::Import::Filter::UserVoice;
use Moose;

with 'JIRA::Import::Filter';

sub process {
    my ($self, $issues) = @_;
    
    foreach my $issue (@$issues) {
        my $title = $issue->{title};
        # XXX: yuck, this is :/
        utf8::encode($title);
        $issue = {
            summary => $title,
            remote_id => $issue->{id},
        }
    }
    $issues;
}

1;