package Hush::Util;
use strict;
use warnings;
use Exporter 'import';
use Carp qw/longmess/;
our @EXPORT_OK = qw/
    barf timing now
    is_valid_zaddr
    is_valid_taddr
    is_valid_privkey
/;
use Time::HiRes qw/gettimeofday tv_interval/;

sub now  { [gettimeofday] }
sub barf { die longmess(@_); }

sub timing {
    my ($t0,$t1) = @_;
    return sprintf "%1.4f", tv_interval($t0,$t1);
}

# valid for HUSH+ZEC, we need tables for other prefixes
sub is_valid_zaddr {
    my ($z) = @_;
    #warn "zaddr=$z";

    # TODO: only base58 is valid
    # TODO: support Zcash Sapling addresses
    if ($z =~ m/^zc[a-z0-9]{93}$/i) {
        return 1;
    } else {
        return 0;
    }
}

# valid for HUSH+ZEC, we need tables for other prefixes
sub is_valid_taddr {
    my ($t) = @_;

    # TODO: only base58 is valid
    # HUSH/ZEC and most zec forks
    if ($t =~ m/^t1[a-z0-9]{33}$/i) {
        return 1;
    } elsif ($t =~ m/^R[a-z0-9]{34}$/i) { # KMD and KMD asset chains
        return 1;
    } else {
        return 0;
    }
}
# we never look at taddr privkeys
# valid for HUSH+ZEC, we need tables for other prefixes
sub is_valid_privkey {
    my ($p) = @_;
    $p =~ s!^hushlist://!!g;
    # TODO: support KMD + new Sapling privkeys
    if ($p =~ m/^SK[a-z0-9]{53}$/i) {
        return 1;
    } else {
        return 0;
    }
}


1;
