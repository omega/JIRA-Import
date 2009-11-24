package JIRA::Import::Types;

use MooseX::Types
    -declare => [qw/
        JIRAClient
        Filter
        Input
    /]
;

use MooseX::Types::Moose qw/Object HashRef ArrayRef Str/;

class_type JIRAClient, { class => 'JIRA::Client' };
coerce JIRAClient,
    from ArrayRef,
    via { Class::MOP::load_class('JIRA::Client'); JIRA::Client->new(@$_); }
;

subtype Filter, as Object, where { $_->does('JIRA::Import::Filter') };
coerce Filter,
    from Str,
    via { 
        my $cls = 'JIRA::Import::Filter::' . $_;
        Class::MOP::load_class($cls);
        $cls->new();
    }
;

subtype Input, as Object, where { $_->does('JIRA::Import::Input') };
coerce Input,
    from HashRef,
    via {
        my $cls = 'JIRA::Import::Input::' . $_->{class};
        Class::MOP::load_class($cls);
        $cls->new($_->{args});
    },
    from Str,
    via {
        die "file-input not implemented yet";
    }
;
1;
