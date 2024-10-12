#!/bin/bash
###############################################################################
# BPS2 (Blood Parameters Storage System) is a simple command line interface   #
# to store previous measured blood parameters such as pressure (diastolic,    #
# systolic and pulse) sugar level, and urine acid level.                      #
# Author:     Paweł Prokop (pa810p@gmail.com)                                 #
# Repository: https://github.com/pa810p/bps2                                  #
# License:    GNU General Public License v3.0  see: LICENSE                   #
###############################################################################

VERSION=1.2.6

declare -A STOMACH_CONDITION_MAP=(
  ["empty"]="e"
  ["full"]="f"
)

declare -A HUMAN_MAP=(
  ["male"]="m"
  ["female"]="f"
  ["child"]="c"
  ["other"]="o"
)


######################################
# Displays Usage information and exit
######################################
function helpme() {
  echo "Version: $VERSION";
	echo "Usage: $0 [OPTIONS]";
	echo "OPTIONS include:";
	echo "-a --urine-acid URINE_ACID           urine acid in blood in µmol/l using format of: 370/'comment'";
	echo "-b --database-port DATABASE_PORT     database port";
  echo "-A --import-urine-acid FILENAME      import urine acid from csv FILENAME";
  echo "-c --cholesterol CHOLESTEROL         cholesterol in blood in µmol/l using format of: 370/'comment'";
  echo "-C --import-cholesterol FILENAME     import cholesterol from csv FILENME";
	echo "-D --dbname DATABASE_NAME            database name";
	echo "-e --engine DATABASE_ENGINE          database engine can be either sqlite or pgsql";
	echo "-f --format                          format display (column names, formatting, colors)";
	echo "-h --help                            help screen";
	echo "-H --host DATABASE_HOST              database host";
	echo "-i --initialize INIT_FILENAME        initialize filename";
	echo "-l [LIST_ENTRIES]                    list last LIST_ENTRIES (default from properties) entries of both pressure and sugar";
	echo "   --list-cholesterol [LIST_ENTRIES] list last LIST_ENTRIES (default from properties) entries of cholesterol";
	echo "   --list-pressure [LIST_ENTRIES]    list last LIST ENTRIES (default from properties) entries of pressure";
	echo "   --list-sugar [LIST_ENTRIES]       list last LIST_ENTRIES (default from properties) entries of sugar";
	echo "   --list-urine-acid [LIST_ENTRIES]  list last LIST_ENTRIES (default from properties) entries of urine acid";
	echo "   --log-level [LEVEL]               logging level where LEVEL may be (0=critical, 1=error, 2=warning, 3=info";
	echo "                                     4=debug)";
	echo "-p --pressure MEASUREMENT            blood pressure measurement in format of: 120/80/90/'comment'";
	echo "-P --import_pressure FILENAME        import pressure from csv FILENAME";
	echo "                                     (systolic/diastolic/pulse/'comment') where comment is optional";
	echo "-q --query QUERY                     SQL query provided to sqlite database (query should correspond with engine -e option)";
	echo "-s --sugar SUGAR_LEVEL               sugar level in blood in mg/dL using format of: 123/'comment'";
  echo "                                     where 'comment' is optional";
  echo "   --empty                           measurement on empty stomach";
  echo "   --full                            measurement on full stomach";
  echo "-S --import-sugar FILENAME           import sugar from csv FILENAME";
  echo "                                     where 'comment' is optional";
  echo "-t --time TIME                       sets time in format 'yyyy-MM-dd HH:mm' or 'HH:mm'";
  echo "                                     if 'HH:mm' format is used date is set to today";
	echo "-U --user USERNAME                   database user name";
	echo "-v --version                         displays version information and exits";
	echo "-X --sync SOURCE:DESTINATION         synchronize databases (copy data from SOURCE to DESTINATION database";
	echo "                                     either SOURCE or DESTINATION may be: sqlite, pgsql";
	echo "";
	echo "Example: ";
	echo "./blood.sh -e pgsql -i createdb.sql";
  echo "./blood.sh -p 123/80/90/'my fancy comment'";
  echo "./blood.sh -p 123/80/90/'my fancy comment' -t '2024-05-30 06:26'";
  echo "./blood.sh -p 123/80/90/'my fancy comment' -t '06:31'";
}

######################################
# Displays Version information and exit
######################################
function version() {
  log $VERSION
  exit 0;
}


###############################################
# Displays reason of failure, usage and exits
# Arguments:
#   $1 name of parameter
#   $2 value of parameter
###############################################
function fail() {
  echo "Invalid parameter: $1: \"$2\" aborting!";
  helpme;
  exit 1;
}

############################
# Outputs log information
# Arguments:
#   $1 log information
############################
function log() {
  echo -e "$1";
}

##################################################
# Outputs debug information according to settings
# Arguments:
#   $1 debug information
##################################################
function debug() {
  if [[ "$LOG_LEVEL" -ge 4 ]] ; then
    log "DEBUG: $1";
  fi
}

function info() {
  if [[ "$LOG_LEVEL" -ge 3 ]] ; then
    log "INFO: $1";
  fi
}

function warn() {
  if [[ "$LOG_LEVEL" -ge 2 ]] ; then
    log "WARN: $1";
  fi
}

function error() {
  if [[ "$LOG_LEVEL" -ge 1 ]] ; then
    log "ERROR: $1";
  fi
}

function critical() {
  if [[ "$LOG_LEVEL" -ge 0 ]] ; then
    log "CRIT: $1";
  fi
}

##############################
# Executes sql query.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   PGSQL
#   SQLITE
# Arguments:
#   sql query to execute
##############################
function query() {

	_QUERY=$1;

	debug "Executing query: $_QUERY";

	case $DB_ENGINE in
		"sqlite" )
		  if [[ "$FORMAT" == "true" ]]; then _MODE=".mode column";
		  else _MODE="";
		  fi

			$SQLITE "$DATABASE_NAME.db" "$_MODE" "$_QUERY";
		;;
		"pgsql" )
		  if [[ "$FORMAT" == "true" ]]; then _MODE="";
		  else _MODE="-t";
		  fi
			_COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			$_COMMAND $_MODE -c "$_QUERY";
		;;
		* )
			warn "Only sqlite and pgsql is supported right now.";
		;;
	esac
}

######################################################
# Queries blood table for given number of entries
# its a wrapper for query function
# Globals:
#  PRESSURE_TABLE
# Arguments:
#  number of entries to receive
######################################################
function list_pressure() {
  readonly _LIST_PRESSURE=$1;

  _QUERY="SELECT datetime,
    systolic ||
    (
      CASE WHEN systolic > syst.vmax THEN ' ↑'
           WHEN systolic < syst.vmin THEN ' ↓'
      ELSE ''
      END
    ) AS systolic,
    diastolic ||
    (
      CASE WHEN diastolic > dias.vmax THEN ' ↑'
           WHEN diastolic < dias.vmin THEN ' ↓'
      ELSE ''
      END
    ) AS diastolic,
    pulse ||
    (
      CASE WHEN pulse > puls.vmax THEN ' ↑'
           WHEN pulse < puls.vmin THEN ' ↓'
      ELSE ''
      END
    ) AS pulse, comment
  FROM pressure
  LEFT OUTER JOIN norms syst ON ('systolic'=syst.name AND syst.human='${HUMAN_MAP[$HUMAN]}')
  LEFT OUTER JOIN norms dias ON ('diastolic'=dias.name AND dias.human='${HUMAN_MAP[$HUMAN]}')
  LEFT OUTER JOIN norms puls ON ('pulse'=puls.name AND puls.human='${HUMAN_MAP[$HUMAN]}')
  ORDER BY datetime DESC LIMIT $_LIST_PRESSURE";

  query "$_QUERY";
}

######################################################
# Queries sugar table for given number of entries
# its a wrapper for query function
# Globals:
#  SUGAR_TABLE
#  HUMAN
# Arguments:
#  number of entries to receive
######################################################
function list_sugar() {

  readonly _LIST_SUGAR=$1;

  _QUERY="SELECT datetime, sugar ||
    (
     CASE WHEN sugar > vmax THEN ' ↑'
          WHEN sugar < vmin THEN ' ↓'
     ELSE ''
      END
     ), comment
     FROM $SUGAR_TABLE
     LEFT OUTER JOIN norms ON (
     (
      CASE WHEN sugar.stomach='f' THEN 'sugar full'
           WHEN sugar.stomach='e' THEN 'sugar empty'
      END
     )=norms.name AND human='${HUMAN_MAP[$HUMAN]}'
    )
    ORDER BY datetime DESC LIMIT $_LIST_SUGAR";

    query "$_QUERY";
}

######################################################
# Queries urine_acid table for given number of entries
# its a wrapper for query function
# Globals:
#  URINE_ACID_TABLE
# Arguments:
#  number of entries to receive
######################################################
function list_urine_acid() {
  readonly _LIST_URINE_ACID=$1;

  _QUERY="SELECT datetime, urine ||
    (
     CASE WHEN urine > vmax THEN ' ↑'
          WHEN urine < vmin THEN ' ↓'
     ELSE ''
     END
     ), comment
    FROM urine_acid
    LEFT OUTER JOIN norms ON ('urine acid'=norms.name AND human='${HUMAN_MAP[$HUMAN]}')
    ORDER BY datetime DESC LIMIT $_LIST_URINE_ACID";

  query "$_QUERY";
}

######################################################
# Queries cholesterol table for given number of entries
# its a wrapper for query function
# Globals:
#  CHOLESTEROL_TABLE
# Arguments:
#  number of entries to receive
######################################################
function list_cholesterol() {
  readonly _LIST_CHOLESTEROL=$1;

  _QUERY="SELECT datetime, cholesterol ||
    (
     CASE WHEN cholesterol > vmax THEN ' ↑'
          WHEN cholesterol < vmin THEN ' ↓'
     ELSE ''
     END
     ), comment
    FROM cholesterol
    LEFT OUTER JOIN norms ON ('cholesterol'=norms.name AND human='${HUMAN_MAP[$HUMAN]}')
    ORDER BY datetime DESC LIMIT $_LIST_CHOLESTEROL";

  query "$_QUERY";
}

###########################################################
# validates and composes given time in format as follow
# 'yyyy-MM-dd HH:mm'
# 'HH:mm'
# to sql valid format
# if format is invalid or empty then current time 'now' is returned
# Globals:
#   DB_ENGINE
# Arguments:
#   time string to be validated
###########################################################
function sql_time() {
  readonly _TIME=$1;

  _VALID=$(echo "$_TIME" | grep -G "^20[2-4][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]$");
  if [[ "$_VALID" != "" ]]; then
    echo "'$_TIME'";
    return
  fi

  _VALID=$(echo "$_TIME" | grep -G "^[0-2][0-9]:[0-5][0-9]$");
  if [[ "$_VALID" != "" ]]; then
    echo "'$(date +'%Y-%m-%d') $_TIME'"
    return
  fi

  case $DB_ENGINE in
    "sqlite" )
      echo "strftime('%Y-%m-%d %H:%M:%f','now', 'localtime')";
    ;;
    "pgsql" )
      echo "'now'";
    ;;
	* )
			warn "Only sqlite and pgsql is supported right now.";
    ;;
  esac

}

############################################
# Adds entry to blood table
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   PRESSURE_TABLE
#   PGSQL
#   SQLITE
# Arguments:
#   measurement string to be parsed
############################################
function pressure_add() {
	# validate input
	readonly _MEASUREMENT=$1;
	readonly _PRESSURE_TIME=$2;

	if [ "$_MEASUREMENT" = "" ] ; then
		helpme
		exit 1;
	else
		# parsing 120/80/90/'optional comment' like measurement input
		_SYSTOLIC=$(echo "$_MEASUREMENT" | awk -F '/' '{print $1}')
		_DIASTOLIC=$(echo "$_MEASUREMENT" | awk -F '/' '{print $2}')
		_PULSE=$(echo "$_MEASUREMENT" | awk -F '/' '{print $3}')
		_COMMENT=$(echo "$_MEASUREMENT" | awk -F '/' '{print $4}')
	fi

	# adding pressure
	info "measurement: $_MEASUREMENT";
	info "Systolic: \"$_SYSTOLIC\"";
	info "Diastolic: \"$_DIASTOLIC"\";
	info "Pulse: \"$_PULSE\"";
	info "Comment: \"$_COMMENT\"";

	if ! [[ $_SYSTOLIC =~ ^[0-9]+$ ]] ; then fail "Systolic" "$_SYSTOLIC"; fi
	if ! [[ $_DIASTOLIC =~ ^[0-9]+$ ]] ; then fail "Diastolic" "$_DIASTOLIC"; fi
	if ! [[ $_PULSE =~ ^[0-9]+$ ]] ; then fail "Pulse" "$_PULSE"; fi

  _SQL_TIME=$(sql_time "$_PRESSURE_TIME")

	case $DB_ENGINE in
		"sqlite" )
			_QUERY="INSERT INTO $PRESSURE_TABLE (
				datetime, systolic, diastolic, pulse, comment) VALUES (
				$_SQL_TIME, $_SYSTOLIC, $_DIASTOLIC, $_PULSE, \"$_COMMENT\"
			);"
			
			echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
		;;
		"pgsql" )
			_QUERY="INSERT INTO $PRESSURE_TABLE (
				datetime, systolic, diastolic, pulse, comment) VALUES (
				$_SQL_TIME, $_SYSTOLIC, $_DIASTOLIC, $_PULSE, '$_COMMENT'
			);"
			
			_COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
		;;
	* )
			warn "Only sqlite and pgsql is supported right now.";
    ;;
	esac
}

############################################
# Adds sugar entry to sugar table.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   SUGAR_TABLE
#   PGSQL
#   SQLITE
# Arguments:
#   measurement string to be parsed
############################################
function sugar_add() {
  readonly _MEASUREMENT=$1;
  readonly _STOMACH=$2;
	readonly _SUGAR_TIME=$3;

	debug "stomach: $_STOMACH";

  if [[ "$_MEASUREMENT" = "" ]] ; then
    helpme
    exit 1;
  else
    _SUGAR=$(echo "$_MEASUREMENT" | awk -F '/' '{print $1}')
		_COMMENT=$(echo "$_MEASUREMENT" | awk -F '/' '{print $2}')
  fi

  if [[ "$_STOMACH" = "" ]] ; then
    helpme
    exit 1;
  fi

  info "Sugar: \"$_SUGAR\"";

  if ! [[ "$_SUGAR" =~ ^[0-9]+$ ]] ; then fail "sugar" "$_SUGAR"; fi
      
  _SQL_TIME=$(sql_time "$_SUGAR_TIME");
  
  case $DB_ENGINE in
    "sqlite" )
      _QUERY="INSERT INTO $SUGAR_TABLE (
        datetime, sugar, comment, stomach) VALUES (
				$_SQL_TIME, $_SUGAR, \"$_COMMENT\", \"$_STOMACH\");"

      debug "$_QUERY";
      echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
    ;;
    "pgsql" )
      _QUERY="INSERT INTO $SUGAR_TABLE (
        datetime, sugar, comment, stomach) VALUES (
        $_SQL_TIME, $_SUGAR, '$_COMMENT', '$_STOMACH');"
			
      _COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
    ;;
  * )
			warn "Only sqlite and pgsql is supported right now.";
    ;;
	esac
}

############################################
# Adds urine acid entry to sugar table.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   URINE_ACID_TABLE
#   PGSQL
#   SQLITE
# Arguments:
#   measurement string to be parsed
############################################
function urine_acid_add() {
  readonly _MEASUREMENT=$1;
  readonly _URINE_ACID_TIME=$2;

  if [ "$_MEASUREMENT" = "" ]; then
    helpme
    exit 1;
  else
    _URINE_ACID=$(echo "$_MEASUREMENT" | awk -F '/' '{print $1}')
    _COMMENT=$(echo "$_MEASUREMENT" | awk -F '/' '{print $2}')
  fi

  info "Urine acid: \"$_URINE_ACID\"";

  if ! [[ "$_URINE_ACID" =~ ^[0-9]+$ ]] ; then fail "urine acid" "$_URINE_ACID"; fi

  _SQL_TIME=$(sql_time "$_URINE_ACID_TIME");

  case $DB_ENGINE in
    "sqlite" )
      _QUERY="INSERT INTO $URINE_ACID_TABLE (
        datetime, urine, comment) VALUES (
    	  $_SQL_TIME, $_URINE_ACID, \"$_COMMENT\");"

      echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
    ;;
    "pgsql" )
      _QUERY="INSERT INTO $URINE_ACID_TABLE (
        datetime, urine, comment) VALUES (
            $_SQL_TIME, $_URINE_ACID, '$_COMMENT');"

      _COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
    ;;
  * )
    warn "Only sqlite and pgsql is supported right now.";
    ;;
  esac
}

############################################
# Adds cholesterol entry to sugar table.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   CHOLESTEROL
#   PGSQL
#   SQLITE
# Arguments:
#   measurement string to be parsed
############################################
function cholesterol_add() {
  readonly _MEASUREMENT=$1;
  readonly _CHOLESTEROL_TIME=$2

  if [ "$_MEASUREMENT" = "" ]; then
    helpme
    exit 1;
  else
    _CHOLESTEROL=$(echo "$_MEASUREMENT" | awk -F '/' '{print $1}')
    _COMMENT=$(echo "$_MEASUREMENT" | awk -F '/' '{print $2}')
  fi

  info "Cholesterol: \"$_CHOLESTEROL\"";

  if ! [[ "$_CHOLESTEROL" =~ ^[0-9]+$ ]] ; then fail "cholesterol" "$_CHOLESTEROL"; fi

  _SQL_TIME=$(sql_time "$_CHOLESTEROL_TIME")

  case $DB_ENGINE in
    "sqlite" )
      _QUERY="INSERT INTO $CHOLESTEROL_TABLE (
        datetime, cholesterol, comment) VALUES (
    	  $_SQL_TIME, $_CHOLESTEROL, \"$_COMMENT\");"

      echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
    ;;
    "pgsql" )
      _QUERY="INSERT INTO $CHOLESTEROL_TABLE (
        datetime, cholesterol, comment) VALUES (
            $_SQL_TIME, $_CHOLESTEROL, '$_COMMENT');"

      _COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
    ;;
  * )
    warn "Only sqlite and pgsql is supported right now.";
    ;;
  esac
}

##############################################
# Initializes database from given init file.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   PGSQL
#   SQLITE
#   INIT_FILENAME
##############################################
function init() {
	case $DB_ENGINE in
		"sqlite" )
			# TODO: validate
			info "SQLITE: Executing: $SQLITE $DATABASE_NAME.db << $INIT_FILENAME";
			$SQLITE "$DATABASE_NAME.db" < "$INIT_FILENAME";
		;;
		"pgsql" )
			# TODO: validate
			info "$PGSQL postgresql://$DATABASE_USER:xxxxxxxx@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME < $INIT_FILENAME";
			$PGSQL "postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME" < "$INIT_FILENAME";
			;;
		* ) ;;
	esac
}

#######################################################
# Imports pressure data from .csv file into database.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   PRESSURE_TABLE
#   PGSQL
#   SQLITE
# Attributes:
#   ENGINE
#   IMPORT_FILENAME
########################################################
function import_pressure() {
	_ENGINE=$1
	_FILE=$2

	info "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			info "SQLITE: Importing from $_FILE into $PRESSURE_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".separator ','" ".mode csv" ".import $_FILE $PRESSURE_TABLE" ".exit"
		;;
		"pgsql" )
			info "$PGSQL postgresql://$DATABASE_USER:xxxxxxxx@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			info "-c \"\\COPY tmp_$PRESSURE_TABLE(datetime, systolic, diastolic, pulse, comment) FROM $_FILE DELIMITER ',' CSV\";";
			_COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$_COMMAND -c "CREATE TABLE tmp_$PRESSURE_TABLE AS TABLE $PRESSURE_TABLE;";
			$_COMMAND -c "\\COPY tmp_$PRESSURE_TABLE(datetime, systolic, diastolic, pulse, comment) FROM $_FILE DELIMITER ',' CSV;";
			$_COMMAND -c "INSERT INTO $PRESSURE_TABLE(datetime, systolic, diastolic, pulse, comment) SELECT datetime, systolic, diastolic, pulse, comment FROM tmp_$PRESSURE_TABLE ON CONFLICT DO NOTHING;";
			$_COMMAND -c "DROP TABLE tmp_$PRESSURE_TABLE;";
		;;
		* ) critical "engine is not set!";;
	esac
}

#######################################################
# Imports sugar data from .csv file into database.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   SUGAR_TABLE
#   PGSQL
#   SQLITE
# Attributes:
#   ENGINE
#   IMPORT_FILENAME
########################################################
function import_sugar() {
  _ENGINE=$1
  _FILE=$2

	info "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			info "SQLITE: Importing from $_FILE into $SUGAR_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".separator ','" ".mode csv" ".import $_FILE $SUGAR_TABLE" ".exit"
		;;
		"pgsql" )
			info "$PGSQL postgresql://$DATABASE_USER:xxxxxxxx@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			info "-c \"\\COPY tmp_$SUGAR_TABLE(datetime, sugar, comment, stomach) FROM $_FILE DELIMITER ',' CSV\";";
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$COMMAND -c "CREATE TABLE tmp_$SUGAR_TABLE AS TABLE $SUGAR_TABLE;";
			$COMMAND -c "\\COPY tmp_$SUGAR_TABLE(datetime, sugar, comment, stomach) FROM $_FILE DELIMITER ',' CSV;";
			$COMMAND -c "INSERT INTO $SUGAR_TABLE(datetime, sugar, comment, stomach) SELECT datetime, sugar, comment, stomach FROM tmp_$SUGAR_TABLE ON CONFLICT DO NOTHING;";
			$COMMAND -c "DROP TABLE tmp_$SUGAR_TABLE;";
		;;
		* ) critical "engine is not set!";;
	esac
}

#######################################################
# Imports urine_acid data from .csv file into database.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   URINE_ACID_TABLE
#   PGSQL
#   SQLITE
# Attributes:
#   ENGINE
#   IMPORT_FILENAME
########################################################
function import_urine_acid() {
  _ENGINE=$1
  _FILE=$2

	info "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			info "SQLITE: Importing from $_FILE into $URINE_ACID_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".separator ','" ".mode csv" ".import $_FILE $URINE_ACID_TABLE" ".exit"
		;;
		"pgsql" )
			info "$PGSQL postgresql://$DATABASE_USER:xxxxxxxx@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			info "-c \"\\COPY tmp_$URINE_ACID_TABLE(datetime, urine, comment) FROM $_FILE DELIMITER ',' CSV\";";
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$COMMAND -c "CREATE TABLE tmp_$URINE_ACID_TABLE AS TABLE $URINE_ACID_TABLE;";
			$COMMAND -c "\\COPY tmp_$URINE_ACID_TABLE(datetime, urine, comment) FROM $_FILE DELIMITER ',' CSV;";
			$COMMAND -c "INSERT INTO $URINE_ACID_TABLE(datetime, urine, comment) SELECT datetime, urine, comment FROM tmp_$URINE_ACID_TABLE ON CONFLICT DO NOTHING;";
			$COMMAND -c "DROP TABLE tmp_$URINE_ACID_TABLE;";
		;;
		* ) critical "engine is not set!";;
	esac
}

#######################################################
# Imports cholesterol data from .csv file into database.
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   URINE_ACID_TABLE
#   PGSQL
#   SQLITE
# Attributes:
#   ENGINE
#   IMPORT_FILENAME
########################################################
function import_cholesterol() {
  _ENGINE=$1
  _FILE=$2

	info "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			info "SQLITE: Importing from $_FILE into $CHOLESTEROL_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".separator ','" ".mode csv" ".import $_FILE $CHOLESTEROL_TABLE" ".exit"
		;;
		"pgsql" )
			info "$PGSQL postgresql://$DATABASE_USER:xxxxxxxx@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			info "-c \"\\COPY tmp_$CHOLESTEROL_TABLE(datetime, cholesterol, comment) FROM $_FILE DELIMITER ',' CSV\";";
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$COMMAND -c "CREATE TABLE tmp_$CHOLESTEROL_TABLE AS TABLE $CHOLESTEROL_TABLE;";
			$COMMAND -c "\\COPY tmp_$CHOLESTEROL_TABLE(datetime, cholesterol, comment) FROM $_FILE DELIMITER ',' CSV;";
			$COMMAND -c "INSERT INTO $CHOLESTEROL_TABLE(datetime, cholesterol, comment) SELECT datetime, cholesterol, comment FROM tmp_$CHOLESTEROL_TABLE ON CONFLICT DO NOTHING;";
			$COMMAND -c "DROP TABLE tmp_$CHOLESTEROL_TABLE;";
		;;
		* ) critical "engine is not set!";;
	esac
}

function list_norms_pressure() {
  echo "Norms for: Pressure";
  local _QUERY="SELECT name, vmin, vmax FROM norms WHERE name IN ('systolic', 'diastolic', 'pulse') AND human='${HUMAN_MAP[$HUMAN]}'";
  query "$_QUERY";
  echo "";
}

function list_norm() {
  local _NORMS="$1";
  local _DESCRIPTION="$2";
  echo "Norms for: $_DESCRIPTION";
  local _QUERY="SELECT vmin || ' - ' || vmax  FROM norms WHERE name='$_NORMS' AND human='${HUMAN_MAP[$HUMAN]}'";
  query "$_QUERY"
  echo "";
}


function list_norms() {
  local _NORMS=$1;

  case $_NORMS in
    "pressure" )
      list_norms_pressure
      ;;
    "sugar" )
      list_norm "sugar empty" "Sugar on empty stomach";
      list_norm "sugar full" "Sugar on full stomach";
      ;;
    "sugar_empty" )
      list_norm "sugar empty" "Sugar on empty stomach";
      ;;
    "sugar_full" )
      list_norm "sugar full" "Sugar on full stomach";
      ;;
    "cholesterol" )
      list_norm "cholesterol" "Cholesterol";
      ;;
    "urine_acid" )
      list_norm "urine acid" "Urine acid";
      ;;
    "all" )
      list_norms_pressure
      list_norm "cholesterol" "Cholesterol";
      list_norm "sugar empty" "Sugar on empty stomach";
      list_norm "sugar full" "Sugar on full stomach";
      list_norm "urine acid" "Urine acid";
      ;;
  esac

}

#####################################################
# Synchronize local sqlite database with postgresql
# Globals:
#   DB_ENGINE
#   DATABASE_NAME
#   DATABASE_USER
#   DATABASE_PASSWD
#   DATABASE_HOST
#   DATABASE_PORT
#   PRESSURE_TABLE
#   SUGAR_TABLE
#   PGSQL
#   SQLITE
#####################################################
function sync() {
	 _SOURCE=$(echo "$OPTION_SYNC" | awk -F ':' '{print $1}');
	readonly _SOURCE
	_DESTINATION=$(echo "$OPTION_SYNC" | awk -F ':' '{print $2}');
  readonly _DESTINATION

	log "Syncing $_SOURCE to $_DESTINATION";

	case $_SOURCE in
		"sqlite" )
			_TMP_FILE=$(mktemp -q)
			if [[ ! -f "$_TMP_FILE" ]]; then
    		error "$0: Can't create temp file, bye..."
    		exit 1
			fi

			$SQLITE -list -separator ',' "$DATABASE_NAME.db" \
		    "SELECT datetime, systolic, diastolic, pulse, '\"' || REPLACE(comment, '\"', '\"\"') || '\"' FROM $PRESSURE_TABLE;" \
			  > "$_TMP_FILE";
			debug "cat $_TMP_FILE:";
      debug "$(cat "$_TMP_FILE")";
			import_pressure "$_DESTINATION" "$_TMP_FILE";

      $SQLITE -list -separator ',' "$DATABASE_NAME.db" \
        "SELECT datetime, sugar, '\"' || REPLACE(comment, '\"', '\"\"') || '\"', stomach FROM $SUGAR_TABLE;" \
        > "$_TMP_FILE";
      debug "cat $_TMP_FILE:";
      debug "$(cat "$_TMP_FILE")";
      import_sugar "$_DESTINATION" "$_TMP_FILE";

      debug "Urine acid table: $URINE_ACID_TABLE"
      $SQLITE -list -separator ',' "$DATABASE_NAME.db" \
        "SELECT datetime, urine, '\"' || REPLACE(comment, '\"', '\"\"') || '\"' FROM $URINE_ACID_TABLE;" \
        > "$_TMP_FILE";
      debug "cat $_TMP_FILE:";
      debug "$(cat "$_TMP_FILE")";
      import_urine_acid "$_DESTINATION" "$_TMP_FILE";

      $SQLITE -list -separator ',' "$DATABASE_NAME.db" \
        "SELECT datetime, cholesterol, '\"' || REPLACE(comment, '\"', '\"\"') || '\"' FROM $CHOLESTEROL_TABLE;" \
        > "$_TMP_FILE";
      debug "cat $_TMP_FILE:";
      debug "$(cat "$_TMP_FILE")";
      import_cholesterol "$_DESTINATION" "$_TMP_FILE";

			rm "$_TMP_FILE";
		;;
		"pgsql" )
			warn "Feature not implemented yet, only sqlite:pgsql is supported";
		;;
		* ) critical "engine is not set!";;
	esac
}

###################################################################
# Displays error message when parameter is missing for cli option
# Attributes:
#   PARAMETER_NAME
###################################################################
function missing_parameter_error() {
  log
  error "Missing parameter for option $1\n";
  helpme
  exit 1
}

######################################################################################
# Main function
######################################################################################
function main() {
  if [ $# -eq 0 ]; then
    helpme
    exit 1;
  fi

  readonly _BLOOD_PROPERTIES=./blood.properties
  DIRNAME=$(dirname "${BASH_SOURCE[0]}")
  log "Trying to use $DIRNAME/blood.properties";
  # cat $DIRNAME/$_BLOOD_PROPERTIES

  source "$DIRNAME/$_BLOOD_PROPERTIES";
  if [ $# -eq 0 ]; then
    log "Trying to use ~/.bps2/blood.properties";
    source "$HOME/.bps2/blood.properties"
    DIRNAME="$HOME/.bps2/";
    DATABASE_NAME="$DIRNAME/$DATABASE_NAME"
  fi

  if [ $# -eq 0 ]; then
    error "blood.properties not found!"
	  helpme
	  exit 1;
  fi

  while true; do
    case "$1" in
      -a | --urine-acid )
        if [[ "$2" != "" ]]; then readonly OPTION_URINE_ACID=$2; shift 2 ;
        else missing_parameter_error "$1";
        fi
        ;;
      -A | --import-urine-acid )
        if [[ "$2" != "" ]]; then readonly IMPORT_URINE_ACID=$2; shift 2;
        else missing_parameter_error "$1";
        fi
        ;;
      -b | --database-port )
        if [[ "$2" != "" ]]; then readonly DATABASE_PORT=$2; shift 2;
        else missing_parameter_error "$1";
        fi
        ;;
      -c | --cholesterol )
        if [[ "$2" != "" ]]; then readonly OPTION_CHOLESTEROL=$2; shift 2;
        else missing_parameter_error "$1";
        fi
        ;;
      -C | --import-cholesterol )
        if [[ "$2" != "" ]]; then readonly IMPORT_CHOLESTEROL=$2; shift 2;
        else missing_parameter_error "$1";
        fi
        ;;
      -D | --dbname )
          if [[ "$2" != "" ]]; then readonly DATABASE_NAME=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -e | --engine )
          if [[ "$2" != "" ]]; then readonly DB_ENGINE=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -f | --format )
          FORMAT="true";
          # ansi formatting codes
          COLOR_GREEN="\u001b[32;1m"
          COLOR_RESET="\u001b[0m"
          shift ;
          ;;
      -h | --help ) helpme; exit 0;;
      -H | --host )
          if [[ "$2" != "" ]]; then readonly DATABASE_HOST=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -i | --initialize )
          if [[ "$2" != "" ]]; then readonly INIT_FILENAME=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -l | --list )
          if [[ $2 =~ ^[0-9]+$ ]]; then readonly LIST=$2; shift 2;
          else readonly LIST=$LIST_ENTRIES; shift;
          fi
        ;;
      --list-cholesterol )
          if [[ "$2" =~ [0-9]+ ]]; then readonly LIST_CHOLESTEROL=$2; shift 2;
          else readonly LIST_CHOLESTEROL=$LIST_ENTRIES; shift;
          fi
        ;;
      --list-pressure )
          if [[ "$2" =~ [0-9]+ ]]; then readonly LIST_PRESSURE=$2; shift 2 ;
          else readonly LIST_PRESSURE=$LIST_ENTRIES; shift;
          fi
        ;;
      --list-sugar )
          if [[ "$2" =~ [0-9]+ ]]; then readonly LIST_SUGAR=$2; shift 2 ;
          else readonly LIST_SUGAR=$LIST_ENTRIES; shift;
          fi
        ;;
      --list-urine-acid )
          if [[ "$2" =~ [0-9]+ ]]; then readonly LIST_URINE_ACID=$2; shift 2 ;
          else readonly LIST_URINE_ACID=$LIST_ENTRIES; shift;
          fi
        ;;
      --log-level )
          if [[ "$2" != "" ]]; then readonly LOG_LEVEL=$2; shift 2 ;
          else readonly LOG_LEVEL=$LOG_LEVEL; shift;
          fi
        ;;
      -n | --norms )
          if [[ "$2" =~ ^\-.* ]] || [[ "$2" == "" ]]; then readonly LIST_NORMS="all"; shift;
          else readonly LIST_NORMS="$2"; shift;
          fi
        ;;
      -p | --pressure )
          if [[ "$2" != "" ]]; then readonly OPTION_PRESSURE=$2; shift 2;
          else missing_parameter_error "$1";
          fi
        ;;
      -P | --import-pressure )
          if [[ "$2" != "" ]]; then readonly IMPORT_PRESSURE=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -q | --query )
          if [[ "$2" != "" ]]; then readonly OPTION_QUERY=$2; shift 2;
          else missing_parameter_error "$1";
          fi
        ;;
      -s | --sugar )
          if [[ "$2" != "" ]]; then readonly OPTION_SUGAR=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      --empty )
          STOMACH_CONDITION="empty"; shift 1;
        ;;
      --full )
          STOMACH_CONDITION="full"; shift 1;
        ;;
      -S | --import-sugar )
          if [[ "$2" != "" ]]; then readonly IMPORT_SUGAR=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -t | --time )
          if [[ "$2" != "" ]]; then readonly OPTION_TIME=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -U | --user )
          if [[ "$2" != "" ]]; then readonly USER=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -v | --version ) version; ;;
      -X | --sync )
          if [[ "$2" != "" ]]; then readonly OPTION_SYNC=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -- ) shift; break ;;
      * ) break ;;
    esac
  done

  case "$DB_ENGINE" in
    sqlite ) info "Using sqlite database name: $DATABASE_NAME"; shift 2 ;;
    pgsql ) info "Using postgresql engine with name: $DATABASE_NAME"; shift 2 ;;
  esac

  if [[ "$INIT_FILENAME" != "" ]]; then
    init "$INIT_FILENAME";

  elif [[ "$IMPORT_PRESSURE" != "" ]]; then
    import_pressure "$DB_ENGINE" "$IMPORT_PRESSURE";

  elif [[ "$IMPORT_SUGAR" != "" ]]; then
    import_sugar "$DB_ENGINE" "$IMPORT_SUGAR";

  elif [[ "$IMPORT_URINE_ACID" != "" ]]; then
    import_urine_acid "$DB_ENGINE" "$IMPORT_URINE_ACID";

  elif [[ "$IMPORT_CHOLESTEROL" != "" ]]; then
    import_cholesterol "$DB_ENGINE" "$IMPORT_CHOLESTEROL";

  elif [[ "$OPTION_PRESSURE" != "" ]]; then
    pressure_add "$OPTION_PRESSURE" "$OPTION_TIME";

  elif [[ "$OPTION_SUGAR" ]]; then
    _STOMACH="${STOMACH_CONDITION_MAP[$STOMACH_CONDITION]}"
    if [[ "$_STOMACH" != "" ]]; then
      sugar_add "$OPTION_SUGAR" "$_STOMACH" "$OPTION_TIME";
    else
      error "configuration error, use options --empty or --full or set default into properties file";
      exit 1;
    fi
  elif [[ "$OPTION_URINE_ACID" ]]; then
    urine_acid_add "$OPTION_URINE_ACID" "$OPTION_TIME";

  elif [[ "$OPTION_CHOLESTEROL" ]]; then
    cholesterol_add "$OPTION_CHOLESTEROL" "$OPTION_TIME";

  elif [[ "$OPTION_SYNC" != "" ]]; then
    sync "$OPTION_SYNC";

  elif [[ "$OPTION_QUERY" != "" ]]; then
    query "$OPTION_QUERY";

  elif [[ "$LIST" != "" ]]; then
    debug "LIST=$LIST"
    log
    log "${COLOR_GREEN}Pressure:${COLOR_RESET}";
    list_pressure "$LIST";
    log
    log "${COLOR_GREEN}Sugar:${COLOR_RESET}";
    list_sugar "$LIST";
    log
    log "${COLOR_GREEN}Urine acid:${COLOR_RESET}";
    list_urine_acid "$LIST";
    log
    log "${COLOR_GREEN}Cholesterol:${COLOR_RESET}";
    list_cholesterol "$LIST";

  elif [[ "$LIST_PRESSURE" != "" ]]; then
    list_pressure "$LIST_PRESSURE";

  elif [[ "$LIST_SUGAR" != "" ]]; then
    list_sugar "$LIST_SUGAR";

  elif [[ "$LIST_URINE_ACID" != "" ]]; then
    list_urine_acid "$LIST_URINE_ACID";

  elif [[ "$LIST_CHOLESTEROL" != "" ]]; then
    list_cholesterol "$LIST_CHOLESTEROL";

  elif [[ "$LIST_NORMS" != "" ]]; then
    list_norms "$LIST_NORMS";

  else
    error "ERROR: Not enough parameters!"
    helpme;
  fi

}


