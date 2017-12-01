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

sub now { [gettimeofday] }
sub barf { die longmess(@_); }

sub timing {
    my ($t0,$t1) = @_;
    return sprintf "%1.4f", tv_interval($t0,$t1);
}

sub is_valid_zaddr {
    my ($zaddr) = @_;
    # TODO: only base58 is valid
    return ($zaddr =~ m/^zc[A-z0-9]{94,94}$/) ? 1 : 0;
}


1;
