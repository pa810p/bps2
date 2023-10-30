#!/bin/bash
#################################################################
# Launches tests against blood.sh
# Author:     Paweł Prokop (pa810p@gmail.com)
# Repository: https://github.com/pa810p/bps2
# License:    GNU General Public License v3.0  see: LICENSE
#################################################################

cp blood.sh ./tests/
cp createdb.sql ./tests/
cp createdb.sqlite ./tests/
cp blood_test.properties ./tests/blood.properties

cd tests

docker network create blood
docker compose up
docker compose down
docker network remove blood

cd ..

rm ./tests/blood.sh
rm ./tests/createdb.sql
rm ./tests/createdb.sqlite
rm ./tests/blood.properties
