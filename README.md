# DATABASE PULL

This script will run as a cron job, 6:45am every Monday. 

Included is a test script which will prepend a `#` to each line containing `# FINDME`
then run the script without triggering any major commands. Some echo may run more then once when they shouldn't because the drop database commands aren't running.

## Example Usage

``` bash
bash db_pull.sh $HOME/project/bin/pg_pull --force
```

No arguments needed
``` bash
bash test_pull.sh
```

## Command Line Arguments
### First
* `DIR`
  * File path to the script that actually pulls the new database

### Second
* `--force`
  * skips all prompts and forces script to run all commands
  * this script does drop and create new databases. Use this flag carefully
