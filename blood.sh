#!/bin/bash
###############################################################################
# BPS2 (Blood Parameters Storage System) is a simple command line interface   #
# to store previous measured blood parameters such as pressure (diastolic,    #
# systolic and pulse) and sugar level.                                        #
# Author:     Paweł Prokop (pa810p@gmail.com)                                 #
# Repository: https://github.com/pa810p/bps2                                  #
# License:    GNU General Public License v3.0  see: LICENSE                   #
###############################################################################

######################################
# Displays Usage information and exit
######################################
function helpme() {
	echo "Usage: $0 [OPTIONS]";
	echo "OPTIONS include:";
  echo "-d --debug                     shows more detailed debug information";
	echo "-D --dbname DATABASE_NAME      database name";
	echo "-e --engine DATABASE_ENGINE    database engine can be either sqlite or pgsql";
	echo "-h --help                      help screen";
	echo "-H --host DATABASE_HOST        database host";
	echo "-i --initialize INIT_FILENAME  initialize filename";
	echo "-p --pressure MEASUREMENT      blood pressure measurement in format of eg.: 120/80/90/'comment'";
	echo "                               (systolic/diastolic/pulse/'comment') where comment is optional";
	echo "-q --query QUERY               SQL query provided to sqlite database (query should correspond with engine -e option)";
  echo "-s --sugar SUGAR_LEVEL         sugar level in blood in mg/dL";
	echo "-U --user USERNAME             database user name";
	echo "-X --sync SOURCE:DESTINATION   synchronize databases (copy data from SOURCE to DESTINATION database";
	echo "                               either SOURCE or DESTINATION may be: sqlite, pgsql";
	echo "";
	echo "Example: ";
	echo "./blood.sh -e pgsql -i createdb.sql";
  echo "./blood.sh -p 123/80/90/'my fancy comment'";
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

	readonly _QUERY=$1;

	log "Executing query: $_QUERY";

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

############################################
# Adds entry to blood table  #
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
				strftime('%Y-%m-%d %H:%M:%S','now', 'localtime'), $_SYSTOLIC, $_DIASTOLIC, $_PULSE, \"$_COMMENT\"
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
# Adds sugar entry to sugar table. #
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
				strftime('%Y-%m-%d %H:%M:%S','now', 'localtime'), $_SUGAR, \"$_COMMENT\");"

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
	readonly _SOURCE=$(echo "$OPTION_SYNC" | awk -F ':' '{print $1}');
	readonly _DESTINATION=$(echo "$OPTION_SYNC" | awk -F ':' '{print $2}');

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

######################################################################################
# Main function
######################################################################################
function main() {
  readonly _BLOOD_PROPERTIES=blood.properties

  source $_BLOOD_PROPERTIES;

  if [ $# -eq 0 ]; then
	  helpme
  fi

  while true; do
    case "$1" in
      -d | --debug ) readonly DEBUG="true"; shift 2 ;;
      -D | --dbname ) readonly DATABASE_NAME=$2; shift 2 ;;
      -e | --engine ) readonly DB_ENGINE=$2; shift 2 ;;
      -h | --help ) helpme;;
      -H | --host ) readonly DATABASE_HOST=$2; shift 2 ;;
      -i | --initialize ) readonly INIT_FILENAME=$2; shift 2 ;;
      -p | --pressure ) readonly OPTION_PRESSURE=$2; shift 2 ;;
      -P | --import-pressure ) readonly IMPORT_PRESSURE=$2; shift 2 ;;
      -q | --query ) readonly OPTION_QUERY=$2; shift 2 ;;
      -s | --sugar ) readonly OPTION_SUGAR=$2; shift 2 ;;
      -S | --import-sugar ) readonly IMPORT_SUGAR=$2; shift 2 ;;
      -X | --sync ) readonly OPTION_SYNC=$2; shift 2 ;;
      -U | --user ) readonly USER=$2; shift 2 ;;
      -- ) shift; break ;;
      * ) break ;;
    esac
  done

  if [ "$INIT_FILENAME" != "" ]; then
    init "$INIT_FILENAME";

  elif [ "$IMPORT_PRESSURE" != "" ]; then
    import_pressure "$DB_ENGINE" "$IMPORT_PRESSURE";

  elif [ "$IMPORT_SUGAR" != "" ]; then
    import_sugar "$DB_ENGINE" "$IMPORT_SUGAR";

  elif [ "$OPTION_PRESSURE" != "" ]; then
    pressure_add "$OPTION_PRESSURE";

  elif [ "$OPTION_SUGAR" ]; then
    sugar_add "$OPTION_SUGAR";

  elif [ "$OPTION_SYNC" != "" ]; then
    sync "$OPTION_SYNC";

  elif [ "$OPTION_QUERY" != "" ]; then
    query "$OPTION_QUERY";

  else
    echo
    echo "ERROR: Not enough parameters!"
    echo
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