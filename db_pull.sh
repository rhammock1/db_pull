#!/bin/bash

# TODO
# refactor code to increase reusability

DIR=$1
DB_NAME=""
PREV_DB=`date -v-7d +%m_%d_%y` # date formatted to match last weeks database name
# TEMPLATES=('node_env_1' 'node_env_2' 'node_env_3') three of these is memory expensive ~40gb each
FORCE=""
echo $(date)

if [[ $2 == --force ]]; then
  echo "Forcing script execution"
  FORCE="y"
fi

getAllNames() {
  psql -lt | cut -d \| -f 1
}

dropAllPrevDB() {
  echo "Dropping week of $1 databases: "
  dropIfDBExists "node_$1" # drop the database used as a template
  getAllNames | grep 'node_env' | while read line ; # drop all database created from template
    do echo "$line" ;
    dropdb $line ;  # FINDME - comment out for testing
    done
}

dropIfDBExists() {
  # check if db already exists
  if [[ `getAllNames | grep -w $1` ]]; then
    if [[ -z $FORCE ]]; then
      read -p "Database already exists. Do you want to drop the old database? ('y' to continue) " PROMPT
      if [ ! "$PROMPT" = "y" ] ; then
        echo "Exiting... "
        exit
      fi
    fi
    echo "Dropping $1 database... "
    dropdb $1 # FINDME - comment out for testing
  fi
}

dropIfTooMany() {
  # check if any db need to be dropped to make room in memory
  COUNT_DB=`getAllNames | grep -c -e '[A-Za-z0-9]'`
  if [[ $COUNT_DB -ge 9 ]]; then # counts the number of non empty lines and checks if >= 9
    # can prolly have more than 9, but it seems to be a good limit
    echo "There are $COUNT_DB databases already created. Getting ready to drop the oldest..."
    DB_DROP=`getAllNames | awk 'FNR <= 1'` # gets the first db in list
    if [[ -z $FORCE ]]; then
      read -p "About to drop $DB_DROP database. Do you want to drop this database? ('y' to continue) " PROMPT
      if [ ! "$PROMPT" = "y" ] ; then
        echo "Exiting... "
        exit
      fi
    fi
    echo "Dropping $DB_DROP database... "
    dropdb $DB_DROP # FINDME - comment out for testing
  fi
}

createNew() {
  dropIfTooMany

  if [[ $2 ]]; then # if 2nd argument, then use 1st as template
    dropIfDBExists $2
    echo "Creating new database named $2 with template $1"
    createdb -T $1 $2 # FINDME - comment out for testing
  else
    dropIfDBExists $1
    echo "Creating new database with name: $1"
    createdb $1 # FINDME - comment out for testing
  fi
}

echo "Getting ready... "
if [ -z $FORCE ]; then
  read -p "New database name? " DB_NAME
fi

if [ -z "$DB_NAME" ] ; then
  echo "Creating database name based on date of $(date +%m_%d_%y)"
  DB_NAME="node_$(date +%m_%d_%y)" # formats new name as node_MM_DD_YY
fi

dropAllPrevDB $PREV_DB

createNew $DB_NAME

echo "Executing command -> bash $DIR postgres://localhost/$DB_NAME --most --force"
bash $DIR postgres://localhost/$DB_NAME --most --force # FINDME - comment out for testing

echo -e "\n\n\n  PG PULL is complete \n\n\n"
echo "Clearing Production payment credentials from new db"

# clear prod payment credientials from the new db
psql -d $DB_NAME -f $HOME/clear_prod_payment.sql # FINDME - comment out for testing

# create new databases with template
createNew $DB_NAME 'node_env_1'

# Don't delete this until the end just in case it's needed during the pg_pull
dropIfDBExists 'node_ice'

# In Case of Emergency
createNew $DB_NAME 'node_ice'

# Text me to tell me everything is complete
osascript -e "tell application \"Messages\" to send \"Database pull complete, Boss.\nIt's all ready for ya!\" to buddy \"$PHONE\""
