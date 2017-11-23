package Hush::RPC;
use strict;
use warnings;
use Bitcoin::RPC::Client;
use Hush::Util qw/barf/;

sub new {
    my $port = $ENV{HUSH_RPC_PORT} || 8822;
    my $host = "127.0.0.1";

    my $rpc = Bitcoin::RPC::Client->new(
        port     => $port, # set this to 18822 to use testnet
        host     => $host,
        user     => $ENV{HUSH_RPC_USERNAME} || "hush",
        password => $ENV{HUSH_RPC_PASSWORD} || "hushmegently",
        # rpc calls, how do they work?
        debug    => $ENV{HUSH_DEBUG} || 0,
    );
    my $info = $rpc->getinfo;
    if ($info) {
        return $rpc,
    } else {
        my $coins = {
            8822 => 'HUSH',
           18822 => 'TUSH',
            8232 => 'ZEC',
           18232 => 'TAZ',
        };
        my $sites = {
            "HUSH" => 'https://myhush.org',
            "TUSH" => 'https://myhush.org',
            "ZEC"  => 'https://z.cash',
            "TAZ"  => 'https://z.cash',
        };
        my $coin = $coins->{$port} || 'cryptocoin';
        my $site = $sites->{$coin} || 'https://github.com/leto/hushlist';
        print "Unable to make RPC connection to $coin full node at $host:$port !\n";
        print "Your $coin full node is not running, or not accessible at that port :(\n";
        print "See $site for more information about this privacy coin\n";
        exit(1);
    }
}

1;

__DATA__

my $chaininfo = $btc->getblockchaininfo;
my $blocks    = $chaininfo->{blocks};

# Set the transaction fee
#     https://bitcoin.org/en/developer-reference#settxfee
my $settx = $btc->settxfee($feerate);
 
# Check your balance 
# (JSON::Boolean objects must be passed as boolean parameters)
#     https://bitcoin.org/en/developer-reference#getbalance
my $account = '';
my $balance = $btc->getbalance($account, 1, JSON::true);

# Send to an address
#     https://bitcoin.org/en/developer-reference#sendtoaddress
my $txid = $rpc->sendtoaddress("1Ky49cu7FLcfVmuQEHLa1WjhRiqJU2jHxe","0.01");
