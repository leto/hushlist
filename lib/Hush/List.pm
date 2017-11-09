package Hush::List;
use strict;
use warnings;
use Hush::RPC;
use Try::Tiny;
use File::Spec::Functions;
use Carp qw/longmess/;
use Hush::Util qw/barf/;
use File::Slurp;

our $VERSION = 20171031;

# as per z_sendmany rpc docs
my $MAX_RECIPIENTS      = 54;
my $HUSH_CONFIG_DIR     = $ENV{HUSH_CONFIG_DIR} || catdir($ENV{HOME},'.hush');
my $HUSHLIST_CONFIG_DIR = $ENV{HUSH_CONFIG_DIR} || catdir($HUSH_CONFIG_DIR, 'list');

sub _sanity_checks {
    if (!-e $HUSH_CONFIG_DIR ) {
        barf "Hush config directory $HUSH_CONFIG_DIR not found! You can set the HUSH_CONFIG_DIR environment variable if it is not ~/.hush";
    }

    my $list_conf = catfile($HUSHLIST_CONFIG_DIR, 'list.conf');

    if (!-e $HUSHLIST_CONFIG_DIR) {
        print "No Hush List config directory found, creating one...\n";
        if (mkdir $HUSHLIST_CONFIG_DIR) {
            print "Created $HUSHLIST_CONFIG_DIR\n";
        } else {
            barf "Could not create $HUSHLIST_CONFIG_DIR, bailing out";
        }
        create_default_conf($list_conf);

        if (mkdir catdir($HUSHLIST_CONFIG_DIR,'contacts')) {
            print "Created $HUSHLIST_CONFIG_DIR/contacts\n";
        } else {
            barf "Could not create $HUSHLIST_CONFIG_DIR/contacts, bailing out";
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

    # when we create a brand new conf, we create brand new funding+nym addrs
    my $rpc             = Hush::RPC->new;
    my $funding_zaddr   = $rpc->z_getnewaddress;
    barf "Unable to create funding zaddr" unless $funding_zaddr;

    my $pseudonym_taddr = $rpc->getnewaddress;
    barf "Unable to create pseudonym taddr" unless $pseudonym_taddr;

    warn "funding=$funding_zaddr, nym=$pseudonym_taddr";

    my $time = time;
    open my $fh, ">", $list_conf or barf "Could not write file $list_conf ! : $!";
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

# show overview of current hushlists
sub global_status {
    my ($self) = @_;
    my @hushlists = map { -d $_ && $_ } glob catdir($HUSHLIST_CONFIG_DIR,'*');
    print "Hushlists:\n";
    for my $hushlist (@hushlists) {
        my $members_file = catfile($hushlist,'members.txt');
        if (-e $members_file) {
            my @members      = read_file($members_file);
            print "\t- $hushlist: " . scalar(@members) . " members \n";
        }
    }
}

# show details about a particular hushlist
sub status {
    my ($self,$name)   = @_;

    my $list_dir           =  catdir($HUSHLIST_CONFIG_DIR,$name);
    if (!-e $list_dir) {
        barf "Hushlist $name does not exist!";
    } else {
        my $list_specific_conf = catfile($HUSHLIST_CONFIG_DIR,$name,'list.conf');
        my %list_conf          = read_file( $list_specific_conf ) =~ /^(\w+)=(.*)$/mg ;
        my $member_list        = catfile($HUSHLIST_CONFIG_DIR,$name,'members.txt');
        my @members            = read_file($member_list);
        my @nicknames          = map { m/^[^ ]+(.*)/ } @members;
        my $num_members        = @members;
        print "Hushlist '$name' has $num_members members, generated at $list_conf{generated}\n";
        #map { print "\t - $_\n" } @nicknames;
        map { print "\t - $_" } @members;
    }
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
        if (!-e $list_dir) {
            barf "Could not create directory $list_dir !";
        }
    } else {
        barf "Hushlist $name already exists!";
    }
    my $list_specific_conf =  catfile($HUSHLIST_CONFIG_DIR,$name,'list.conf');
    my $member_list        =  catfile($HUSHLIST_CONFIG_DIR,$name,'members.txt');
    my $time = time;

    {
    open my $fh, '>', $list_specific_conf or barf "Could not open $list_specific_conf for writing";
    print $fh "# hushlist $name config v$Hush::List::VERSION\n";
    print $fh "generated=$time\n";
    close $fh;
    }

    {
    open my $fh, '>', $member_list or barf "Could not open $member_list for writing";
    print $fh "";
    close $fh;
    }

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
    barf "Invalid zaddr=$zaddr" unless $zaddr =~ m/^z/;

    my $lists = $self->{lists};
    my $list  = $lists->{$name};

    barf "Hush list $list does not exist" unless $list;
    $list->{recipients}->{$zaddr}++;
    return $self;
}

sub remove_zaddr {
    my ($self,$name,$zaddr) = @_;
    barf "Invalid zaddr=$zaddr" unless $zaddr;

    my $lists = $self->{lists};
    my $list  = $lists->{$name};

    barf "Hush list $list does not exist" unless $list;

    delete $list->{recipients}->{$zaddr};

    return $self;
}

# send a message to a Hush List, weeeeee!
sub send_message {
    my ($self,$from,$name,$message) = @_;
    my $rpc = $self->{rpc};

    # TODO: better validation
    barf "Invalid Hush list name" unless $name;
    barf "Hush message cannot be empty" unless $message;
    barf "Invalid Hush from address: $from" unless $from;

    my $hush_list = $self->{lists}->{$name} || barf "No Hush List by the name of '$name' found";

    my $recipients = $hush_list->recipients;

    barf "Max recipients of $MAX_RECIPIENTS exceeded" if (@$recipients > $MAX_RECIPIENTS);

    # TODO: can we make amount=0 and have fee-only xtns?
    # amount is hidden, so it does not identify list messages via metadata
    my $amount  = 1e-4;
    my $fee     = 1e-6;

    # this could blow up for a bajillion reasons...
    try {
        my $txid = $rpc->z_sendmany($from, $amount, $recipients, $message);
        warn "txid=$txid";
    } catch {
        barf "caught RPC error: $_";
    } finally {
        # TODO: notekeeping, logging, etc..
    }

    return $self;
}

sub new_taddr {}
sub new_zaddr {}


1;
