package Hush::List;
use strict;
use warnings;
use Hush::RPC;
use Try::Tiny;
use File::Spec::Functions;

#TODO: verify
my $MAX_RECIPIENTS      = 55;
my $HUSH_CONFIG_DIR     = $ENV{HUSH_CONFIG_DIR}     || catdir($ENV{HOME},'.hush');
my $HUSHLIST_CONFIG_DIR = $ENV{HUSHLIST_CONFIG_DIR} || catdir($HUSHLIST_CONFIG_DIR, 'list');

#TODO: create this if not specified
my $ZADDR = $ENV{HUSH_LIST_ZADDR} || die 'No funding zaddr found';

sub _sanity_checks {
    if (!-e $HUSH_CONFIG_DIR ) {
        die "Hush config directory $HUSH_CONFIG_DIR not found! You can set the HUSH_CONFIG_DIR environment variable if it is not ~/.hush";
    }

    if (!-e $HUSHLIST_CONFIG_DIR) {
        print "No Hush List config directory found, creating one...\n";
        mkdir $HUSHLIST_CONFIG_DIR;
    }
}

sub new {
    my ($options)       = @_;
    my $hush_list       = {};
    my $rpc             = Hush::RPC->new($options);

    # we only need a single RPC connection
    $hush_list->{rpc}   = $rpc;
    $hush_list->{lists} = {};

    _sanity_checks();

    return bless $hush_list, 'Hush::List';
}

sub new_list {
    my ($self,$name)        = @_;
    my $lists = $self->{lists};
    # a list is simply a list of addresses, which can be looked up by name, and maybe some other metadata
    $lists->{$name} = { recipients => {} };
    return $self;
}

sub add_zaddr {
    my ($self,$name,$zaddr) = @_;
    die "Invalid zaddr=$zaddr" unless $zaddr;

    my $lists = $self->{lists};
    my $list  = $lists->{$name};

    die "Hush list $list does not exist" unless $list;
    $list->{recipients}->{$zaddr}++;
    return $self;
}

sub remove_zaddr {
    my ($self,$name,$zaddr) = @_;
    die "Invalid zaddr=$zaddr" unless $zaddr;

    my $lists = $self->{lists};
    my $list  = $lists->{$name};

    die "Hush list $list does not exist" unless $list;

    delete $list->{recipients}->{$zaddr};

    return $self;
}

# send a message to a Hush List, weeeeee!
sub send_message {
    my ($self,$from,$name,$message) = @_;
    my $rpc = $self->{rpc};

    # TODO: better validation
    die "Invalid Hush list name" unless $name;
    die "Hush message cannot be empty" unless $message;
    die "Invalid Hush from address: $from" unless $from;

    my $hush_list = $self->{lists}->{$name} || die "No Hush List by the name of '$name' found";

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
