FROM debian:latest

RUN apt-get update
RUN apt-get -y install sqlite3

RUN apt-get -y install postgresql

# CMD /etc/init.d/postgresql start

# CMD createuser -h localhost -p 2345 -U postgres -w blood
# CMD createdb -h localhost -p 2345 -U postgres -w blood

# CMD ls -al /opt/
#CMD psql postgresql://postgres:postgres@localhost:2345/postgres -c "CREATE DATABASE blood; \
#	CREATE USER blood WITH PASSWORD 'bloodme'; \
#	GRANT ALL PRIVILEDGES ON blood TO blood;"

CMD /bin/bash /opt/tests/bats/bin/bats --print-output-on-failure --verbose-run /opt/tests/blood.bats

