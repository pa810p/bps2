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

  assert_output --partial "psql postgresql://postgres:postgres@db:5432/postgres < createdb.sql";
  assert_output --partial "CREATE SEQUENCE";
  assert_output --partial "CREATE TABLE";
}

@test "should run blood.sh and display usage" {
  run $BLOOD
  assert_output --partial "Usage: /opt/tests/blood.sh";
}

@test "should init sqlite database" {
  init_sqlite_database;
}

@test "should add valid pressure measurement to sqlite" {
  init_sqlite_database;

  run $BLOOD -p 120/80/80

  assert_output --partial "measurement: 120/80/80";
  assert_output --partial "Systolic: \"120\"";
  assert_output --partial "Diastolic: \"80\"";
  assert_output --partial "Pulse: \"80\"";

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM blood ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "120|80|80" | assert_output;
}

@test "should add valid pressure measurement with comment to sqlite" {
  init_sqlite_database;

  run $BLOOD -p 120/80/80/'some comment'

  assert_output --partial "measurement: 120/80/80";
  assert_output --partial "Systolic: \"120\"";
  assert_output --partial "Diastolic: \"80\"";
  assert_output --partial "Pulse: \"80\"";
  assert_output --partial "Comment: \"some comment\"";
  
  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM blood ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "120|80|80|some comment" | assert_output;
}

@test "should add valid sugar level to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123

  run $BLOOD -q "SELECT sugar FROM sugar ORDER BY datetime DESC limit 1;" -e sqlite;

  echo "123" | assert_output;
}

@test "should add valid sugar level with comment to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123/'some comment'

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC limit 1;" -e sqlite;

  echo "123|some comment" | assert_output;
}

@test "should fail on invalid sugar level to sqlite" {
  init_sqlite_database;
  run $BLOOD -s xxx

  assert_output --partial "Invalid parameter: sugar: \"xxx\"";
}

@test "should fail on invalid systolic xxx/80/80 on sqlite" {
  init_sqlite_database;
  run $BLOOD -p xxx/80/80;

  assert_output --partial "Invalid parameter: Systolic: \"xxx\"";
}

@test "should fail on invalid diastolic 120/xx/80 on sqlite" {
  init_sqlite_database;
  run $BLOOD -p 120/xx/80;

  assert_output --partial "Invalid parameter: Diastolic: \"xx\"";
}

@test "should fail on invalid pulse 120/80/xx on sqlite" {
  init_sqlite_database;
  run $BLOOD -p 120/80/xx;

  assert_output --partial "Invalid parameter: Pulse: \"xx\"";
}

@test "should fail on invalid measurement format xxxxxxxxxx on sqlite" {
  init_sqlite_database;

  run $BLOOD -p xxxxxxxxx;

  assert_output --partial "Invalid parameter: Systolic: \"xxxxxxxxx\"";
}

@test "should query sample measurement on sqlite" {
  init_sqlite_database;

  run $BLOOD -p 120/80/80
  run $BLOOD -q "SELECT * FROM blood ORDER BY datetime LIMIT 1;";

  assert_output --partial "|120|80|80|";
}

@test "should query sample suger on sqlite" {
  init_sqlite_database;

  run $BLOOD -s 123
  run $BLOOD -q "SELECT * FROM sugar ORDER BY datetime LIMIT 1;";

  assert_output --partial "123";
}

@test "should init tables on pgsql" {
  init_pgsql_database;
}

@test "should add valid measurement to pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/80/80 -e pgsql

  assert_output --partial "measurement: 120/80/80";
  assert_output --partial "Systolic: \"120\"";
  assert_output --partial "Diastolic: \"80\"";
  assert_output --partial "Pulse: \"80\"";

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM blood ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  # assert_output --regexp "^\s*120\s\|\s*80\s\|\s*80\s\|\s*$"
  assert_output --partial "      120 |        80 |    80 |";
}

@test "should add valid measurement with comment to pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/80/80/'some comment' -e pgsql

  assert_output --partial "measurement: 120/80/80";
  assert_output --partial "Systolic: \"120\"";
  assert_output --partial "Diastolic: \"80\"";
  assert_output --partial "Pulse: \"80\"";
  assert_output --partial "Comment: \"some comment\"";
 
  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM blood ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "      120 |        80 |    80 | some comment";
}

@test "should add valid sugar level to pgsql" {
  init_pgsql_database;

  run $BLOOD -s 123 -e pgsql;

  run $BLOOD -q "SELECT sugar FROM sugar ORDER BY datetime DESC limit 1;" -e pgsql;

  assert_output --partial "123";
}

@test "should add valid sugar level with comment to pgsql" {
  init_pgsql_database;

  run $BLOOD -s 123/'some comment' -e pgsql;

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC limit 1;" -e pgsql;

  assert_output --partial "123 | some comment";
}

@test "should fail on invalid sugar level to pgsql" {
  init_pgsql_database;

  run $BLOOD -s xxx -e pgsql

  assert_output --partial "Invalid parameter: sugar: \"xxx\"";
}

@test "should fail on invalid systolic xxx/80/80 on pgsql" {
  init_pgsql_database;

  run $BLOOD -p xxx/80/80 -e pgsql;

  assert_output --partial "Invalid parameter: Systolic: \"xxx\"";
}

@test "should fail on invalid diastolic 120/xx/80 on pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/xx/80 -e pgsql;

  assert_output --partial "Invalid parameter: Diastolic: \"xx\"";
}

@test "should fail on invalid pulse 120/80/xx on pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/80/xx -e pgsql;

  assert_output --partial "Invalid parameter: Pulse: \"xx\"";
}

@test "should fail on invalid measurement format xxxxxxxxxx on pgsql" {
  init_pgsql_database;

  run $BLOOD -p xxxxxxxxx -e pgsql;

  assert_output --partial "Invalid parameter: Systolic: \"xxxxxxxxx\"";
}

@test "should query sample measurement on pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/80/80 -e pgsql
  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM blood ORDER BY datetime LIMIT 1;" -e pgsql;

  assert_output --partial "      120 |        80 |    80 |";
}

@test "should sync data from sqlite to pgsql" {
  init_pgsql_database;
  init_sqlite_database;

  run $BLOOD -p 133/83/83 -e sqlite
  run $BLOOD -X sqlite:pgsql

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM blood ORDER BY datetime LIMIT 1;" -e pgsql;

  assert_output --partial "      133 |        83 |    83 |";
}

