package Hush::Util;
use strict;
use warnings;
use Exporter 'import';
use Carp qw/longmess/;
our @EXPORT_OK = qw/ barf timing now/;
use Time::HiRes qw/gettimeofday tv_interval/;

sub now { [gettimeofday] }
sub barf { die longmess(@_); }

sub timing {
    my ($t0,$t1) = @_;
    return sprintf "%1.4f", tv_interval($t0,$t1);
}

1;
