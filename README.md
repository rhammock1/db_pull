# POSTGRESQL DATABASE PULL

This script will run as a cron job, 6:45am every Monday. Had to include the `PATH` variable so that cron would recognize the `psql` commands. Cron will also mail you the output of the task which is used to double check for any errors. Run `mail` in terminal to view mail

```
PATH="/usr/local/bin:/usr/bin:/bin:/Applications/Postgres.app/Contents/Versions/latest/bin"
45 6 * * 1 bash $HOME/db_pull/db_pull.sh <path-to-pg-pull-script> --force
```

Included is a test script which will prepend a `#` to each line containing `# FINDME`
then run the script without triggering any major commands

## Example Usage

``` bash
bash db_pull.sh $HOME/project/bin/pg_pull --force
```

No arguments needed
``` bash
bash test_pull.sh
```

## Arguments
### First
* `DIR`
  * File path to the script that actually pulls the new database

### Second
* `--force`
  * skips all prompts and forces script to run all commands
  * this script does drop and create new databases. Use this flag carefully
