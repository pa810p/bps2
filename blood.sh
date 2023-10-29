#!/bin/bash

################################################
helpme() {
	echo "Usage: $0 [OPTIONS]";
	echo "OPTIONS include:";
  echo "-d --debug                     shows more detailed debug information";
	echo "-D --dbname DATABASE_NAME      database name";
	echo "-e --engine DATABASE_ENGINE    database engine can be either sqlite or pgsql";
	echo "-h --help                      help screen";
	echo "-H --host HOST                 database host";
	echo "-i --initialize INIT_FILENAME  initialize filename";
	echo "-p --pressure MEASUREMENT      blood pressure measurement in format of eg.: 120/80/90/'comment'";
	echo "                               (systolic/diastolic/pulse/'comment') where comment is optional";
	echo "-q --query QUERY               SQL query provided to sqlite database (query should correspond with engine -e option)";
  echo "-s --sugar SUGAR_LEVEL         sugar level in blood in mg/dL";
  echo "-t --table TABLENAME           table name in database, blood by default";
	echo "-U --user USERNAME             database user name";
	echo "-X --sync SOURCE:DESTINATION   synchronize databases (copy data from SOURCE to DESTINATION database";
	echo "                               either SOURCE or DESTINATION may be: sqlite, pgsql";
	echo "";
	echo "Example: ";
	echo "./blood.sh -e pgsql -i createdb.sql";
  echo "./blood.sh -p 123/80/90/'my fancy comment'";
	exit 0;
}

#################################################
fail() {
	echo "Invalid parameter: $1: \"$2\" aborting!";
	helpme;
}

#################################################
log() {
	echo -e "$1";
}

#################################################
debug() {
  if [ "$DEBUG" = "true" ] ; then
    log "$1";
  fi
}

#######################
# executes sql query. #
#######################
query() {

	_QUERY=$1;

	log "Executing query: $_QUERY";

	case $DB_ENGINE in
		"sqlite" )
			echo "$_QUERY" | $SQLITE "$DATABASE_NAME.db";
		;;
		"pgsql" )
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			$COMMAND -c "$_QUERY";
		;;
		* )
			log "Only sqlite and pgsql is supported right now.";
		;;
	esac
}

############################################
# This function adds entry to blood table. #
############################################
add() {
	# validate input
	MEASUREMENT=$1;

	if [ "$MEASUREMENT" = "" ] ; then
		helpme
	else
		# parsing 120/80/90/'optional comment' like measurement input
		SYSTOLIC=$(echo "$MEASUREMENT" | awk -F '/' '{print $1}')
		DIASTOLIC=$(echo "$MEASUREMENT" | awk -F '/' '{print $2}')
		PULSE=$(echo "$MEASUREMENT" | awk -F '/' '{print $3}')
		COMMENT=$(echo "$MEASUREMENT" | awk -F '/' '{print $4}')
	fi

	# adding pressure

	log "measurement: $MEASUREMENT";
	log "Systolic: \"$SYSTOLIC\"";
	log "Diastolic: \"$DIASTOLIC"\";
	log "Pulse: \"$PULSE\"";
	log "Comment: \"$COMMENT\"";

	if ! [[ $SYSTOLIC =~ ^[0-9]+$ ]] ; then fail "Systolic" "$SYSTOLIC"; fi
	if ! [[ $DIASTOLIC =~ ^[0-9]+$ ]] ; then fail "Diastolic" "$DIASTOLIC"; fi
	if ! [[ $PULSE =~ ^[0-9]+$ ]] ; then fail "Pulse" "$PULSE"; fi

	case $DB_ENGINE in
		"sqlite" )
			QUERY="INSERT INTO $BLOOD_TABLE (
				datetime, systolic, diastolic, pulse, comment) VALUES (
				strftime('%Y-%m-%d %H:%M:%S','now', 'localtime'), $SYSTOLIC, $DIASTOLIC, $PULSE, \"$COMMENT\"
			);"
			
			echo "$QUERY" | $SQLITE "$DATABASE_NAME.db";
		;;
		"pgsql" )
			QUERY="INSERT INTO $BLOOD_TABLE (
				datetime, systolic, diastolic, pulse, comment) VALUES (
				'now', $SYSTOLIC, $DIASTOLIC, $PULSE, '$COMMENT'
			);"
			
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $COMMAND -c "$QUERY";
		;;
	* )
			log "Only sqlite and pgsql is supported right now.";
    ;;
	esac
}

############################################
# This function adds entry to sugar table. #
############################################
sugar() {
  MEASUREMENT=$1;
  
  if [ "$MEASUREMENT" = "" ] ; then
    helpme
  else
    SUGAR=$(echo "$MEASUREMENT" | awk -F '/' '{print $1}')
		COMMENT=$(echo "$MEASUREMENT" | awk -F '/' '{print $2}')
  fi

  log "Sugar: \"$SUGAR\"";

  if ! [[ "$SUGAR" =~ ^[0-9]+$ ]] ; then fail "sugar" "$SUGAR"; fi

  case $DB_ENGINE in
    "sqlite" )
      QUERY="INSERT INTO $SUGAR_TABLE (
        datetime, sugar, comment) VALUES (
				strftime('%Y-%m-%d %H:%M:%S','now', 'localtime'), $SUGAR, \"$COMMENT\");"

      echo "$QUERY" | $SQLITE "$DATABASE_NAME.db";
    ;;
    "pgsql" )
      QUERY="INSERT INTO $SUGAR_TABLE (
        datetime, sugar, comment) VALUES (
        'now', $SUGAR, '$COMMENT');"
			
      COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
      $COMMAND -c "$QUERY";
    ;;
  * )
			log "Only sqlite and pgsql is supported right now.";
    ;;
	esac
}

##############################################
# initializes database from given init file. #
##############################################
init() {
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

##############################################
# imports data from .csv file into database. #
# $1=DB_ENGINE                               #
# $2=IMPORT_BLOOD
##############################################
import_blood() {
	_ENGINE=$1
	_FILE=$2

	echo "Importing $_ENGINE from $_FILE";

	case $_ENGINE in
		"sqlite" )
			log "SQLITE: Importing from $_FILE into $BLOOD_TABLE on database $DATABASE_NAME.db";
			$SQLITE "$DATABASE_NAME.db" ".mode csv" ".import $_FILE $BLOOD_TABLE" ".exit"
		;;
		"pgsql" )
			log "$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME";
			log "-c \"\\COPY tmp_$BLOOD_TABLE(datetime, systolic, diastolic, pulse, comment) FROM $_FILE DELIMITER ',' CSV\";";
			COMMAND="$PGSQL postgresql://$DATABASE_USER:$DATABASE_PASSWD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"

			$COMMAND -c "CREATE TABLE tmp_$BLOOD_TABLE AS TABLE $BLOOD_TABLE;";
			$COMMAND -c "\\COPY tmp_$BLOOD_TABLE(datetime, systolic, diastolic, pulse, comment) FROM $_FILE DELIMITER ',' CSV;";
			$COMMAND -c "INSERT INTO $BLOOD_TABLE(datetime, systolic, diastolic, pulse, comment) SELECT datetime, systolic, diastolic, pulse, comment FROM tmp_$BLOOD_TABLE ON CONFLICT DO NOTHING;";
			$COMMAND -c "DROP TABLE tmp_$BLOOD_TABLE;";

		;;
		* ) ;;
	esac
}

import_sugar() {
  _ENGINE=$1
  _FILE=$2

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

###################################################################
# synchronize local sqlite database with postgresql or vice versa #
###################################################################
sync() {
	_SOURCE=$(echo "$OPTION_SYNC" | awk -F ':' '{print $1}');
	_DESTINATION=$(echo "$OPTION_SYNC" | awk -F ':' '{print $2}');

	log "Syncing $_SOURCE to $_DESTINATION";

	case $_SOURCE in
		"sqlite" )
			TMP_FILE=$(mktemp -q)
			if [ ! -f "$TMP_FILE" ]; then
    		log "$0: Can't create temp file, bye..."
    		exit 1
			fi

			$SQLITE -list -separator ',' "$DATABASE_NAME.db" "SELECT datetime, systolic, diastolic, pulse, comment FROM $BLOOD_TABLE;" > "$TMP_FILE";

			import_blood "$_DESTINATION" "$TMP_FILE";

      $SQLITE -list -separator ',' "$DATABASE_NAME.db" "SELECT datetime, sugar, comment FROM $SUGAR_TABLE;" > "$TMP_FILE";

      import_sugar "$_DESTINATION" "$TMP_FILE";
			
			rm "$TMP_FILE";
		;;
		"pgsql" )
			log "Feature not implemented yet, only sqlite:pgsql is supported";
		;;
		* ) ;;
	esac

}


######################################################################################
# pwd
#ls -al blood.properties
BLOOD_PROPERTIES=blood.properties

source $BLOOD_PROPERTIES

if [ $# -eq 0 ]; then
	helpme
fi

echo "Using: $BLOOD_PROPERTIES";

while true; do
	case "$1" in
    -d | --debug ) DEBUG="true"; shift 2 ;;
		-D | --dbname ) DATABASE_NAME=$2; shift 2 ;;
		-e | --engine ) DB_ENGINE=$2; shift 2 ;;
		-h | --help ) helpme; shift ;;
		-H | --host ) DATABASE_HOST=$2; shift 2 ;;
		-i | --initialize ) INIT_FILENAME=$2; shift 2 ;;
    -p | --pressure ) OPTION_PRESSURE=$2; shift 2 ;;
		-P | --import-pressure ) IMPORT_BLOOD=$2; shift 2 ;;
		-q | --query ) OPTION_QUERY=$2; shift 2 ;;
    -s | --sugar ) OPTION_SUGAR=$2; shift 2 ;;
    -S | --import-sugar ) IMPORT_SUGAR=$s; shift 2 ;;
		-X | --sync ) OPTION_SYNC=$2; shift 2 ;;
		-U | --user ) USER=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

if [ "$INIT_FILENAME" != "" ]; then
	init "$INIT_FILENAME";
fi

if [ "$IMPORT_BLOOD" != "" ]; then
	import_blood "$DB_ENGINE" "$IMPORT_BLOOD";
fi

if [ "$IMPORT_SUGAR" != "" ]; then
	import_sugar "$DB_ENGINE" "$IMPORT_SUGAR";
fi

if [ "$OPTION_PRESSURE" != "" ]; then
	add "$OPTION_PRESSURE";
fi

if [ "$OPTION_SUGAR" ]; then
  sugar "$OPTION_SUGAR";
fi

if [ "$OPTION_SYNC" != "" ]; then
	sync "$OPTION_SYNC";
fi

if [ "$OPTION_QUERY" != "" ]; then
	query "$OPTION_QUERY";
fi

