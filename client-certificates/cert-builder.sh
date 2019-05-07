#!/usr/bin/env bash
# Original Work: adamcath
# Bash script aggregates all openssl related commands needed to generate a CA and client cert.
# 1. Install nginx and openssl
# 2. Run command, set passphrases and ensure Common Name is set to domain FQDN. Other fields can be set as desired
# 3. In NGINX site-available config: ssl_certificate and ssl_certificate_key set to server.crt and server.key respectively
# 4. Also in NGINX Add ssl_client_certificate /path/to/ca.crt and ssl_verify_client on;
# 5. Restart nginx (test with nginx -t to ensure config is good)
# 6. Import p12 file into client browser and use to auth to SSL protected sites. Perform HTTP -> HTTPS redir on * or per basis.

set -o errexit
set -o pipefail
set -o nounset

echo "########## Creating CA stuff"
openssl genrsa -des3 -out ca.key 4096 # CA key
openssl req -new -x509 -days 365 -key ca.key -out ca.crt # CA cert

echo "########## Creating client stuff"
openssl genrsa -des3 -out client.key 4096 # Client key
openssl req -new -key client.key -out client.csr # Client signing request
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt # Client cert
openssl pkcs12 -export -clcerts -in client.crt -inkey client.key -out client.p12 # Client cert+key
openssl verify -CAfile ca.crt client.crt # Verify client

# Create a server key and cert, sign the cert
echo "########## Creating server stuff"
openssl genrsa -out server.key 2048 # Server key
openssl req -key server.key -new -sha256 -out server.csr # Server signing request
openssl x509 -req -days 360 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -sha256 # Server cert
openssl verify -CAfile ca.crt server.crt # Verify server

echo "########## Created all crypto stuff!"
