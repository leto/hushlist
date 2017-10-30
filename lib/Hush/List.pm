package Hush::List;
use strict;
use warnings;
use Hush::RPC;
use Try::Tiny;


#TODO: verify
my $MAX_RECIPIENTS = 55;

#TODO: create this if not specified
my $ZADDR = $ENV{HUSH_LIST_ZADDR} || die 'No funding zaddr found';

sub new {
    my $hush_list = {};
    $hush_list->{lists} = {};
    return bless $hush_list, 'Hush::List';
}

sub new_list {
    my ($self,$name)        = @_;
    my $lists = $self->{lists};
    die "Hush list $name already exists" if $lists->{$name};
    $lists->{$name}++;
    return $self;
}

# send a message to a Hush List, weeeeee!
sub send_message {
    my ($self,$from,$name,$message) = @_;

    # TODO: better validation
    die "Invalid Hush list name" unless $name;
    die "Hush message cannot be empty" unless $message;
    die "Invalid Hush from address: $from" unless $from;

    my $hush_list = $self->{lists}->{$name} || die "No Hush List by the name of '$name' found";

    my $rpc = Hush::RPC->new;
    my $recipients = $hush_list->recipients;

    die "Max recipients of $MAX_RECIPIENTS exceeded" if (@$recipients > $MAX_RECIPIENTS);

    # prevent an easily searchable single xtn amount
    my $amount  = 1e-4 + (1e-5*rand());

    # this could blow up for a bajillion reasons...
    try {
        $rpc->z_sendmany($from, $amount, $recipients, $memo);
    } catch {
        die "caught RPC error: $_";
    } finally {
        # TODO: notekeeping, logging, etc..
    }

    return $self;
}

sub new_taddr {}
sub new_zaddr {}


1;
