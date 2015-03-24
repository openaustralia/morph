#!/bin/sh
# Remove rules for redirecting web traffic from the docker containers to the
# mitmproxy running in transparent mode

# Use add_iptables_rules.sh to add rules

# Need to run this as root

iptables -t nat -D PREROUTING -i docker0 -p tcp --dport 80 -j REDIRECT --to-ports 8080
iptables -t nat -D PREROUTING -i docker0 -p tcp --dport 443 -j REDIRECT --to-ports 8080
