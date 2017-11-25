package Hush::List;
use strict;
use warnings;
use Hush::RPC;
use Try::Tiny;
use File::Spec::Functions;
use Hush::Util qw/barf/;
use File::Slurp;
use Hush::Logger qw/debug/;
use JSON;

# as per z_sendmany rpc docs
my $MAX_RECIPIENTS      = 54;
my $HUSH_CONFIG_DIR     = $ENV{HUSH_CONFIG_DIR} || catdir($ENV{HOME},'.hush');
my $HUSHLIST_CONFIG_DIR = $ENV{HUSH_CONFIG_DIR} || catdir($HUSH_CONFIG_DIR, 'list');
our $VERSION            = 20171031;
my $rpc                 = Hush::RPC->new;

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
        create_default_conf($rpc,$list_conf);

        if (mkdir catdir($HUSHLIST_CONFIG_DIR,'contacts')) {
            print "Created $HUSHLIST_CONFIG_DIR/contacts\n";
        } else {
            barf "Could not create $HUSHLIST_CONFIG_DIR/contacts, bailing out";
        }

    } else {
        # directory exists, does the conf file?
        if (-e $list_conf) {
            # conf file already exists, DO NOTHING
            debug("detected existing $list_conf");
        } else {
            # no config file found, generate one
            create_default_conf($rpc,$list_conf);
        }
    }
}

sub create_default_conf {
    my ($rpc,$list_conf) = @_;

    # when we create a brand new conf, we create brand new funding+nym addrs
    my $funding_zaddr   = $rpc->z_getnewaddress;
    barf "Unable to create funding zaddr" unless $funding_zaddr;

    my $pseudonym_taddr = $rpc->getnewaddress;
    barf "Unable to create pseudonym taddr" unless $pseudonym_taddr;

    debug("setting funding_zaddr=$funding_zaddr, pseudonym_taddr=$pseudonym_taddr");

    my $time = time;
    # this will overwrite an existing conf!!! should we back up last version?
    open my $fh, ">", $list_conf or barf "Could not write file $list_conf ! : $!";
    print $fh "# hushlist config v$Hush::List::VERSION\n";
    print $fh "funding_zaddr=$funding_zaddr\n";
    print $fh "pseudonym_taddr=$pseudonym_taddr\n";
    print $fh "generated=$time\n";
    close $fh;

    debug("created new config file $list_conf");
}

sub new {
    my ($rpc,$options)  = @_;
    my $hush_list       = {};

    # we only need a single RPC connection
    $hush_list->{rpc}   = $rpc;
    $hush_list->{lists} = {};

    _sanity_checks();

    return bless $hush_list, 'Hush::List';
}

sub list_members {
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

    print "Hushlist contacts:\n ";

    # other possibilties: KMD, ZEN, others?
    my @chains = qw/hush tush zec taz/;

    for my $chain (@chains) {
        my $contacts_file = catdir($HUSHLIST_CONFIG_DIR,"$chain-contacts.txt");
        if (-e $contacts_file) {
            my @contacts      = read_file($contacts_file);
            my $uchain        = uc($chain);
            print "\t- " . scalar(@contacts) . " $uchain contacts\n";
        }
    }
}

sub _hushlist_exists {
    my ($name)   = @_;
    my $list_dir =  catdir($HUSHLIST_CONFIG_DIR,$name);
    return (-e $list_dir) ? 1 : 0;
}

sub exit_unless_hushlist_exists {
    my ($name)   = @_;
    if (!_hushlist_exists($name)) {
        print "Hushlist $name does not exist!\n";
        exit(1);
    };
}

# show details about a particular hushlist
sub show {
    my ($self,$name)   = @_;

    exit_unless_hushlist_exists($name);

    my $list_specific_conf = catfile($HUSHLIST_CONFIG_DIR,$name,'list.conf');
    my %list_conf          = read_file( $list_specific_conf ) =~ /^(\w+)=(.*)$/mg ;

    print "Hushlist: $name\n";
    print "Recents memos:\n";
    my $memos_exist = 0;

    # TODO: detect the last N memos to our zaddr for this list
    if ($memos_exist) {
    } else {
        print "No memos found!\n";
    }
}

# show details about a particular hushlist
sub status {
    my ($self,$name)   = @_;

    exit_unless_hushlist_exists($name);

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
    my $time               = time;
    my $sending_zaddr      = $rpc->z_getnewaddress;

    {
    open my $fh, '>', $list_specific_conf or barf "Could not open $list_specific_conf for writing";
    print $fh "# hushlist $name config v$Hush::List::VERSION\n";
    # every list has a unique sending zaddr, so there is no metadata leaked
    # across one user sending messages to multiple hushlists
    print $fh "sending_zaddr=$sending_zaddr\n";
    print $fh "generated=$time\n";
    # default chain is hush for now
    # changing the chain of an existing list means that the subset
    # of members that have addresses in the local contact list for the
    # new chain will receive message, or operation aborts if no valid
    # contacts on new chain
    print $fh "chain=hush\n";
    close $fh;
    }

    {
    open my $fh, '>', $member_list or barf "Could not open $member_list for writing";
    print $fh "";
    close $fh;
    }

    # We consider members.txt the oracle, so users can simply maintain a simple
    # text file of one item per line, and other files serialized version
    # ~/.hush/list/LIST_NAME/
    # ~/.hush/list/LIST_NAME/list.conf - list-specific config items
    # ~/.hush/list/LIST_NAME/members.txt  - list member zaddrs, one per line
    # ~/.hush/list/LIST_NAME/list.json - list data, in JSON
    # ~/.hush/list/LIST_NAME/list.png  - user-specified image for list
    return $self;
}

# make a local hushlist PUBLIC by publishing its PRIVKEY
# to the blockchain via OP_RETURN. This is a ONE WAY PROCESS!!!
# You can not make a public hushlist private again, it's privkey is in the wild,
# but we CAN make 
sub public {
    my ($self,$name) = @_;
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

# send a memo to a Hush List, weeeeee!
sub send_memo {
    my ($self,$rpc, $name,$memo) = @_;

    # TODO: better validation
    barf "Invalid Hush list name" unless $name =~ m/^([a-z0-9]+)$/i;
    barf "Hush memo cannot be empty" unless $memo;

    my $debug = sub { debug("send_memo: @_") };

    # each hush list has a sending_zaddr defined at time of creation
    # which is used to send to this list
    my $list_specific_conf = catfile($HUSHLIST_CONFIG_DIR,$name,'list.conf');
    unless (-e $list_specific_conf) {
        barf "Hushlist config for $name list not found!";
    }

    my %list_conf          = read_file( $list_specific_conf ) =~ /^(\w+)=(.*)$/mg ;
    my $from               = $list_conf{sending_zaddr};
    # default should probably be TUSH, but meh...
    my $chain              = $list_conf{chain} || 'hush';

    #barf "Invalid Hushlist chain! $chain" unless $chain =~ m/$(tush|hush)$/i;
    barf "Invalid Hush from address! $from" unless $from;

    my $list_members_file = catfile($HUSHLIST_CONFIG_DIR,$name,'members.txt');
    unless (-e $list_members_file) {
        barf "No members file found for Hushlist $name!";
    }
    my %list_members   = read_file( $list_members_file ) =~ /^(.*)$/mg ;
    $debug->("list_members=" . join(",",keys %list_members));
    use Data::Dumper;

    # Now that we have all the list member pseudonyms, look them
    # up in the appropriate chain

    my $contacts_file = catdir($HUSHLIST_CONFIG_DIR,"$chain-contacts.txt");
    unless (-e $contacts_file) {
        barf "Could not find Hushlist contacts for chain $chain!";
    }

    # grab all contacts
    # TODO: serialize/make more effiecient/etc
    my %contacts   = read_file( $contacts_file ) =~ /^([a-z0-9]+) (.*)$/mgi ;
    $debug->("contacts=" . join(",",keys %contacts));
    # this is the subset of contacts that we are sending to on this hushlist
    # with proper amount/memo keys to appease the z_sendmany gods
    my $list_addrs = { };

    # This must be a string to make JSON elder gods happy
    my $amount  = "0.00"; # amount is hidden in (z,z) xtns, so it does not identify list messages via metadata
    my $raw_memo  = unpack("h*",$memo); # backend wants hex-encoded memo-field
    $debug->("memo=$memo");
    $debug->("raw_memo=$memo");

    while (my ($addr, $contact) = each %contacts) {
        $debug->("adding $contact => $addr to recipients and sending: $memo");
        $list_addrs->{$contact} = {
            address             => $addr,
            amount              => $amount,
            memo                => $raw_memo,
        };
    }
    warn Dumper [ $list_addrs ];

    barf "Max recipients of $MAX_RECIPIENTS exceeded" if (keys %contacts > $MAX_RECIPIENTS);

    $debug->("initiating z_sendmany");

    my $default_fee  = 1e-4;
    my $fee          = $ENV{HUSHLIST_FEE} ? sprintf "%.8f", $ENV{HUSHLIST_FEE} : $default_fee;
    my $balance      = $rpc->z_gettotalbalance;
    my $zbalance     = $balance->{private};

    # this is the total cost to send the current Hush
    # transaction to N recipients eac with $fee
    my $recipients = (keys %contacts);
    my $total_cost = $fee * $recipients;
    my $CURR = "HUSH";
    $debug->("calculated total_cost=$total_cost $CURR for $recipients recipients");

    if ($zbalance < $fee) {
        $debug->("Insufficient zaddr balance to pay even one fee=$fee");
        return;
    }elsif ($zbalance < $total_cost) {
        $debug->("Insufficient zaddr balance to pay full xtn fee=$total_cost to $recipients recipients with balance=$zbalance");
        return;
    }

    # this could blow up for a bajillion reasons...
    #try {
#       z_sendmany
#       Arguments:
#       1. "fromaddress"         (string, required) The taddr or zaddr to send the funds from.
#       2. "amounts"             (array, required) An array of json objects representing the amounts to send.
#           [{
#             "address":address  (string, required) The address is a taddr or zaddr
#             "amount":amount    (numeric, required) The numeric amount in ZEC is the value
#             "memo":memo        (string, optional) If the address is a zaddr, raw data represented in hexadecimal string format
#           }, ... ]
#       3. minconf               (numeric, optional, default=1) Only use funds confirmed at least this many times.
#       4. fee                   (numeric, optional, default=0.0001) The fee amount to attach to this transaction.

    my $opid = $rpc->z_sendmany($from, [values $list_addrs]);

    if (defined $opid) {
        $debug->("z_sendmany opid=$opid from $from");
        # omg we got an opid, lets see what is up
        my @opids = ( $opid );
        my $status = $rpc->z_getoperationstatus([@opids]);
        if ($status) {
            $debug->("$opid has status=$status");
        } else {
            $debug->("no status for opid=$opid");
        }
    } else {
        $debug->("z_sendmany failed!");
    }

    return $self;
}

sub new_taddr {}
sub new_zaddr {}

1;
