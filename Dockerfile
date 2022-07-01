FROM thethingsnetwork/lorawan-stack:latest 
# TODO pin version

# POSTGRES
USER root:root 
RUN apk update

EXPOSE 5432
RUN apk add postgresql14 postgresql-contrib
RUN su postgres -c 'mkdir -p /tmp/db/postgres'
RUN su postgres -c 'echo 'test' > /tmp/db/.pass'
RUN su postgres -c 'initdb -U test --pwfile=/tmp/db/.pass /tmp/db/postgres/'
RUN mkdir /run/postgresql && chown postgres: /run/postgresql
# server command:  su postgres -c 'postgres -D /tmp/db/postgres/'

RUN apk add redis
EXPOSE 6379

RUN apk add supervisor
RUN mv /etc/supervisord.conf /etc/supervisord.conf.orig

RUN apk add openssl jq
ADD cfssl/cfssl_1.6.1_linux_amd64 /usr/bin/cfssl
ADD cfssl/cfssljson_1.6.1_linux_amd64 /usr/bin/cfssljson
RUN chmod +x /usr/bin/cfssl*

COPY /ssl/ca.pem /ssl/ca.pem
COPY /ssl/ca-key.pem /ssl/ca-key.pem

ENV TTN_LW_BLOB_LOCAL_DIRECTORY /srv/ttn-lorawan/public/blob
ENV TTN_LW_REDIS_ADDRESS localhost:6379
ENV TTN_LW_IS_DATABASE_URI postgres://test:test@localhost:5432/ttn_lorawan?sslmode=disable
ENTRYPOINT /usr/bin/supervisord

COPY /ssl/csr.json /ssl/csr.json
COPY supervisord.conf /etc/supervisord.conf
COPY ttn-lw-stack-docker.yml /config/ttn-lw-stack-docker.yml
COPY init.sh /init.sh
