#!/usr/bin/env bash

BLOOD_DIR="/opt/tests";
BLOOD_DB="postgres.db";

BLOOD="$BLOOD_DIR/blood.sh";

setup_file() {
  echo 1 >> /tmp/setup_file;
}

teardown_file() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  PATH="$DIR/..:$PATH";
  cd $DIR;

  rm /tmp/setup_file;
  run $BLOOD -q "COPY (SELECT 1) TO PROGRAM 'kill -INT \`head -1 postmaster.pid\`'" -e pgsql;
  run $BLOOD -q "COPY (SELECT 1) TO PROGRAM 'pg_ctl -D stop'" -e pgsql;

  rm -f "$BLOOD_DIR/$BLOOD_DB";
}

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  PATH="$DIR/..:$PATH";
  cd $DIR;
}


teardown() {
  rm -f /tmp/output
}

init_sqlite_database() {
  rm -f "$BLOOD_DIR/$BLOOD_DB";

  run $BLOOD -i createdb.sqlite

  assert [ -e "$BLOOD_DIR/$BLOOD_DB" ]
}

init_pgsql_database() {
  run $BLOOD -i createdb.sql -e pgsql

  assert_output --partial "psql postgresql://postgres:xxxxxxxx@db:5432/postgres < createdb.sql";
  assert_output --partial "CREATE SEQUENCE";
  assert_output --partial "CREATE TABLE";
}