#!/usr/bin/env perl
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  Copyright (C) 2013, Nathan Williams <nath.e.will@gmail.com>
#
use strict;
use warnings;

use Getopt::Long;
use Sys::Syslog;
use LWP::Simple;

# user vars
my $user;
my $pass;
my $tunnel;
my $iface = "he-ipv6";
my $verbosity = 1;

die "$0 must be run as root.\n" unless $> eq 0;

# get user vars
GetOptions ('user=s' => \$user,
            'pass=s' => \$pass,
            'tunnel=s' => \$tunnel,
            'iface=s' => \$iface,
            'verbosity=s' => \$verbosity,
            );

if ( !defined($user) || !defined($pass) || !defined($tunnel) ) {
    system("perldoc $0"); exit;
}

# script vars
my @urls = ("http://ipv4.icanhazip.com", "http://v4.ipv6-test.com/api/myip.php");
my $he_url = "https://ipv4.tunnelbroker.net/ipv4_end.php?apikey=USER&pass=PASS&ip=IPV4&tid=TUNNEL";
my $cached_v4 = "/var/cache/tunnel-guard";

# do it
exit &main();

# actors;
sub main {
    my $prev_v4 = &get_cache();
    my $cur_v4 = &get_ipv4(); 

    &set_cache($cur_v4) if defined($cur_v4);

    if ( $cur_v4 ne $prev_v4 ) {
        my $updated = &set_ipv4($cur_v4);
        my $rebuilt = &rebuild_tunnel();
    }
}

sub log_it {
    my $priority = shift;
    my $message = shift;
    openlog("tunnel-guard", "ndelay,pid,perror", "user");
    syslog($priority, '%s', $message);
    closelog();
}

sub set_cache {
    my $v4addr = shift;
    my $cache_file = shift;
    open(my $fh, '>', $cache_file) or return 0;
    print $fh "${v4addr}";
    close $fh;
    return 1;
}

sub get_cache {
    open(my $fh, '<', $cached_v4) or return 0;
    chomp(my $v4addr = <$fh>);
    close $fh;
    return $v4addr if is_valid_ipv4($v4addr);
    return undef;
}

sub rebuild_tunnel {
    my $down = qx(/sbin/ifdown $iface);
    sleep 5;
    my $up = qx(/sbin/ifup $iface);
    my $status = qx(/etc/init.d/radvd restart);
}

sub set_ipv4 {
    my $v4addr = shift;
    $he_url =~ s/USER/$user/;
    $he_url =~ s/PASS/$pass/;
    $he_url =~ s/TUNNEL/$tunnel/;
    $he_url =~ s/IPV4/$v4addr/;
    my $result = get($he_url);
    return is_success($result);
}

sub get_ipv4 {
    my $try_1 = rand(@urls);
    my $v4addr = get($try_1);
    if (!is_success($v4addr)) {
        my $try_2 = grep { $_ != $try_1 } @urls;
        $v4addr = get($try_2);
    }
    return $v4addr if is_success($v4addr) && is_valid_ipv4($v4addr);
    return undef;
}

sub is_valid_ipv4 {
    my $v4addr = shift;
    if ( $v4addr =~ m/^(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)$/ ) {
        return 1 if ($1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255);
    }
    return 0;
}

__END__
=head1 AUTHOR

Nathan Williams <nath.e.will@gmail.com>

=head1 SYNOPSIS



=head1 USAGE

tunnel-broker.pl --user <user> --pass <md5pass> --tunnel <tunnel id>

=cut
#/* vim: set ts=4 sw=4: */#
