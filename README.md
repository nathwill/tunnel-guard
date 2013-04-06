tunnel-guard
============

perl script to keep Hurricane Electric IPv6 tunnel
up to date with your current dynamic ipv4 endpoint.

add to /etc/crontab:

    @reboot /usr/local/sbin/tunnel-guard.pl >/dev/null 2>&1
    */15 * * * * root /usr/local/sbin/tunnel-guard.pl >/dev/null 2>&1
