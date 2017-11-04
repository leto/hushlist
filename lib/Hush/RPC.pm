package Hush::RPC;
use strict;
use warnings;
use Bitcoin::RPC::Client;

sub new {
    my $rpc = Bitcoin::RPC::Client->new(
        user     => $ENV{HUSH_RPC_USERNAME} || "hush",
        password => $ENV{HUSH_RPC_PASSWORD} || "puppy",
        host     => "127.0.0.1",
        # set this to 18822 to use testnet
        port     => $ENV{HUSH_RPC_PORT} || 8822,
    );
    return $rpc,
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
