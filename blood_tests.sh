#!/usr/bin/env bash

cp blood.sh ./tests/
cp createdb.sql ./tests/
cp createdb.sqlite ./tests/
cp blood_test.properties ./tests/blood.properties

docker network create blood
docker compose up
docker compose down
docker network remove blood

rm ./tests/blood.sh
rm ./tests/createdb.sql
rm ./tests/createdb.sqlite
rm ./tests/blood.properties

