# DATABASE PULL

This script will run as a cron job, 6:45am every Monday. 
Output of cron job can be output to log file `cron.log`. Make sure to create the file first

## Example Usage

``` bash
./db_pull.sh $HOME/project/bin/pg_pull --force
```

## Command Line Arguments
### First
* `DIR`
  * File path to the script that actually pulls the new database

### Second
* `--force`
  * skips all prompts and forces script to run all commands
  * this script does drop and create new databases. Use this flag carefully
