#!/bin/bash

set -euxo pipefail

echo "Executing ssl_cert_generator.sh"

# Execute ssl_cert_generator.sh
./ssl_cert_generator.sh

# set env variables
RSYSLOG_CONF="/etc/rsyslog.conf"

echo "Configuring rsyslog..."

sudo apt-get update -y
sudo apt-get install -y rsyslog
sudo systemctl start rsyslog

# Append the tls configuration and new ruleset to the configuration file
sudo cat << 'EOF' | sudo tee -a "$RSYSLOG_CONF" > /dev/null

# tls 
global(
DefaultNetstreamDriver="gtls"
DefaultNetstreamDriverCAFile="/etc/pki/syslog/rootCA.pem"
DefaultNetstreamDriverCertFile="/etc/pki/syslog/devopssampletesting.pem"
DefaultNetstreamDriverKeyFile="/etc/pki/syslog/devopssampletesting_private.pem"
)

module(load="imtcp" StreamDriver.Name="gtls" StreamDriver.Mode="1" StreamDriver.AuthMode="anon")
input(type="imtcp" port="6514")

# my ruleset
$template PerHostLog, "/var/log/dsa.log"
$template ManagerLog, "/var/log/dsm.log"
$template DefaultLog, "/var/log/default.log"
if $msg contains 'Deep Security Agent' then -?PerHostLog
else if $msg contains 'Deep Security Manager' then -?ManagerLog
else -?DefaultLog
EOF

# install necessary tools
sudo apt-get install -y gnutls
sudo apt-get install -y rsyslog-gnutls

# restart rsyslog
sudo systemctl restart rsyslog