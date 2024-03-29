#!/bin/bash

# TODO
# refactor code to increase reusability
# Add check to make sure psql is running 

# get the directory of this script
__dir="$(cd "$(dirname "$0")" && pwd)" 
echo $__dir

# clear previous log contents
> $__dir/logs/pull.log

# Output all standard output to the log file
exec 2> $__dir/logs/pull.log

REPO_PATH=""
DB_NAME=""
FORCE=""
INTEGRATION=false
CLEAR_BRANCH_DATABASES=false
echo $(date)

while test $# -gt 0
do
  case "$1" in
    --repo | -r) REPO_PATH=$2 && echo "Using repo path: $REPO_PATH"
      ;;
    --integration | -i) INTEGRATION=true && echo "Going to setup new DB based on contents of 'sql/integration_setup.sql'"
      ;;
    --force | -f) FORCE=true && echo "Forcing script execution"
      ;;
    --clear-branch-db | -c) CLEAR_BRANCH_DATABASES=true && echo "Going to clear all databases that match git branch names"
      ;;
    --help | -h) echo "Pending..."
      exit 0
      ;;
    --*) echo "No such option: $1"
      exit 0
      ;;
  esac
  shift
done

hasActiveConnections() {
  if [[ $(psql -t -f sql/check_active_connections.sql) ]] ; then
    echo "There is a database connection still open. Please close it before running this script."
    exit 1
  fi
}

getAllNames() {
  psql -lt | cut -d \| -f 1
}

dropAllPrevDB() {
  echo "Dropping previously used databases: "
  # drop all databases that match the date format MM_DD_YY
  getAllNames | grep -E '(node_)\d{2}_\d{2}_\d{2}' | while read line; # drop the database used as a template
    do echo "$line" ;
    dropdb $line ; # FINDME - comment out for testing
    done

  if [ $CLEAR_BRANCH_DATABASES = true ]; then
    # get all git branch names as an array
    git_branches=($(git --git-dir=$REPO_PATH/.git branch | sed 's/* //'))
    # drop all databases that match the git branch names
    for branch in "${git_branches[@]}"
    do
      getAllNames | grep $branch | while read line ; # drop all database created from template
        do echo "$line" ;
        dropdb $line ;  # FINDME - comment out for testing
        done
    done
  fi
}

dropIfDBExists() {
  # check if db already exists
  if [ `getAllNames | grep -w $1` ]; then
    if [ -z $FORCE ]; then
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

createNew() {
  if [ $2 ]; then # if 2nd argument, then use 1st as template
    dropIfDBExists $2
    echo "Creating new database named $2 with template $1"
    createdb -T $1 $2 # FINDME - comment out for testing
  else
    dropIfDBExists $1
    echo "Creating new database with name: $1"
    createdb $1 # FINDME - comment out for testing
  fi
}

hasActiveConnections

echo "Getting ready... "
if [ -z $FORCE ]; then
  read -p "New database name? " DB_NAME
fi

if [ -z "$DB_NAME" ] ; then
  echo "Creating database name based on date of $(date +%m_%d_%y)"
  DB_NAME="node_$(date +%m_%d_%y)" # formats new name as node_MM_DD_YY
fi

dropAllPrevDB

createNew $DB_NAME

echo "Executing command -> bash $DIR postgres://localhost/$DB_NAME --most --force"
bash $REPO_PATH/bin/pg_pull_streaming postgres://localhost/$DB_NAME --most --force & # FINDME - comment out for testing
PULL_PID=$!
# wait for the pull to finish
# maybe this will help with the server hang up issue?
wait $PULL_PID

getErrorLine() {
  grep 'errors ignored on restore:' logs/pull.log
}

# read contents of logs/pull.log and find line containing "errors ignored on restore:"
# recent pulls have given 26 errors when successful
number_of_errors=$(getErrorLine | grep -o -E '[0-9]+')
echo "errors: $number_of_errors"

if [[ -z $(getErrorLine) ]]; then
  echo "Didn't find the error check line. It's likely that the pull was unsuccessful."
  echo "Not going to continue. Please check logs/pull.log"
  exit 1
elif [[ $number_of_errors -gt 30 ]]; then
  echo "There were more errors than expected."
  echo "Not going to continue trying. Please check logs/pull.log"
  exit 1
else
  echo -e "\n\n\n  PG PULL is complete \n\n\n"
fi

# Clear prod payment credientials from the new db
if [ -f "$__dir/sql/clear_prod_payment.sql" ]; then
  echo "Clearing Production payment credentials from new db"  
  psql -d $DB_NAME -f $__dir/sql/clear_prod_payment.sql # FINDME - comment out for testing
fi

# If $INTEGRATION is true, run integration_setup.sql
if [[ $INTEGRATION=true && -f "$__dir/sql/integration_setup.sql" ]]; then
  echo "Adding integration values to new db"
  psql -d $DB_NAME -f $__dir/sql/integration_setup.sql # FINDME - comment out for testing
fi

hasActiveConnections

# Don't delete this until the end just in case it's needed during the pg_pull
dropIfDBExists 'node_ice'

# In Case of Emergency
createdb 'node_ice'
DBID=`psql -t -c "select oid from pg_catalog.pg_database where datname='$DB_NAME'" | xargs`

if [ -z "$TEMPLATE_DBOID" ]
  then
    echo "Could not locate an existing database with the name '$TEMPLATE_DBNAME'"
    exit 3
fi

NEW_DBOID=`psql -t -c "select oid from pg_catalog.pg_database where datname='node_ice'" | xargs`
PGDATA=`psql -t -c "SHOW data_directory" | xargs`
# Clear out the directory of the new database
rm -rf "$PGDATA/base/$NEW_DBOID"
# Clone the template database files into the new database directory.
cp -Rc "$PGDATA/base/$TEMPLATE_DBOID" "$PGDATA/base/$NEW_DBOID"

# Update .env.template and .env files with new template database name
sed -i '' "s/TEMPLATE_DATABASE=.*/TEMPLATE_DATABASE=$DB_NAME/g" $REPO_PATH/.env


message="Database pull complete, Boss.\nIt's all ready for ya!"
if [ -z $PHONE ]; then
  title="Database Pull Complete"
  subtitle="Database Pull"

  osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\""
else 
  # Text me to tell me everything is complete
  osascript -e "tell application \"Messages\" to send \"$message\" to buddy \"$PHONE\""
  echo "Message should have been sent to $PHONE"
fi
echo "Completed at $(date)"
