# POSTGRESQL DATABASE PULL

~This script will run as a cron job, 5 am every Monday. Had to include the `PATH` variable so that cron would recognize the `psql` commands. Cron will also mail you the output of the task which is used to double check for any errors. Run `mail` in terminal to view mail~

Example cron task
```
PATH="/usr/local/bin:/usr/bin:/bin:/Applications/Postgres.app/Contents/Versions/latest/bin"
0 5 * * 1 bash $HOME/db_pull/db_pull.sh <path-to-pg-pull-script> --force
```

Because Apple has depreciated Cron on Mac, I have decided to change and use `Launchctl`. 
With launchctl, the message letting me know the db_pull is complete is actually sent.

The LaunchAgent won't run if your computer is asleep.
Don't forget to update Mac `System Preferences` to wake your computer at a specific time.
Computer must be plugged in to follow set wake-up time.

To run this as a Launchctl Agent, move `com.example.db_pull.plist` to `~/Library/LaunchAgents/`. This is your user's collection of LaunchAgents. In the future it may be good to move to root? <br />
<b>Make sure to update the appropriate fields first!</b> <br />
The Agent should automatically load, but if not (or if changes are made) run `launchctl unload ~/Library/LaunchAgents/com.example.db_pull.plist` then `launchctl load ~/Library/LaunchAgents/com.example.db_pull.plist`

More details on Launchctl [here](https://launchd.info/)

Included is a test script which will prepend a `#` to each line containing `# FINDME`
then run the script without triggering any major commands. Some echo may run more then once when they shouldn't because the drop database commands aren't running.


## SETUP
* Don't forget to `chmomd +x *.sh` ? (Tbh I don't know, atm, if you have to do this...)
* Create a `logs/` folder in the root of this project and touch `logs/pull.log` - This will be .gitignored
* If you'd like it to clear production payment details- create `sql/clear_prod_payment.sql`
* If working on an integration- create `sql/integration_setup.sql`

-- If running as an agent
* Update System Preferences to wake the computer at specific time
* Edit `com.example.db_pull.plist` with your specific values
* Move `com.example.db_pull.plist` to `~/Library/LaunchAgents/`.

## Example Usage

``` bash
bash db_pull.sh $HOME/project/bin/pg_pull --force --integration
```

No arguments needed
``` bash
bash test_pull.sh
```

## Arguments
### First
* `PG_PULL_DIR`
  * File path to the script that actually pulls the new database

### [Second]
* `--force`
  * skips all prompts and forces script to run all commands
  * this script does drop and create new databases. Use this flag carefully

### [Third]
* `--integration`
  * Runs sql/integration_setup.sql if it exists
  * Used if needing a large database setup for a project
