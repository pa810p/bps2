# BPS2 - Blood Parameters Storage System

BPS2 is a simple command line interface written in bash to store previous measured blood parameters such as pressure 
(diastolic, systolic and pulse) and sugar level. By default, data is stored in sqlite file named blood.db in local 
directory. There is possibility to synchronize blood.db with postgresql server.

## Installation

### Prerequisites

- [sqlite3](https://www.sqlite.org/)
- [postgresql](https://www.postgresql.org/) (:hand: optional)
- [bash](https://www.gnu.org/software/bash/)

### Install BPS2

#### Download and configure
Clone GitHub repository:
````
$ git clone git@github.com:pa810p/bps2.git
````
Copy blood_template.properties to blood.properties:
````
$ cp blood_template.properties blood.properties
````
Edit blood.properties according to your needs (database access :arrow_down:).

#### Initialize database:
- sqlite (:bulb: note that sqlite3 database is default one so there is no need to use option -e sqlite)
````
./blood.sh -i createdb.sqlite
````
Then you can test if it works by inserting your first measurement:
````
$ ./blood.sh -p 123/80/90/
Using: blood.properties
measurement: 123/80/90/
Systolic: "123"
Diastolic: "80"
Pulse: "90"
Comment: ""
````
And check if it is persisted in database by using query:
````
$ ./blood.sh -q 'SELECT * FROM blood;'
Using: blood.properties
Executing query: SELECT * FROM blood;
2023-10-29 14:50:13|123|80|90|
````
- postgresql (:hand: optional)
Create role and database on your postgresql system or ask administrator to create it: 
````
postgres=# CREATE USER blood WITH ENCRYPTED PASSWORD 'password';
CREATE ROLE
postgres=# CREATE DATABASE blood;
CREATE DATABASE
postgres=# ALTER DATABASE blood OWNER TO blood; 
ALTER DATABASE
````
Initialize database:
````
$ ./blood.sh -i createdb.sql -e pgsql
Using: blood.properties
psql postgresql://blood:password@:5433/blood < createdb.sql
NOTICE:  table "blood" does not exist, skipping
DROP TABLE
NOTICE:  sequence "blood_id_seq" does not exist, skipping
DROP SEQUENCE
CREATE SEQUENCE
CREATE TABLE
NOTICE:  table "sugar" does not exist, skipping
DROP TABLE
NOTICE:  sequence "sugar_id_seq" does not exist, skipping
DROP SEQUENCE
CREATE SEQUENCE
CREATE TABLE
````
Then you can test if it works by inserting your first measurement:
````
$ ./blood.sh -e pgsql -p 123/12/12
Using: blood.properties
measurement: 123/12/12
Systolic: "123"
Diastolic: "12"
Pulse: "12"
Comment: ""
INSERT 0 1
````
And check if it is persisted in database by using query:
````
$ ./blood.sh -e pgsql -q 'SELECT * FROM blood;'
Using: blood.properties
Executing query: SELECT * FROM blood;
 id |         datetime          | systolic | diastolic | pulse | comment 
----+---------------------------+----------+-----------+-------+---------
  1 | 2023-10-29 14:33:52.10622 |      123 |        12 |    12 | 
(1 row)
````

## Usage

````
$ ./blood.sh

Usage: ./blood.sh [OPTIONS]
OPTIONS include:
-d --debug                     shows more detailed debug information
-D --dbname DATABASE_NAME      database name
-e --engine DATABASE_ENGINE    database engine can be either sqlite or pgsql
-h --help                      help screen
-H --host DATABASE_HOST        database host
-i --initialize INIT_FILENAME  initialize filename
-p --pressure MEASUREMENT      blood pressure measurement in format of eg.: 120/80/90/'comment'
(systolic/diastolic/pulse/'comment') where comment is optional
-q --query QUERY               SQL query provided to sqlite database (query should correspond with engine -e option)
-s --sugar SUGAR_LEVEL         sugar level in blood in mg/dL
-U --user USERNAME             database user name
-X --sync SOURCE:DESTINATION   synchronize databases (copy data from SOURCE to DESTINATION database
either SOURCE or DESTINATION may be: sqlite, pgsql
````

### Example usage
#### Store blood pressure to sqlite database:
````
$ ./blood.sh -p 120/80/80
````

#### Store sugar level to sqlite database:
````
$ ./blood.sh -s 95
````

#### Synchronize local sqlite database with postgresql
````
$ ./blood.sh -X sqlite:pgsql
````


### Web interface
Not implemented yet, see TODO section

### Visualization

#### Grafana

## Testing

### Prerequisites
Tests are launched in dockerized environment
Make sure you have installed:
- [docker](https://docs.docker.com/desktop/install/linux-install/)

Install bats wherever you want, then copy directories : bats and test_helper into tests folder:
```
$ git init
$ git submodule add https://github.com/bats-core/bats-core.git test/bats
$ git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
$ git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
$ git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-files
```

:warning: Probably you'll  need to rename ./tests/test_helper/bats_files to ./tests/test_helper/bats_file
```
$ mv ./tests/test_helper/bats_files ./tests/test_helper/bats_files
$ ls ./tests
bats  blood.bats  test_helper
```

### Run tests
```
$ ./blood_tests.sh
```

## Known bugs
1. No error message for **invalid** input (missing parameter -p when adding blood pressure) `./blood.sh 123/90/100`

## TODO
- add units option to _blood_template.properties_ so user can specify unit of value he provide to system
- add comment feature to CLI for sugar input (-s 110/'my comment')
- add feature to store urine acid
- add feature to store cholesterol level
- add web interface with features like:
  - GUI interface to :
    - input data manually
    - visualise data with various graphs
  - REST interface
- login page, and support for multiple users, accounts
- import data from various number of file format:
  - json
  - xml
  - csv
- publish code from grafana that generates fancy graphs
- dockerize postgresql with volume on local storage
