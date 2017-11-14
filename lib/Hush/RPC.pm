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
        #debug    => 1,
    );
    my $info = $rpc->getinfo;
    if ($info) {
        return $rpc,
    } else {
        barf "Unable to make RPC connection to $host:$port !";
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
