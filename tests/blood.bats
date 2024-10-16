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

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime DESC LIMIT 1;" -e sqlite;

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
  
  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "120|80|80|some comment" | assert_output;
}

@test "should add valid sugar level to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123

  run $BLOOD -q "SELECT sugar FROM sugar ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "123" | assert_output;
}

@test "should add valid sugar level with timestamp '2024-06-03 18:35' to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123 -t '2024-06-03 18:35'

  run $BLOOD -q "SELECT sugar, datetime FROM sugar ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  assert_output --partial "2024-06-03 18:35"
}

@test "should add valid sugar level with time '19:16' to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123 -t '19:16'

  run $BLOOD -q "SELECT sugar, datetime FROM sugar ORDER BY datetime DESC LIMIT 1;" -e sqlite;
  
  assert_output --partial "19:16"
}

@test "should add valid sugar level with comment to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123/'some comment'

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "123|some comment" | assert_output;
}

@test "should add valid sugar level with full stomach to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123 --full

  run $BLOOD -q "SELECT sugar, stomach FROM sugar ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "123|f" | assert_output;
}

@test "should add valid sugar level with empty stomach to sqlite" {
  init_sqlite_database;
  run $BLOOD -s 123 --empty

  run $BLOOD -q "SELECT sugar, stomach FROM sugar ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  echo "123|e" | assert_output;
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

@test "should add valid urine acid level with timestamp '2024-06-03 18:35' to sqlite" {
  init_sqlite_database;
  run $BLOOD -a 123 -t '2024-06-03 18:35'

  run $BLOOD -q "SELECT urine, datetime FROM urine_acid ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  assert_output --partial "2024-06-03 18:35"
}

@test "should add valid urine acid level with time '19:16' to sqlite" {
  init_sqlite_database;
  run $BLOOD -a 123 -t '19:16'

  run $BLOOD -q "SELECT urine, datetime FROM urine_acid ORDER BY datetime DESC LIMIT 1;" -e sqlite;
  
  assert_output --partial "19:16"
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

@test "should add valid cholesterol level to sqlite" {
  init_sqlite_database;
  run $BLOOD -c 123

  run $BLOOD -q "SELECT cholesterol FROM cholesterol ORDER BY datetime DESC limit 1;" -e sqlite;

  echo "123" | assert_output;
}

@test "should add valid cholesterol level with timestamp '2024-06-03 18:35' to sqlite" {
  init_sqlite_database;
  run $BLOOD -c 123 -t '2024-06-03 18:35'

  run $BLOOD -q "SELECT cholesterol, datetime FROM cholesterol ORDER BY datetime DESC LIMIT 1;" -e sqlite;

  assert_output --partial "2024-06-03 18:35"
}

@test "should add valid cholesterol level with time '19:16' to sqlite" {
  init_sqlite_database;
  run $BLOOD -c 123 -t '19:16'

  run $BLOOD -q "SELECT cholesterol, datetime FROM cholesterol ORDER BY datetime DESC LIMIT 1;" -e sqlite;
  
  assert_output --partial "19:16"
}


@test "should add valid cholesterol level with comment to sqlite" {
  init_sqlite_database;
  run $BLOOD -c 123/'some comment'

  run $BLOOD -q "SELECT cholesterol, comment FROM cholesterol ORDER BY datetime DESC limit 1;" -e sqlite;

  echo "123|some comment" | assert_output;
}

@test "should fail on invalid cholesterol level to sqlite" {
  init_sqlite_database;
  run $BLOOD -c xxx

  assert_failure
  assert_output --partial "Invalid parameter: cholesterol: \"xxx\"";
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
  run $BLOOD -q "SELECT * FROM pressure ORDER BY datetime LIMIT 1;";

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

@test "should add valid pressure to pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/80/80 -e pgsql

  assert_output --partial "measurement: 120/80/80";
  assert_output --partial "Systolic: \"120\"";
  assert_output --partial "Diastolic: \"80\"";
  assert_output --partial "Pulse: \"80\"";

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  # assert_output --regexp "^\s*120\s\|\s*80\s\|\s*80\s\|\s*$"
  assert_output --partial "      120 |        80 |    80 |";
}

@test "should add valid pressure with comment to pgsql" {
  init_pgsql_database;

  run $BLOOD -p 120/80/80/'some comment' -e pgsql

  assert_output --partial "measurement: 120/80/80";
  assert_output --partial "Systolic: \"120\"";
  assert_output --partial "Diastolic: \"80\"";
  assert_output --partial "Pulse: \"80\"";
  assert_output --partial "Comment: \"some comment\"";
 
  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "      120 |        80 |    80 | some comment";
}

@test "should add valid sugar level to pgsql" {
  init_pgsql_database;

  run $BLOOD -s 123 -e pgsql;

  run $BLOOD -q "SELECT sugar FROM sugar ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "123";
}

@test "should add valid sugar level with comment to pgsql" {
  init_pgsql_database;

  run $BLOOD -s 123/'some comment' -e pgsql;

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "123 | some comment";
}

@test "should add valid sugar level with timestamp '2024-06-03 18:13' to pgsql" {
  init_pgsql_database;

  run $BLOOD -s 123 -t '2024-06-03 18:13' -e pgsql;

  run $BLOOD -q "SELECT sugar, datetime FROM sugar ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "2024-06-03 18:13";
}

@test "should add valid sugar level with time '21:32' to pgsql" {
  init_pgsql_database;

  run $BLOOD -s 123 -t '21:32' -e pgsql;

  run $BLOOD -q "SELECT sugar, datetime FROM sugar ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "21:32";
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

@test "should add valid sugar level with full stomach to pgsql" {
  init_pgsql_database;
  run $BLOOD -s 123 --full -e pgsql

  run $BLOOD -q "SELECT sugar, stomach FROM sugar ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "123 | f"
}

@test "should add valid sugar level with empty stomach to pgsql" {
  init_pgsql_database;
  run $BLOOD -s 123 --empty -e pgsql

  run $BLOOD -q "SELECT sugar, stomach FROM sugar ORDER BY datetime DESC LIMIT 1;" -e pgsql;

  assert_output --partial "123 | e"
}

@test "should fail on invalid urine acid level to pgsql" {
  init_pgsql_database;

  run $BLOOD -a xxx -e pgsql

  assert_output --partial "Invalid parameter: urine acid: \"xxx\"";
}

@test "should add valid cholesterol level to pgsql" {
  init_pgsql_database;

  run $BLOOD -c 123 -e pgsql;

  run $BLOOD -q "SELECT cholesterol FROM cholesterol ORDER BY datetime DESC limit 1;" -e pgsql;

  assert_output --partial "123";
}

@test "should add valid cholesterol level with comment to pgsql" {
  init_pgsql_database;

  run $BLOOD -c 123/'some comment' -e pgsql;

  run $BLOOD -q "SELECT cholesterol, comment FROM cholesterol ORDER BY datetime DESC limit 1;" -e pgsql;

  assert_output --partial "123 | some comment";
}

@test "should fail on invalid cholesterol level to pgsql" {
  init_pgsql_database;

  run $BLOOD -c xxx -e pgsql

  assert_output --partial "Invalid parameter: cholesterol: \"xxx\"";
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
  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime LIMIT 1;" -e pgsql;

  assert_output --partial "      120 |        80 |    80 |";
}

@test "should sync data from sqlite to pgsql" {
  init_pgsql_database;
  init_sqlite_database;

  run $BLOOD -p 133/83/83 -e sqlite
  run $BLOOD -a 123/'first urine acid' -e sqlite
  run $BLOOD -s 234/'first sugar' -e sqlite
  run $BLOOD -c 345/'first cholesterol' -e sqlite
  run $BLOOD -X sqlite:pgsql

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime LIMIT 1;" -e pgsql;
  assert_output --partial "      133 |        83 |    83 |";

  run $BLOOD -q "SELECT urine, comment FROM urine_acid ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   123 | first urine acid";

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   234 | first sugar";

  run $BLOOD -q "SELECT cholesterol, comment FROM cholesterol ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   345 | first cholesterol";

}

@test "should sync data with comma in comment from sqlite to pgsql" {
  init_pgsql_database;
  init_sqlite_database;

  run $BLOOD -p 133/83/83/'first, pressure' -e sqlite
  run $BLOOD -a 123/'first, urine acid' -e sqlite
  run $BLOOD -s 234/'first, sugar' -e sqlite
  run $BLOOD -c 345/'first, cholesterol' -e sqlite
  run $BLOOD -X sqlite:pgsql

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime LIMIT 1;" -e pgsql;
  assert_output --partial "      133 |        83 |    83 | first, pressure";

  run $BLOOD -q "SELECT urine, comment FROM urine_acid ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   123 | first, urine acid";

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   234 | first, sugar";

  run $BLOOD -q "SELECT cholesterol, comment FROM cholesterol ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   345 | first, cholesterol";
}

@test "should sync data with quotation in comment from sqlite to pgsql" {
  init_pgsql_database;
  init_sqlite_database;

  run $BLOOD -p 133/83/83/'first"", pressure' -e sqlite
  run $BLOOD -a 123/'first"", urine acid' -e sqlite
  run $BLOOD -s 234/'first"", sugar' -e sqlite
  run $BLOOD -c 345/'first"", cholesterol' -e sqlite
  run $BLOOD -X sqlite:pgsql

  run $BLOOD -q "SELECT systolic, diastolic, pulse, comment FROM pressure ORDER BY datetime LIMIT 1;" -e pgsql;
  assert_output --partial "      133 |        83 |    83 | first\", pressure";

  run $BLOOD -q "SELECT urine, comment FROM urine_acid ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   123 | first\", urine acid";

  run $BLOOD -q "SELECT sugar, comment FROM sugar ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   234 | first\", sugar";

  run $BLOOD -q "SELECT cholesterol, comment FROM cholesterol ORDER BY datetime DESC limit 1;" -e pgsql;
  assert_output --partial "   345 | first\", cholesterol";
}

# imports sample pressure from sample_pressure.csv
import_sample_pressure() {
  run $BLOOD -P sample_pressure.csv -e $1;
}

# imports sample sugar from sample_sugar.csv
import_sample_sugar() {
  run $BLOOD -S sample_sugar.csv -e $1
}

# imports sample urine acid from sample_urine_acid.csv
import_sample_urine_acid() {
  run $BLOOD -A sample_urine_acid.csv -e $1
}

# imports sample cholesterol from sample_sugar.csv
import_sample_cholesterol() {
  run $BLOOD -C sample_cholesterol.csv -e $1
}

@test "should list 2 entries of all features on sqlite" {
  init_sqlite_database;

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$($BLOOD -l 2 --log-level debug)";

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204 ↑|fourth sugar" <<< "$result"
  grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"

  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

  grep -q "624 ↑|fourth cholesterol" <<< "$result"
  grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"

}

@test "should list default entries of all features on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD -l)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"

  grep -q "204 ↑|fourth sugar" <<< "$result"
  grep -q "203 ↑|third sugar" <<< "$result"
  grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"

  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

  grep -q "624 ↑|fourth cholesterol" <<< "$result"
  grep -q "623 ↑|third cholesterol" <<< "$result"
  grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"

}

@test "should query list of 2 pressure entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-pressure 2)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204 ↑|fourth sugar" <<< "$result"
  ! grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
  ! grep -q "624 ↑|fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"

}

@test "should query default pressure entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-pressure)"

  grep -q "100|80|84|fourth pressure" <<< "$result"
  grep -q "100|80|83|third pressure" <<< "$result"
  grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204 ↑|fourth sugar" <<< "$result"
  ! grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
  ! grep -q "624 ↑|fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"
}

@test "should query list of 2 cholesterol entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-cholesterol 2)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204 ↑|fourth sugar" <<< "$result"
  ! grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
  grep -q "624 ↑|fourth cholesterol" <<< "$result"
  grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"

}

@test "should query default cholesterol entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-cholesterol)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204 ↑|fourth sugar" <<< "$result"
  ! grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"
  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
  grep -q "624 ↑|fourth cholesterol" <<< "$result"
  grep -q "623 ↑|third cholesterol" <<< "$result"
  grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"
}

@test "should list of 2 urine_acid entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-urine-acid 2)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204 ↑|fourth sugar" <<< "$result"
  ! grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"
  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
  ! grep -q "624 ↑|fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"
}

@test "should list default urine acid entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-urine-acid)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  ! grep -q "204 ↑|fourth sugar" <<< "$result"
  ! grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"
  grep -q "324|fourth acid" <<< "$result"
  grep -q "323|third acid" <<< "$result"
  grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"
  ! grep -q "624 ↑|fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"
}

@test "should list of 2 sugar entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-sugar 2)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  grep -q "204 ↑|fourth sugar" <<< "$result"
  grep -q "203 ↑|third sugar" <<< "$result"
  ! grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

  ! grep -q "624 ↑|fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"

}

@test "should list default sugar entries on sqlite" {
  init_sqlite_database

  import_sample_pressure sqlite
  import_sample_sugar sqlite
  import_sample_urine_acid sqlite
  import_sample_cholesterol sqlite

  result="$(run $BLOOD --list-sugar)"

  ! grep -q "100|80|84|fourth pressure" <<< "$result"
  ! grep -q "100|80|83|third pressure" <<< "$result"
  ! grep -q "100|80|82|second pressure" <<< "$result"
  ! grep -q "100|80|81|first pressure" <<< "$result"
  grep -q "204 ↑|fourth sugar" <<< "$result"
  grep -q "203 ↑|third sugar" <<< "$result"
  grep -q "202 ↑|second sugar" <<< "$result"
  ! grep -q "201 ↑|first sugar" <<< "$result"

  ! grep -q "324|fourth acid" <<< "$result"
  ! grep -q "323|third acid" <<< "$result"
  ! grep -q "322|second acid" <<< "$result"
  ! grep -q "321|first acid" <<< "$result"

  ! grep -q "624 ↑|fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑|third cholesterol" <<< "$result"
  ! grep -q "622 ↑|second cholesterol" <<< "$result"
  ! grep -q "621 ↑|first cholesterol" <<< "$result"
}

@test "should list sugar low on empty stomach on sqlite" {
  init_sqlite_database;
  run $BLOOD -s 20 --empty

  result="$(run $BLOOD --list-sugar)";

  grep -q "20 ↓" <<< "$result"
}

@test "should list sugar normal on empty stomach on sqlite" {
  init_sqlite_database;
  run $BLOOD -s 90 --empty

  result="$(run $BLOOD --list-sugar)";

  grep -q "90" <<< "$result";
}

@test "should list sugar high on empty stomach on sqlite" {
  init_sqlite_database;
  run $BLOOD -s 120 --empty

  result="$(run $BLOOD --list-sugar)";

  grep -q "120 ↑" <<< "$result";
}

@test "should list sugar low on full stomach on sqlite" {
  init_sqlite_database;
  run $BLOOD -s 20 --full

  result="$(run $BLOOD --list-sugar)";

  grep -q "20 ↓" <<< "$result"
}

@test "should list sugar normal on full stomach on sqlite" {
  init_sqlite_database;
  run $BLOOD -s 120 --full

  result="$(run $BLOOD --list-sugar)";

  grep -q "120" <<< "$result";
}

@test "should list sugar high on full stomach on sqlite" {
  init_sqlite_database;
  run $BLOOD -s 220 --full

  result="$(run $BLOOD --list-sugar)";

  grep -q "220 ↑" <<< "$result";
}

@test "should list sugar low on empty stomach on pgsql" {
  init_pgsql_database;
  run $BLOOD -s 20 --empty -e pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)";

  grep -q "20 ↓" <<< "$result"
}

@test "should list sugar normal on empty stomach on pgsql" {
  init_pgsql_database;
  run $BLOOD -s 90 --empty -e pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)";

  grep -q "90" <<< "$result";
}

@test "should list sugar high on empty stomach on pgsql" {
  init_pgsql_database;
  run $BLOOD -s 120 --empty -e pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)";

  grep -q "120 ↑" <<< "$result";
}

@test "should list sugar low on full stomach on pgsql" {
  init_pgsql_database;
  run $BLOOD -s 20 --full -e pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)";

  grep -q "20 ↓" <<< "$result"

}

@test "should list sugar normal on full stomach on pgsql" {
  init_pgsql_database;
  run $BLOOD -s 120 --full -e pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)";

  grep -q "120" <<< "$result";
}

@test "should list sugar high on full stomach on pgsql" {
  init_pgsql_database;
  run $BLOOD -s 220 --full -e pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)";

  grep -q "220 ↑" <<< "$result";
}

@test "should list high pressure on sqlite" {
  init_sqlite_database
  run $BLOOD -p 240/180/200/'high pressure' -e sqlite

  result="$(run $BLOOD --list-pressure -e sqlite)"

  grep -q "240 ↑|180 ↑|200 ↑|high pressure" <<< "$result"
}

@test "should list normal pressure on sqlite" {
  init_sqlite_database
  run $BLOOD -p 120/80/80/'normal pressure' -e sqlite

  result="$(run $BLOOD --list-pressure -e sqlite)"

  grep -q "120|80|80|normal pressure" <<< "$result"
}

@test "should list low pressure on sqlite" {
  init_sqlite_database
  run $BLOOD -p 40/20/20/'low pressure' -e sqlite

  result="$(run $BLOOD --list-pressure -e sqlite)"

  grep -q "40 ↓|20 ↓|20 ↓|low pressure" <<< "$result"
}

@test "should list high urine acid on sqlite" {
  init_sqlite_database
  run $BLOOD -a 840/'high acid' -e sqlite

  result="$(run $BLOOD --list-urine-acid -e sqlite)"

  grep -q "840 ↑|high acid" <<< "$result"
}

@test "should list normal urine acid on sqlite" {
  init_sqlite_database
  run $BLOOD -a 300/'normal acid' -e sqlite

  result="$(run $BLOOD --list-urine-acid -e sqlite)"

  grep -q "300|normal acid" <<< "$result"
}

@test "should list low urine acid on sqlite" {
  init_sqlite_database
  run $BLOOD -a 20/'low acid' -e sqlite

  result="$(run $BLOOD --list-urine-acid -e sqlite)"

  grep -q "20 ↓|low acid" <<< "$result"
}

@test "should list high cholesterol on sqlite" {
  init_sqlite_database
  run $BLOOD -c 840/'high cholesterol' -e sqlite

  result="$(run $BLOOD --list-cholesterol -e sqlite)"

  grep -q "840 ↑|high cholesterol" <<< "$result"
}

@test "should list normal cholesterol on sqlite" {
  init_sqlite_database
  run $BLOOD -c 300/'normal cholesterol' -e sqlite

  result="$(run $BLOOD --list-cholesterol -e sqlite)"

  grep -q "300|normal cholesterol" <<< "$result"
}

@test "should list low cholesterol on sqlite" {
  init_sqlite_database
  run $BLOOD -c 20/'low cholesterol' -e sqlite

  result="$(run $BLOOD --list-cholesterol -e sqlite)"

  grep -q "20 ↓|low cholesterol" <<< "$result"
}


@test "should list high pressure on pgsql" {
  init_pgsql_database
  run $BLOOD -p 240/180/200/'high pressure' -e pgsql

  result="$(run $BLOOD --list-pressure -e pgsql)"

  grep -q "| 240 ↑    | 180 ↑     | 200 ↑ | high pressure" <<< "$result"
}

@test "should list normal pressure on pgsql" {
  init_pgsql_database
  run $BLOOD -p 120/80/80/'normal pressure' -e pgsql

  result="$(run $BLOOD --list-pressure -e pgsql)"

  grep -q "| 120      | 80        | 80    | normal pressure" <<< "$result"
}

@test "should list low pressure on pgsql" {
  init_pgsql_database
  run $BLOOD -p 40/20/20/'low pressure' -e pgsql

  result="$(run $BLOOD --list-pressure -e pgsql)"

  grep -q "| 40 ↓     | 20 ↓      | 20 ↓  | low pressure" <<< "$result"
}

@test "should list high urine acid on pgsql" {
  init_pgsql_database
  run $BLOOD -a 840/'high acid' -e pgsql

  result="$(run $BLOOD --list-urine-acid -e pgsql)"

  grep -q "| 840 ↑    | high acid" <<< "$result"
}

@test "should list normal urine acid on pgsql" {
  init_pgsql_database
  run $BLOOD -a 300/'normal acid' -e pgsql

  result="$(run $BLOOD --list-urine-acid -e pgsql)"

  grep -q "| 300      | normal acid" <<< "$result"
}

@test "should list low urine acid on pgsql" {
  init_pgsql_database
  run $BLOOD -a 20/'low acid' -e pgsql

  result="$(run $BLOOD --list-urine-acid -e pgsql)"

  grep -q "| 20 ↓     | low acid" <<< "$result"
}

@test "should list high cholesterol on pgsql" {
  init_pgsql_database
  run $BLOOD -c 840/'high cholesterol' -e pgsql

  result="$(run $BLOOD --list-cholesterol -e pgsql)"

  grep -q "| 840 ↑    | high cholesterol" <<< "$result"
}

@test "should list normal cholesterol on pgsql" {
  init_pgsql_database
  run $BLOOD -c 300/'normal cholesterol' -e pgsql

  result="$(run $BLOOD --list-cholesterol -e pgsql)"

  grep -q "| 300      | normal cholesterol" <<< "$result"
}

@test "should list low cholesterol on pgsql" {
  init_pgsql_database
  run $BLOOD -c 20/'low cholesterol' -e pgsql

  result="$(run $BLOOD --list-cholesterol -e pgsql)"

  grep -q "| 20 ↓     | low cholesterol" <<< "$result"
}

@test "should list 2 entries of all features on pgsql" {
  init_pgsql_database;

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD -l 2 -e pgsql)"

  echo "$result" >/tmp/result.txt

  grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"

  grep -q "| 204 ↑    | fourth sugar" <<< "$result"
  grep -q "| 203 ↑    | third sugar" <<< "$result"
  ! grep -q "| 202 ↑    | second sugar" <<< "$result"
  ! grep -q "| 201 ↑    | first sugar" <<< "$result"


  grep -q "| 324      | fourth acid" <<< "$result"
  grep -q "| 323      | third acid" <<< "$result"
  ! grep -q "| 322      | second acid" <<< "$result"
  ! grep -q "| 321      | first acid" <<< "$result"

  grep -q "| 624 ↑    | fourth cholesterol" <<< "$result"
  grep -q "| 623 ↑    | third cholesterol" <<< "$result"
  ! grep -q "| 622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "| 621 ↑    | first cholesterol" <<< "$result"
}

@test "should list default entries of all features on pgsql" {
  init_pgsql_database;

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD -l -e pgsql)"

  grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"

  grep -q "204 ↑    | fourth sugar" <<< "$result"
  grep -q "203 ↑    | third sugar" <<< "$result"
  grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"

  grep -q "324      | fourth acid" <<< "$result"
  grep -q "323      | third acid" <<< "$result"
  grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"

  grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  grep -q "623 ↑    | third cholesterol" <<< "$result"
  grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
}

@test "should list of 2 pressure entries on pgsql" {
  init_pgsql_database

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD --list-pressure 2 -e pgsql)"

  grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"
  ! grep -q "204 ↑    | fourth sugar" <<< "$result"
  ! grep -q "203 ↑    | third sugar" <<< "$result"
  ! grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"
  ! grep -q "324      | fourth acid" <<< "$result"
  ! grep -q "323      | third acid" <<< "$result"
  ! grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"
  ! grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑    | third cholesterol" <<< "$result"
  ! grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
}

@test "should list of default pressure entries on pgsql" {
  init_pgsql_database

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD --list-pressure -e pgsql)"

  grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"

  ! grep -q "204 ↑    | fourth sugar" <<< "$result"
  ! grep -q "203 ↑    | third sugar" <<< "$result"
  ! grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"

  ! grep -q "324      | fourth acid" <<< "$result"
  ! grep -q "323      | third acid" <<< "$result"
  ! grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"

  ! grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑    | third cholesterol" <<< "$result"
  ! grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
}

@test "should list of 2 cholesterol entries on pgsql" {
  init_pgsql_database

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD --list-cholesterol 2 -e pgsql)"

  ! grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"
  ! grep -q "204 ↑    | fourth sugar" <<< "$result"
  ! grep -q "203 ↑    | third sugar" <<< "$result"
  ! grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"
  ! grep -q "324      | fourth acid" <<< "$result"
  ! grep -q "323      | third acid" <<< "$result"
  ! grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"
  grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  grep -q "623 ↑    | third cholesterol" <<< "$result"
  ! grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
}

@test "should list of default cholesterol entries on pgsql" {
  init_pgsql_database

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD --list-cholesterol -e pgsql)"

  ! grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"

  ! grep -q "204 ↑    | fourth sugar" <<< "$result"
  ! grep -q "203 ↑    | third sugar" <<< "$result"
  ! grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"

  ! grep -q "324      | fourth acid" <<< "$result"
  ! grep -q "323      | third acid" <<< "$result"
  ! grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"

  grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  grep -q "623 ↑    | third cholesterol" <<< "$result"
  grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
}

@test "should list of 2 sugar entries on pgsql" {
  init_pgsql_database

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD --list-sugar 2 -e pgsql)"

  ! grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"

  grep -q "204 ↑    | fourth sugar" <<< "$result"
  grep -q "203 ↑    | third sugar" <<< "$result"
  ! grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"

  ! grep -q "324      | fourth acid" <<< "$result"
  ! grep -q "323      | third acid" <<< "$result"
  ! grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"

  ! grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑    | third cholesterol" <<< "$result"
  ! grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
}

@test "should list of default sugar entries on pgsql" {
  init_pgsql_database

  import_sample_pressure pgsql
  import_sample_sugar pgsql
  import_sample_urine_acid pgsql
  import_sample_cholesterol pgsql

  result="$(run $BLOOD --list-sugar -e pgsql)"

  ! grep -q "| 100      | 80        | 84    | fourth pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 83    | third pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 82    | second pressure" <<< "$result"
  ! grep -q "| 100      | 80        | 81    | first pressure" <<< "$result"

  grep -q "204 ↑    | fourth sugar" <<< "$result"
  grep -q "203 ↑    | third sugar" <<< "$result"
  grep -q "202 ↑    | second sugar" <<< "$result"
  ! grep -q "201 ↑    | first sugar" <<< "$result"

  ! grep -q "324      | fourth acid" <<< "$result"
  ! grep -q "323      | third acid" <<< "$result"
  ! grep -q "322      | second acid" <<< "$result"
  ! grep -q "321      | first acid" <<< "$result"

  ! grep -q "624 ↑    | fourth cholesterol" <<< "$result"
  ! grep -q "623 ↑    | third cholesterol" <<< "$result"
  ! grep -q "622 ↑    | second cholesterol" <<< "$result"
  ! grep -q "621 ↑    | first cholesterol" <<< "$result"
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

@test "should fail with valid error on missing parameter for -b" {
  run $BLOOD -b
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -b"
}

@test "should fail with valid error on missing parameter for --database-port" {
  run $BLOOD --database-port
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --database-port"
}

@test "should fail with valid error on missing parameter for -C" {
  run $BLOOD -C
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option -C"
}

@test "should fail with valid error on missing parameter for --import-cholesterol" {
  run $BLOOD --import-cholesterol
  assert_failure
  assert_output --partial "ERROR: Missing parameter for option --import-cholesterol"
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

@test "should list sugar norms on empty stomach on sqlite" {
  init_sqlite_database
  result="$(run $BLOOD -n sugar_empty)"

  grep -q "Norms for: Sugar on empty stomach" <<< $result
  grep -q "50 - 99" <<< $result;
}

@test "should list sugar norms on full stomach on sqlite" {
  init_sqlite_database
  result="$(run $BLOOD -n sugar_full)"

  grep -q "Norms for: Sugar on full stomach" <<< $result
  grep -q "50 - 149" <<< $result;
}

@test "should list sugar norms on sqlite" {
  init_sqlite_database
  result="$(run $BLOOD -n sugar)"

  grep -q "Norms for: Sugar on empty stomach" <<< $result
  grep -q "50 - 99" <<< $result;
  grep -q "Norms for: Sugar on full stomach" <<< $result
  grep -q "50 - 149" <<< $result;
}

@test "should list pressure norms on sqlite" {
  init_sqlite_database
  result="$(run $BLOOD -n pressure)"

  grep -q "Norms for: Pressure" <<< $result;
  grep -q "diastolic|60|100" <<< $result;
  grep -q "pulse|60|90" <<< $result;
  grep -q "systolic|100|140" <<< $result;
}

@test "should list cholesterol norms on sqlite" {
  init_sqlite_database
  result="$(run $BLOOD -n cholesterol)"

  grep -q "Norms for: Cholesterol" <<< $result;
  grep -q "0 - 518" <<< $result;
}

@test "should list urine acid norms on sqlite" {
  init_sqlite_database

  result="$(run $BLOOD -n urine_acid)"

  grep -q "Norms for: Urine acid" <<< $result;
  grep -q "300 - 360" <<< $result;
}

@test "should list all norms on sqlite" {
  init_sqlite_database

  result="$(run $BLOOD -n)";
  grep -q "Norms for: Pressure" <<< $result;
  grep -q "diastolic|60|100" <<< $result;
  grep -q "pulse|60|90" <<< $result;
  grep -q "systolic|100|140" <<< $result;
  grep -q "Norms for: Cholesterol" <<< $result;
  grep -q "0 - 518" <<< $result;
  grep -q "Norms for: Urine acid" <<< $result;
  grep -q "300 - 360" <<< $result;
}




#----------
@test "should list sugar norms on empty stomach on pgsql" {
  init_pgsql_database
  result="$(run $BLOOD -n sugar_empty)"

  grep -q "Norms for: Sugar on empty stomach" <<< $result
  grep -q "50 - 99" <<< $result;
}

@test "should list sugar norms on full stomach on pgsql" {
  init_pgsql_database
  result="$(run $BLOOD -n sugar_full)"

  grep -q "Norms for: Sugar on full stomach" <<< $result
  grep -q "50 - 149" <<< $result;
}

@test "should list sugar norms on pgsql" {
  init_pgsql_database
  result="$(run $BLOOD -n sugar)"

  grep -q "Norms for: Sugar on empty stomach" <<< $result
  grep -q "50 - 99" <<< $result;
  grep -q "Norms for: Sugar on full stomach" <<< $result
  grep -q "50 - 149" <<< $result;
}

@test "should list pressure norms on pgsql" {
  init_pgsql_database
  result="$(run $BLOOD -n pressure)"

  grep -q "Norms for: Pressure" <<< $result;
  grep -q "diastolic|60|100" <<< $result;
  grep -q "pulse|60|90" <<< $result;
  grep -q "systolic|100|140" <<< $result;
}

@test "should list cholesterol norms on pgsql" {
  init_pgsql_database
  result="$(run $BLOOD -n cholesterol)"

  grep -q "Norms for: Cholesterol" <<< $result;
  grep -q "0 - 518" <<< $result;
}

@test "should list urine acid norms on pgsql" {
  init_pgsql_database

  result="$(run $BLOOD -n urine_acid)"

  grep -q "Norms for: Urine acid" <<< $result;
  grep -q "300 - 360" <<< $result;
}

@test "should list all norms on pgsql" {
  init_pgsql_database

  result="$(run $BLOOD -n)";
  grep -q "Norms for: Pressure" <<< $result;
  grep -q "diastolic|60|100" <<< $result;
  grep -q "pulse|60|90" <<< $result;
  grep -q "systolic|100|140" <<< $result;
  grep -q "Norms for: Cholesterol" <<< $result;
  grep -q "0 - 518" <<< $result;
  grep -q "Norms for: Urine acid" <<< $result;
  grep -q "300 - 360" <<< $result;
}
