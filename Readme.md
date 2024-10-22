1. Do Terraform init and apply
2. Get the public IP of rsyslog and use it to configure your syslog in C1WS or V1 SWP
3. (Can use API call to automate task)

Note: For TLS configuration, please change file permission of rsyslog_tls.sh and ssl_cert_generator.sh (sudo chmod +x rsyslog_tls.sh ssl_cert_generator.sh) -- Might encounte errors...