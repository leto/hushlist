package Hush::App;
use strict;
use warnings;
use Try::Tiny;
use lib 'lib';
use Hush::List;
use Hush::Util qw/barf/;
use Data::Dumper;
use Hush::RPC;

my $COMMANDS  = {
    "add"     => \&add,
    "contact" => \&Hush::List::contact,
    "help"    => \&help,
    "new"     => \&new,
    "remove"  => \&remove,
    "send"    => \&send,
    "show"    => \&show,
    "status"  => \&status,
    #"public"  => \&public,
};
# TODO: translations
my %HELP      = (
    "add"     => "Add a contact to a Hushlist",
    "contact" => "Manage Hushlist contacts",
    "help"    => "Get your learn on",
    "new"     => "Create a new Hushlist",
    "remove"  => "Remove a Hushlist",
    "send"    => "Send a new new Hushlist memo",
    "status"  => "Get overview of Hushlists or a specific Hushlist",
    "show"    => "Show Hushlist memos",
    #"public"  => "Make a private Hushlist public",
);

my $rpc           = Hush::RPC->new;

sub show_status {
    my $chaininfo     = $rpc->getblockchaininfo;
    my $walletinfo    = $rpc->getwalletinfo;
    my $chain         = $chaininfo->{chain};
    my $blocks        = $chaininfo->{blocks};
    my $balance       = $rpc->z_gettotalbalance;
    my $tbalance      = sprintf "%.8f", $balance->{transparent};
    my $zbalance      = sprintf "%.8f", $balance->{private};
    my $total_balance = $balance->{total};
    my $blockchain    = "HUSH";

    print "Hushlist v$Hush::List::VERSION running on $blockchain ${chain}net, $blocks blocks\n";
    print "Balances: transparent $tbalance HUSH, private $zbalance HUSH\n";
}

my $options   = {};
my $list      = Hush::List->new($rpc, $options);
my $command   = shift || help();

sub run {
    my ($command) = @_;
    #print "Running command $command\n";
    my $cmd = $COMMANDS->{$command};

    show_status();

    if ($cmd) {
        $cmd->(@ARGV);
    } else {
        usage();
    }
}

sub add {
    my ($list_name,$zaddr) = @_;

    $list->add_zaddr($list_name,$zaddr);
}

sub remove {
    my ($list_name,$zaddr) = @_;

    $list->remove_zaddr($list_name,$zaddr);
}

sub send {
    my ($list_name,$memo) = @_;

    $list->send_memo($rpc, $list_name, $memo);
}

sub help {
    print "Available Hushlist commands:\n";
    my @cmds = sort keys %$COMMANDS;
    for my $cmd (@cmds) {
        print "\t$cmd\t: $HELP{$cmd}\n";
    }
}

sub show {
    my ($name,@args) = @_;
    if ($name) {
        my $status = $list->show($name);
    } else {
        my $status = $list->global_show;
    }
}

sub usage {
    print "Usage: $0 command [subcommand] [options]\n";
    print "$0 help for more details :)\n";
}

sub status {
    my $name = shift;
    if ($name) {
        my $status = $list->status($name);
    } else {
        my $status = $list->global_status;
    }
}

# make a hushlist public by publishing its privkey in OP_RETURN data
# This operation costs HUSH and cannot be undone!!! It sends private
# keys to the PUBLIC BLOCKCHAIN
sub publicize {
    my ($name) = @_;

    $list->publicize($name);
}

sub new {
    my $name = shift || '';
    #TODO: better validation and allow safe unicode stuff
    barf "Invalid hushlist name '$name' !" unless $name && ($name =~ m/^[A-z0-9_-]{0,64}/);

    $list->new_list($name);
    print "hushlist '$name' created, enjoy your private comms ;)\n";
}

