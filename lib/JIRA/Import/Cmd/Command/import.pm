package JIRA::Import::Cmd::Command::import;

use Moose;

extends qw(MooseX::App::Cmd::Command);

use JIRA::Import::Types qw/JIRAClient Filter Input/;

with 'MooseX::SimpleConfig';

has 'client' => ( is => 'ro', isa => JIRAClient, coerce => 1, handles => [qw/create_issue/]);
has 'input' => ( is => 'ro', isa => Input, required => 1, coerce => 1, handles => 'JIRA::Import::Input');


has 'filter' => (is => 'ro', isa => Filter, predicate => 'has_filter', coerce => 1);

has 'project' => (is => 'ro', isa => 'Str');
has 'remote_id_custom_field' => (is => 'ro', isa => 'Int');
has 'remote_issue_type' => (is => 'ro', isa => 'Int');


use Data::Dump qw/dump/;
sub execute {
    my $self = shift;
    Class::MOP::load_class('IO::Select');
    Class::MOP::load_class('JSON');
    $self->import_issues(
        $self->filter_input(
            $self->read_input()
        )
    );
}
sub cust_id {
    my $self = shift;
    
    return 'customfield_' . $self->remote_id_custom_field;
}
sub filter_input {
    my ($self, $input) = @_;
    
    if ($self->has_filter) {
        $input = $self->filter->process($input);
    }
    # Now we should pad with project and type
    map {
        $_->{project} = $self->project;
        $_->{type} = $self->remote_issue_type;
        
        $_->{custom_fields} = {
             $self->cust_id => delete $_->{remote_id}
        };
    } @$input;
    
    $input;
}

sub import_issues {
    my ($self, $issues) = @_;
    
    foreach my $issue (@$issues) {
        
        if (my $err = $self->verify_issue($issue)) {
            confess("Could not verify issue: $err");
        }
        
        my $remote_issue;
        if ($remote_issue = $self->get_jira_issue($issue->{custom_fields}->{$self->cust_id})) {
            print "Found " . $remote_issue->{key} . " from remote id, not creating\n";
            # XXX: Should check for changes in $issue vs $remote_issue
        } else {
            # I guess we should try to add it then
            $remote_issue = $self->create_issue($issue);
            print "Created " . $remote_issue->{key} . "\n";
        }
    }
}

sub get_jira_issue {
    my ($self, $remote_id) = @_;
    
    my $issues = $self->client->getIssuesFromJqlSearch(
        "project = " . $self->project . " and cf[" . $self->remote_id_custom_field . "] = " . $remote_id, 
    1);
    if (@$issues) {
        return $issues->[0];
    } else {
        return;
    }
}

sub verify_issue {
    my ($self, $issue) = @_;
    my @required = qw/project summary type/;
    
    foreach my $f (@required) {
        return "missing issue field: $f" unless exists $issue->{$f};
    }
    
    return;
}

1;