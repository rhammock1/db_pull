#!/bin/bash
# commands may be commented out for testing. Dont forget to remove them!

# TODO 
# refactor code to increase reusability

DIR=$1
DB_NAME=""
PREV_DB=`date -v-7d +%m_%d_%y` # date formatted to match last weeks database name
TEMPLATES=('node_env_1' 'node_env_2' 'node_env_3')
FORCE=""

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
  getAllNames | grep 'node_env' | while read line ; do echo "$line" ; dropdb $line ; done # drop all database created from template
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
    dropdb $1
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
    dropdb $DB_DROP 
  fi
}

createNew() {
  dropIfTooMany

  if [[ $2 ]]; then # if 2nd argument, then use 1st as template
    dropIfDBExists $2
    echo "Creating new database named $2 with template $1"
    createdb -T $1 $2
  else
    dropIfDBExists $1
    echo "Creating new database with name: $1"
    createdb $1
  fi
}

echo "Getting ready... "
if [ -z $FORCE ]; then
  read -p "New database name? " DB_NAME
fi

if [ -z "$DB_NAME" ] ; then
  echo "Creating database name based on date"
  DB_NAME="node_$(date +%m_%d_%y)" # formats new name as node_MM_DD_YY
fi

dropAllPrevDB $PREV_DB

createNew $DB_NAME

echo "Executing command -> bash $DIR postgres://localhost/$DB_NAME --most --force"
bash $DIR postgres://localhost/$DB_NAME --most --force

echo -e "\n\n\n PG PULL is complete \n\n\n"
echo "Clearing Production payment credentials from new db"

# clear prod payment credientials from the new db
psql -d $DB_NAME -f $HOME/clear_prod_payment.sql

for str in ${TEMPLATES[@]}; do
  createNew $DB_NAME $str # create new databases with template
done
