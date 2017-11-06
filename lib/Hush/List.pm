package Hush::List;
use strict;
use warnings;
use Hush::RPC;
use Try::Tiny;
use File::Spec::Functions;
use Carp qw/longmess/;
use Hush::Util qw/barf/;

our $VERSION = 20171031;

#TODO: verify
my $MAX_RECIPIENTS      = 55;
my $HUSH_CONFIG_DIR     = $ENV{HUSH_CONFIG_DIR} || catdir($ENV{HOME},'.hush');
my $HUSHLIST_CONFIG_DIR = $ENV{HUSH_CONFIG_DIR} || catdir($HUSH_CONFIG_DIR, 'list');

#TODO: create this if not specified
my $ZADDR = $ENV{HUSH_LIST_ZADDR};

sub _sanity_checks {
    if (!-e $HUSH_CONFIG_DIR ) {
        die "Hush config directory $HUSH_CONFIG_DIR not found! You can set the HUSH_CONFIG_DIR environment variable if it is not ~/.hush";
    }

    my $list_conf = catfile($HUSHLIST_CONFIG_DIR, 'list.conf');

    if (!-e $HUSHLIST_CONFIG_DIR) {
        print "No Hush List config directory found, creating one...\n";
        if (mkdir $HUSHLIST_CONFIG_DIR) {
            print "Created $HUSHLIST_CONFIG_DIR\n";
        } else {
            die "Could not create $HUSHLIST_CONFIG_DIR, bailing out";
        }
        create_default_conf($list_conf);

        if (mkdir catdir($HUSHLIST_CONFIG_DIR,'contacts')) {
            print "Created $HUSHLIST_CONFIG_DIR/contacts\n";
        } else {
            die "Could not create $HUSHLIST_CONFIG_DIR/contacts, bailing out";
        }

    } else {
        # directory exists, does the conf file?
        if (-e $list_conf) {
            # conf file already exists, DO NOTHING
        } else {
            # no config file found, generate one
            create_default_conf($list_conf);
        }
    }
}

sub create_default_conf {
    my ($list_conf) = @_;
    my $time = time;
    open my $fh, ">", $list_conf or die "Could not write file $list_conf ! : $!";

    # when we create a brand new conf, we create brand new funding+nym addrs
    my $rpc             = Hush::RPC->new;
    my $funding_zaddr   = $rpc->z_getnewaddress;
    die "Unable to create funding zaddr" unless $funding_zaddr;

    my $pseudonym_taddr = $rpc->getnewaddress;
    die "Unable to create pseudonym taddr" unless $pseudonym_taddr;

    print $fh "# hushlist config v$Hush::List::VERSION\n";
    print $fh "funding_zaddr=$funding_zaddr\n";
    print $fh "pseudonym_taddr=$pseudonym_taddr\n";
    print $fh "generated=$time\n";
    close $fh;
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
    my ($self,$name)   = @_;
    my $lists          = $self->{lists};
    # a list is simply a list of addresses, which can be looked up by name, and maybe some other metadata
    $lists->{$name} = { recipients => {} };

    my $list_dir           =  catdir($HUSHLIST_CONFIG_DIR,$name);
    if (!-e $list_dir) {
        # create the config dir for the list for the first time
        mkdir $list_dir;
        if ($!) {
            barf "Could not create directory $list_dir !";
        }
    }
    my $list_specific_conf =  catfile($HUSHLIST_CONFIG_DIR,$name,'list.conf');
    my $time = time;

    open my $fh, '>', $list_specific_conf or barf "Could not open $list_specific_conf for writing";
    print $fh "# hushlist $name config\n";
    print $fh "generated=$time\n";
    print $fh "generated_by=Hush::List $Hush::List::VERSION\n";
    close $fh;

    # We consider members.txt the oracle, so users can simply maintain a list
    # of zaddrs into a file, if they want. We sync/serialize to list.json
    # each time we run
    # hust list contacts?
    # TODO: still in flux
    # ~/.hush/list/contacts/
    # ~/.hush/list/LIST_NAME/
    # ~/.hush/list/LIST_NAME/list.conf - list-specific config items
    # ~/.hush/list/LIST_NAME/members.txt  - list member zaddrs, one per line
    # ~/.hush/list/LIST_NAME/list.json - list data, in JSON
    # ~/.hush/list/LIST_NAME/list.png  - user-specified image for list
    return $self;
}

sub add_zaddr {
    my ($self,$name,$zaddr) = @_;
    $zaddr||= '';
    die "Invalid zaddr=$zaddr" unless $zaddr =~ m/^z/;

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

    # TODO: can we make amount=0 and have fee-only xtns?
    # amount is hidden, so it does not identify list messages via metadata
    my $amount  = 1e-4;
    my $fee     = 1e-6;

    # this could blow up for a bajillion reasons...
    try {
        $rpc->z_sendmany($from, $amount, $recipients, $message);
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
