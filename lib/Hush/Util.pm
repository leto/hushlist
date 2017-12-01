package Hush::Util;
use strict;
use warnings;
use Exporter 'import';
use Carp qw/longmess/;
our @EXPORT_OK = qw/
    barf timing now
    is_valid_zaddr
/;
use Time::HiRes qw/gettimeofday tv_interval/;

sub now  { [gettimeofday] }
sub barf { die longmess(@_); }

sub timing {
    my ($t0,$t1) = @_;
    return sprintf "%1.4f", tv_interval($t0,$t1);
}

sub is_valid_zaddr {
    my ($z) = @_;
    #warn "zaddr=$z";

    # TODO: only base58 is valid
    if ($z =~ m/^zc[a-z0-9]{93}$/i) {
        return $z;
    } else {
        return 0;
    }
}


1;
