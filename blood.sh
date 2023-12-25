#!/bin/bash
###############################################################################
# BPS2 (Blood Parameters Storage System) is a simple command line interface   #
# to store previous measured blood parameters such as pressure (diastolic,    #
# systolic and pulse) sugar level, and urine acid level.                      #
# Author:     Paweł Prokop (pa810p@gmail.com)                                 #
# Repository: https://github.com/pa810p/bps2                                  #
# License:    GNU General Public License v3.0  see: LICENSE                   #
###############################################################################

VERSION=1.0.2-20231225

######################################
# Displays Usage information and exit
######################################
function helpme() {
  echo "Version: $VERSION";
	echo "Usage: $0 [OPTIONS]";
	echo "OPTIONS include:";
  echo "-d --debug                         shows more detailed debug information";
	echo "-D --dbname DATABASE_NAME          database name";
	echo "-e --engine DATABASE_ENGINE        database engine can be either sqlite or pgsql";
	echo "-h --help                          help screen";
	echo "-H --host DATABASE_HOST            database host";
	echo "-i --initialize INIT_FILENAME      initialize filename";
	echo "-l [LIST_ENTRIES]                  list last LIST_ENTRIES (default from properties) entries of both pressure and sugar";
	echo "   --list-pressure [LIST_ENTRIES]  list last LIST ENTRIES (default from properties) entries of pressure";
	echo "   --list-sugar [LIST_ENTRIES]     list last LIST_ENTRIES (default from properties) entries of sugar"
	echo "-p --pressure MEASUREMENT          blood pressure measurement in format of eg.: 120/80/90/'comment'";
	echo "-P --import_pressure FILENAME      import pressure from csv FILENAME";
	echo "                                   (systolic/diastolic/pulse/'comment') where comment is optional";
	echo "-q --query QUERY                   SQL query provided to sqlite database (query should correspond with engine -e option)";
	echo "-R --import-urine-acid FILENAME    import urine acid from csv FILENAME";
  echo "-s --sugar SUGAR_LEVEL             sugar level in blood in mg/dL using format of eg.: 123/'comment'";
  echo "                                   where 'comment' is optional";
  echo "-S --import-sugar FILENAME         import sugar from csv FILENAME";
  echo "-u --urine-acid URINE_ACID         urine acid in blood in µmol/l using format of eg.: 370/'comment'";
  echo "                                   where 'comment' is optional";
	echo "-U --user USERNAME                 database user name";
	echo "-v --version                       displays version information and exits";
	echo "-X --sync SOURCE:DESTINATION       synchronize databases (copy data from SOURCE to DESTINATION database";
	echo "                                   either SOURCE or DESTINATION may be: sqlite, pgsql";
	echo "";
	echo "Example: ";
	echo "./blood.sh -e pgsql -i createdb.sql";
  echo "./blood.sh -p 123/80/90/'my fancy comment'";
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
  if [ "$DEBUG" = "true" ] ; then
    log "$1";
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
			echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
		;;
		"pgsql" )
			_COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			$_COMMAND -c "$_QUERY";
		;;
		* )
			log "Only sqlite and pgsql is supported right now.";
		;;
	esac
}

######################################################
# Queries blood table for given number of entries
# its a wrapper for query function
# Arguments:
#  number of entries to receive
######################################################
function log_pressure() {

  readonly _LOG_PRESSURE=$1;

  query "SELECT * FROM blood ORDER BY datetime DESC LIMIT $_LOG_PRESSURE";

}

######################################################
# Queries sugar table for given number of entries
# its a wrapper for query function
# Arguments:
#  number of entries to receive
######################################################
function log_sugar() {

  readonly _LOG_SUGAR=$1;

  query "SELECT * FROM sugar ORDER BY datetime DESC LIMIT $_LOG_SUGAR";

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
#   BLOOD_TABLE
#   PGSQL
#   SQLITE
# Arguments:
#   measurement string to be parsed
############################################
function pressure_add() {
	# validate input
	readonly _MEASUREMENT=$1;

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

	log "measurement: $_MEASUREMENT";
	log "Systolic: \"$_SYSTOLIC\"";
	log "Diastolic: \"$_DIASTOLIC"\";
	log "Pulse: \"$_PULSE\"";
	log "Comment: \"$_COMMENT\"";

	if ! [[ $_SYSTOLIC =~ ^[0-9]+$ ]] ; then fail "Systolic" "$_SYSTOLIC"; fi
	if ! [[ $_DIASTOLIC =~ ^[0-9]+$ ]] ; then fail "Diastolic" "$_DIASTOLIC"; fi
	if ! [[ $_PULSE =~ ^[0-9]+$ ]] ; then fail "Pulse" "$_PULSE"; fi

	case $DB_ENGINE in
		"sqlite" )
			_QUERY="INSERT INTO $BLOOD_TABLE (
				datetime, systolic, diastolic, pulse, comment) VALUES (
				strftime('%Y-%m-%d %H:%M:%f','now', 'localtime'), $_SYSTOLIC, $_DIASTOLIC, $_PULSE, \"$_COMMENT\"
			);"
			
			echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
		;;
		"pgsql" )
			_QUERY="INSERT INTO $BLOOD_TABLE (
				datetime, systolic, diastolic, pulse, comment) VALUES (
				'now', $_SYSTOLIC, $_DIASTOLIC, $_PULSE, '$_COMMENT'
			);"
			
			_COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
		;;
	* )
			log "Only sqlite and pgsql is supported right now.";
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
  
  if [ "$_MEASUREMENT" = "" ] ; then
    helpme
    exit 1;
  else
    _SUGAR=$(echo "$_MEASUREMENT" | awk -F '/' '{print $1}')
		_COMMENT=$(echo "$_MEASUREMENT" | awk -F '/' '{print $2}')
  fi

  log "Sugar: \"$_SUGAR\"";

  if ! [[ "$_SUGAR" =~ ^[0-9]+$ ]] ; then fail "sugar" "$_SUGAR"; fi

  case $DB_ENGINE in
    "sqlite" )
      _QUERY="INSERT INTO $SUGAR_TABLE (
        datetime, sugar, comment) VALUES (
				strftime('%Y-%m-%d %H:%M:%f','now', 'localtime'), $_SUGAR, \"$_COMMENT\");"

      echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
    ;;
    "pgsql" )
      _QUERY="INSERT INTO $SUGAR_TABLE (
        datetime, sugar, comment) VALUES (
        'now', $_SUGAR, '$_COMMENT');"
			
      _COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
    ;;
  * )
			log "Only sqlite and pgsql is supported right now.";
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

  if [ "$_MEASUREMENT" = "" ]; then
    helpme
    exit 1;
  else
    _URINE_ACID=$(echo "$_MEASUREMENT" | awk -F '/' '{print $1}')
    _COMMENT=$(echo "$_MEASUREMENT" | awk -F '/' '{print $2}')
  fi

  log "Urine acid: \"$_URINE_ACID\"";

  if ! [[ "$_URINE_ACID" =~ ^[0-9]+$ ]] ; then fail "urine acid" "$_URINE_ACID"; fi

  case $DB_ENGINE in
    "sqlite" )
      _QUERY="INSERT INTO $URINE_ACID_TABLE (
        datetime, urine, comment) VALUES (
    	  strftime('%Y-%m-%d %H:%M:%f','now', 'localtime'), $_URINE_ACID, \"$_COMMENT\");"

      echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
    ;;
    "pgsql" )
      _QUERY="INSERT INTO $URINE_ACID_TABLE (
        datetime, urine, comment) VALUES (
            'now', $_URINE_ACID, '$_COMMENT');"

      _COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $_COMMAND -c "$_QUERY";
    ;;
  * )
    log "Only sqlite and pgsql is supported right now.";
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
			log "SQLITE: Executing: $SQLITE $DATABASE_NAME.db << $INIT_FILENAME";
			$SQLITE "$DATABASE_NAME.db" < "$INIT_FILENAME";
		;;
		"pgsql" )
			# TODO: validate
			log "$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME < $INIT_FILENAME";
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
#   BLOOD_TABLE
#   PGSQL
#   SQLITE
# Attributes:
#   ENGINE
#   IMPORT_FILENAME
########################################################
function import_pressure() {
	readonly _ENGINE=$1
	readonly _FILE=$2

	echo "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			log "SQLITE: Importing from $_FILE into $BLOOD_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".mode csv" ".import $_FILE $BLOOD_TABLE" ".exit"
		;;
		"pgsql" )
			log "$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			log "-c \"\\COPY tmp_$BLOOD_TABLE(datetime, systolic, diastolic, pulse, comment) FROM $_FILE DELIMITER ',' CSV\";";
			_COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$_COMMAND -c "CREATE TABLE tmp_$BLOOD_TABLE AS TABLE $BLOOD_TABLE;";
			$_COMMAND -c "\\COPY tmp_$BLOOD_TABLE(datetime, systolic, diastolic, pulse, comment) FROM $_FILE DELIMITER ',' CSV;";
			$_COMMAND -c "INSERT INTO $BLOOD_TABLE(datetime, systolic, diastolic, pulse, comment) SELECT datetime, systolic, diastolic, pulse, comment FROM tmp_$BLOOD_TABLE ON CONFLICT DO NOTHING;";
			$_COMMAND -c "DROP TABLE tmp_$BLOOD_TABLE;";

		;;
		* ) ;;
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
  readonly _ENGINE=$1
  readonly _FILE=$2

	echo "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			log "SQLITE: Importing from $_FILE into $SUGAR_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".mode csv" ".import $_FILE $SUGAR_TABLE" ".exit"
		;;
		"pgsql" )
			log "$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			log "-c \"\\COPY tmp_$SUGAR_TABLE(datetime, sugar, comment) FROM $_FILE DELIMITER ',' CSV\";";
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$COMMAND -c "CREATE TABLE tmp_$SUGAR_TABLE AS TABLE $SUGAR_TABLE;";
			$COMMAND -c "\\COPY tmp_$SUGAR_TABLE(datetime, sugar, comment) FROM $_FILE DELIMITER ',' CSV;";
			$COMMAND -c "INSERT INTO $SUGAR_TABLE(datetime, sugar, comment) SELECT datetime, sugar, comment FROM tmp_$SUGAR_TABLE ON CONFLICT DO NOTHING;";
			$COMMAND -c "DROP TABLE tmp_$SUGAR_TABLE;";

		;;
		* ) ;;
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
  readonly _ENGINE=$1
  readonly _FILE=$2

	echo "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			log "SQLITE: Importing from $_FILE into $URINE_ACID_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".mode csv" ".import $_FILE $URINE_ACID_TABLE" ".exit"
		;;
		"pgsql" )
			log "$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			log "-c \"\\COPY tmp_$URINE_ACID_TABLE(datetime, urine, comment) FROM $_FILE DELIMITER ',' CSV\";";
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$COMMAND -c "CREATE TABLE tmp_$URINE_ACID_TABLE AS TABLE $URINE_ACID_TABLE;";
			$COMMAND -c "\\COPY tmp_$URINE_ACID_TABLE(datetime, urine, comment) FROM $_FILE DELIMITER ',' CSV;";
			$COMMAND -c "INSERT INTO $URINE_ACID_TABLE(datetime, urine, comment) SELECT datetime, urine, comment FROM tmp_$URINE_ACID_TABLE ON CONFLICT DO NOTHING;";
			$COMMAND -c "DROP TABLE tmp_$URINE_ACID_TABLE;";

		;;
		* ) ;;
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
#   BLOOD_TABLE
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
			if [ ! -f "$_TMP_FILE" ]; then
    		log "$0: Can't create temp file, bye..."
    		exit 1
			fi

			$SQLITE -list -separator ',' "$DATABASE_NAME.db" "SELECT datetime, systolic, diastolic, pulse, comment FROM $BLOOD_TABLE;" > "$_TMP_FILE";

			import_pressure "$_DESTINATION" "$_TMP_FILE";

      $SQLITE -list -separator ',' "$DATABASE_NAME.db" "SELECT datetime, sugar, comment FROM $SUGAR_TABLE;" > "$_TMP_FILE";

      import_sugar "$_DESTINATION" "$_TMP_FILE";
			
			rm "$_TMP_FILE";
		;;
		"pgsql" )
			log "Feature not implemented yet, only sqlite:pgsql is supported";
		;;
		* ) ;;
	esac

}

function missing_parameter_error() {
  log
  log "ERROR: Missing parameter for option $1\n";
  helpme
  exit 1
}

######################################################################################
# Main function
######################################################################################
function main() {
  readonly _BLOOD_PROPERTIES=./blood.properties
  DIRNAME=$(dirname ${BASH_SOURCE[0]})
  debug "Trying to use $DIRNAME/blood.properties"

  source "$DIRNAME/$_BLOOD_PROPERTIES"

  if [ $# -eq 0 ]; then
    source ~/.bps2/blood.properties
    DIRNAME="$HOME/.bps2/";
    log "Using sqlite database: $DIRNAME/$DATABASE_NAME.db";
    DATABASE_NAME="$DIRNAME/$DATABASE_NAME"
  fi

  if [ $# -eq 0 ]; then
	  helpme
	  exit 1;
  fi

  while true; do
    case "$1" in
      -d | --debug ) readonly DEBUG="true"; shift;;
      -D | --dbname )
          if [ "$2" != "" ]; then readonly DATABASE_NAME=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -e | --engine )
          if [ "$2" != "" ]; then readonly DB_ENGINE=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -h | --help ) helpme; exit 0;;
      -H | --host )
          if [ "$2" != "" ]; then readonly DATABASE_HOST=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -i | --initialize )
          if [ "$2" != "" ]; then readonly INIT_FILENAME=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -l | --list )
           if [ "$2" != "" ]; then readonly LIST=$2; shift 2;
           else readonly LIST=$LIST_ENTRIES; shift;
           fi
        ;;
      --list-pressure )
            if [ "$2" != "" ]; then readonly LIST_PRESSURE=$2; shift 2 ;
            else readonly LIST_PRESSURE=$LIST_ENTRIES; shift;
            fi
        ;;
      --list-sugar )
            if [ "$2" != "" ]; then readonly LIST_SUGAR=$2; shift 2 ;
            else readonly LIST_SUGAR=$LIST_ENTRIES; shift;
            fi
        ;;
      -p | --pressure )
          if [ "$2" != "" ]; then readonly OPTION_PRESSURE=$2; shift 2;
          else missing_parameter_error "$1";
          fi
        ;;
      -P | --import-pressure )
          if [ "$2" != "" ]; then readonly IMPORT_PRESSURE=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -q | --query )
          if [ "$2" != "" ]; then readonly OPTION_QUERY=$2; shift 2;
          else missing_parameter_error "$1";
          fi
        ;;
      -R | --import-urine-acid )
          if [ "$2" != "" ]; then readonly IMPORT_URINE_ACID; shift 2;
          else missing_parameter_error "$2";
          fi
        ;;
      -s | --sugar )
            if [ "$2" != "" ]; then readonly OPTION_SUGAR=$2; shift 2 ;
            else missing_parameter_error "$1";
            fi
        ;;
      -S | --import-sugar )
          if [ "$2" != "" ]; then readonly IMPORT_SUGAR=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
         ;;
      -u | --urine-acid )
          if [ "$2" != "" ]; then readonly OPTION_URINE_ACID=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -U | --user )
          if [ "$2" != "" ]; then readonly USER=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -v | --version ) version; ;;
      -X | --sync )
          if [ "$2" != "" ]; then readonly OPTION_SYNC=$2; shift 2 ;
          else missing_parameter_error "$1";
          fi
        ;;
      -- ) shift; break ;;
      * ) break ;;
    esac
  done

  case "$DB_ENGINE" in
    sqlite ) echo "Using sqlite database name: $DATABASE_NAME"; shift 2 ;;
    pgsql ) echo "Using postgresql engine with name: $DATABASE_NAME"; shift 2 ;;
  esac

  if [ "$INIT_FILENAME" != "" ]; then
    init "$INIT_FILENAME";

  elif [ "$IMPORT_PRESSURE" != "" ]; then
    import_pressure "$DB_ENGINE" "$IMPORT_PRESSURE";

  elif [ "$IMPORT_SUGAR" != "" ]; then
    import_sugar "$DB_ENGINE" "$IMPORT_SUGAR";

  elif [ "$IMPORT_URINE_ACID" != "" ]; then
    import_urine_acid "$DB_ENGINE" "$IMPORT_URINE_ACID";

  elif [ "$OPTION_PRESSURE" != "" ]; then
    pressure_add "$OPTION_PRESSURE";

  elif [ "$OPTION_SUGAR" ]; then
    sugar_add "$OPTION_SUGAR";

  elif [ "$OPTION_URINE_ACID" ]; then
    urine_acid_add "$OPTION_URINE_ACID";

  elif [ "$OPTION_SYNC" != "" ]; then
    sync "$OPTION_SYNC";

  elif [ "$OPTION_QUERY" != "" ]; then
    query "$OPTION_QUERY";

  elif [ "$LIST" != "" ]; then
    debug "LIST=$LIST"
    log
    log "Pressure:";
    log_pressure "$LIST";
    log
    log "Sugar:";
    log_sugar "$LIST";

  elif [ "$LIST_PRESSURE" != "" ]; then
    debug "LIST_PRESSURE=$LIST_PRESSURE"
    log_pressure "$LIST_PRESSURE";

  elif [ "$LIST_SUGAR" != "" ]; then
    debug "LIST_SUGAR=$LIST_SUGAR"
    log_sugar "$LIST_SUGAR";

  else
    log
    log "ERROR: Not enough parameters!"
    log
    helpme;
  fi

}

# ensure we're running in bash
SHELL=$(readlink /proc/$$/exe | awk -F '/' '{print $NF}')

if [ "$SHELL" != "bash" ]; then
  echo "$_ -> $(readlink "$_")";
  echo "Please use bash instead of $SHELL :";
  echo "\$ ./$0";
  echo "\$ bash $0";
fi;

main "$@";