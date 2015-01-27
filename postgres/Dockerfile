# vim:set ft=dockerfile:
FROM postgres:9.4
MAINTAINER Justin Dossey <justin.dossey@newcontext.com>

# this script adds a line to pg_hba.conf to allow all users to connect to all
# databases from all IP addresses.
ADD docker-entrypoint-initdb.d/allow-all-connections.sh /docker-entrypoint-initdb.d/
