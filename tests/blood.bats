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

  assert_failure
  assert_output --partial "Invalid parameter: sugar: \"xxx\"";
}

@test "should add valid urine acid level to sqlite" {
  init_sqlite_database;
  run $BLOOD -a 123

  run $BLOOD -q "SELECT urine FROM urine_acid ORDER BY datetime DESC limit 1;" -e sqlite;

  echo "123" | assert_output;
}

@test "should add valid urine acid level with comment to sqlite" {
  init_sqlite_database;
  run $BLOOD -a 123/'some comment'

  run $BLOOD -q "SELECT urine, comment FROM urine_acid ORDER BY datetime DESC limit 1;" -e sqlite;

  echo "123|some comment" | assert_output;
}

@test "should fail on invalid urine acid level to sqlite" {
  init_sqlite_database;
  run $BLOOD -a xxx

  assert_failure
  assert_output --partial "Invalid parameter: urine acid: \"xxx\"";
}


@test "should fail on invalid systolic xxx/80/80 on sqlite" {
  init_sqlite_database;
  run $BLOOD -p xxx/80/80;

  assert_failure
  assert_output --partial "Invalid parameter: Systolic: \"xxx\"";
}

@test "should fail on invalid diastolic 120/xx/80 on sqlite" {
  init_sqlite_database;
  run $BLOOD -p 120/xx/80;

  assert_failure
  assert_output --partial "Invalid parameter: Diastolic: \"xx\"";
}

@test "should fail on invalid pulse 120/80/xx on sqlite" {
  init_sqlite_database;
  run $BLOOD -p 120/80/xx;

  assert_failure
  assert_output --partial "Invalid parameter: Pulse: \"xx\"";
}

@test "should fail on invalid measurement format xxxxxxxxxx on sqlite" {
  init_sqlite_database;

  run $BLOOD -p xxxxxxxxx;

  assert_failure
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

@test "should add valid urine acid level to pgsql" {
  init_pgsql_database;

  run $BLOOD -a 123 -e pgsql;

  run $BLOOD -q "SELECT urine FROM urine_acid ORDER BY datetime DESC limit 1;" -e pgsql;

  assert_output --partial "123";
}

@test "should add valid urine acid level with comment to pgsql" {
  init_pgsql_database;

  run $BLOOD -a 123/'some comment' -e pgsql;

  run $BLOOD -q "SELECT urine, comment FROM urine_acid ORDER BY datetime DESC limit 1;" -e pgsql;

  assert_output --partial "123 | some comment";
}

@test "should fail on invalid urine acid level to pgsql" {
  init_pgsql_database;

  run $BLOOD -a xxx -e pgsql

  assert_output --partial "Invalid parameter: urine acid: \"xxx\"";
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

# add sample pressure entries to blood table
prepare_sample_pressure() {
  run $BLOOD -p 100/80/81/'first pressure'
  run $BLOOD -p 100/80/82/'second pressure'
  run $BLOOD -p 100/80/83/'third pressure'
  run $BLOOD -p 100/80/84/'fourth pressure'
}

# add sample sugar entries to sugar table
prepare_sample_sugar() {
  run $BLOOD -s 201/'first sugar'
  run $BLOOD -s 202/'second sugar'
  run $BLOOD -s 203/'third sugar'
  run $BLOOD -s 204/'fourth sugar'
}

# add sample urine acid entries to sugar table
prepare_sample_urine_acid() {
  run $BLOOD -a 321/'first acid'
  run $BLOOD -a 322/'second acid'
  run $BLOOD -a 323/'third acid'
  run $BLOOD -a 324/'fourth acid'

}

@test "should list 2 entries of all features on sqlite" {
  init_sqlite_database;

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD -l 2)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should list default entries of all features on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD -l)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

}

@test "should query list of 2 pressure entries on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-pressure 2)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204|fourth sugar" <<< "$result"
  ! grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

}

@test "should query default pressure entries on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-pressure)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204|fourth sugar" <<< "$result"
  ! grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should list of 2 urine_acid entries on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-urine-acid 2)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204|fourth sugar" <<< "$result"
  ! grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"
  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

}

@test "should list default urine acid entries on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-urine-acid)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204|fourth sugar" <<< "$result"
  ! grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"
  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}


@test "should list of 2 sugar entries on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-sugar 2)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should list default sugar entries on sqlite" {
  init_sqlite_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-sugar)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should list 2 entries of all features on pgsql" {
  init_pgsql_database;

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD -l 2)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should list default entries of all fetures on pgsql" {
  init_pgsql_database;

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD -l)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}


@test "should list of 2 pressure entries on pgsql" {
  init_pgsql_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-pressure 2)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204|fourth sugar" <<< "$result"
  ! grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

}

@test "should list of default pressure entries on pgsql" {
  init_pgsql_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-pressure)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  ! grep -q "204|fourth sugar" <<< "$result"
  ! grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}


@test "should list of 2 sugar entries on pgsql" {
  init_pgsql_database

  prepare_sample_pressure
  prepare_sample_sugar

  result="$(run $BLOOD --list-sugar 2)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  ! grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should list of default sugar entries on pgsql" {
  init_pgsql_database

  prepare_sample_pressure
  prepare_sample_sugar
  prepare_sample_urine_acid

  result="$(run $BLOOD --list-sugar)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204|fourth sugar" <<< "$result"
  grep -q "203|third sugar" <<< "$result"
  grep -q "202|second sugar" <<< "$result"
  ! grep -q "201|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
}

@test "should fail with valid error on missing parameter for -A" {
  run $BLOOD -A
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -A"
}

@test "should fail with valid error on missing parameter for --import-urine-acid" {
  run $BLOOD --import-urine-acid
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --import-urine-acid"
}

@test "should fail with valid error on missing parameter for -p" {
  run $BLOOD -p
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -p"
}

@test "should fail with valid error on missing parameter for -s" {
  run $BLOOD -s
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -s"
}

@test "should fail with valid error on missing parameter for --pressure" {
  run $BLOOD --pressure
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --pressure"
}

@test "should fail with valid error on missing parameter for --sugar" {
  run $BLOOD --sugar
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --sugar"
}

@test "should fail with valid error on missing parameter for -q" {
  run $BLOOD -q
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -q"
}

@test "should fail with valid error on missing parameter for --query" {
  run $BLOOD --query
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --query"
}

@test "should fail with valid error on missing parameter for -D" {
  run $BLOOD -D
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -D"
}

@test "should fail with valid error on missing parameter for --dbname" {
  run $BLOOD --dbname
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --dbname"
}

@test "should fail with valid error on missing parameter for -e" {
  run $BLOOD -e
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -e"
}

@test "should fail with valid error on missing parameter for --engine" {
  run $BLOOD --engine
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --engine"
}

@test "should fail with valid error on missing parameter for -H" {
  run $BLOOD -H
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -H"
}

@test "should fail with valid error on missing parameter for --host" {
  run $BLOOD --host
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --host"
}

@test "should fail with valid error on missing parameter for -i" {
  run $BLOOD -i
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -i"
}

@test "should fail with valid error on missing parameter for --initialize" {
  run $BLOOD --initialize
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --initialize"
}

@test "should fail with valid error on missing parameter for -P" {
  run $BLOOD -P
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -P"
}

@test "should fail with valid error on missing parameter for --import-pressure" {
  run $BLOOD --import-pressure
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --import-pressure"
}

@test "should fail with valid error on missing parameter for -S" {
  run $BLOOD -S
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -S"
}

@test "should fail with valid error on missing parameter for --import-sugar" {
  run $BLOOD --import-sugar
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --import-sugar"
}

@test "should fail with valid error on missing parameter for -U" {
  run $BLOOD -U
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -U"
}

@test "should fail with valid error on missing parameter for --user" {
  run $BLOOD --user
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --user"
}

@test "should fail with valid error on missing parameter for -X" {
  run $BLOOD -X
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -X"
}

@test "should fail with valid error on missing parameter for --sync" {
  run $BLOOD --sync
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --sync"
}



