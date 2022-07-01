#!/bin/sh

if [ -z $DOMAIN ]
then
    export DOMAIN=lorawan.example.local
fi

echo "sleeping"
sleep 5
su postgres -c 'createdb -U test -O test ttn_lorawan'

sed -i -e "s|PLACEHOLDER|${DOMAIN}|g" /ssl/csr.json

sed -i -e "s|thethings.example.com|${DOMAIN}|g" /config/ttn-lw-stack-docker.yml

cfssl gencert -ca=/ssl/ca.pem -ca-key=/ssl/ca-key.pem /ssl/csr.json   | cfssljson -bare /ssl/crt
chmod a+r /ssl/crt-key.pem

ttn-lw-stack -c /config/ttn-lw-stack-docker.yml is-db migrate

ttn-lw-stack -c /config/ttn-lw-stack-docker.yml is-db create-admin-user --id admin --email lorawan@example.com --password letmein
ttn-lw-stack -c /config/ttn-lw-stack-docker.yml is-db create-oauth-client --id cli --name "Command Line Interface" --owner admin --no-secret --redirect-uri "local-callback" --redirect-uri "code"
ttn-lw-stack -c /config/ttn-lw-stack-docker.yml is-db create-oauth-client --id console --name "Console" --owner admin --secret "letmein" --redirect-uri "http://localhost:1885/console/oauth/callback" --redirect-uri "/console/oauth/callback" --logout-redirect-uri "http://localhost:1885/console" --logout-redirect-uri "/console" 


if [ $? -eq 0 ]
then
    [ ! -f /.nostart ] && supervisorctl start stack || echo "Not Starting Stack" 
fi



