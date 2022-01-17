# DATABASE PULL

This script will run as a cron job, 6:45am every Monday. 

## Example Usage

./db_pull.sh $HOME/project/bin/pg_pull --force

## Command Line Arguments
### First --- $1
* DIR
  * File path to the script that actually pulls the new database

### Second --- $2
* --force
  * skips all prompts and forces script to run all commands
  * this script does drop and create new databases. Use this flag carefully
