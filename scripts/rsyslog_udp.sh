#!/bin/bash

set -euxo pipefail

# set env variables
RSYSLOG_CONF="/etc/rsyslog.conf"

echo "Configuring rsyslog..."

sudo apt-get update -y
sudo apt-get install -y rsyslog
sudo systemctl start rsyslog

# Uncomment the lines for UDP input
sudo sed -i 's/^#module(load="imudp")/module(load="imudp")/' "$RSYSLOG_CONF"
sudo sed -i 's/^#input(type="imudp" port="514")/input(type="imudp" port="514")/' "$RSYSLOG_CONF"

# Append the new ruleset to the configuration file
sudo cat << 'EOF' | sudo tee -a "$RSYSLOG_CONF" > /dev/null

# my ruleset
$template PerHostLog, "/var/log/dsa_%$month%-%$day%-%$year%.log"
$template ManagerLog, "/var/log/dsm_%$month%-%$day%-%$year%.log"
$template DefaultLog, "/var/log/default.log"
if $msg contains 'Deep Security Agent' then -?PerHostLog
else if $msg contains 'Deep Security Manager' then -?ManagerLog
else -?DefaultLog
EOF

# restart rsyslog
sudo systemctl restart rsyslog