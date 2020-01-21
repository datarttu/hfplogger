# Record public transit high-frequency positioning data

See [Digitransit HFP documentation](https://digitransit.fi/en/developers/apis/4-realtime-api/vehicle-positions/).

This is a tool for recording HFP v2 feed for later use.

## Usage

The tool should work on Debian-based Linux and has been tested on Ubuntu 18.04 LTS.

### Installation

Install from GitHub:

```
$ git clone https://github.com/datarttu/hfplogger.git && cd hfplogger
# From now on, assume you're inside hfplogger/ directory.
```

Ensure you have at least Python 3.7:

```
$ python --version
Python 3.7.1 # Or higher
```

Python scripts will use a virtual environment that makes them independent on the packages installed in your host machine.
Install it in the subscription script directory:

```
$ cd subscriber
$ python -m venv env
```

A directory `env` containing the environment stuff is created.
Activate the environment (you will see `(env)` in the beginning of the command line now), and install dependencies in it:

```
$ source env/bin/activate
$ (env) pip install -r requirements.txt
# To exit the environment, run:
$ (env) deactivate
$
```

To install the database, see the [db-server](db-server) README.

### Regular recording and handling of data

Determine what data you want to subscribe to, in `subscriptions.txt`.
Give the topic, fields you want to save, and duration of one subscription in seconds, separated by `;`.

Then modify the `cronfile_example.txt` to your needs.

**IMPORTANT:** match the duration with the time step you are going to use in the cron job, and add some seconds to it to account for the overhead time when the subscription starts - this way your result files will have overlapping data rather than gaps between the files.
For example, if you want to subscribe every 15 minutes, define it as `*/15` in the cron job and `903` in `subscriptions.txt`.

To get the regular jobs up and running, install a new crontab to your user (**WARNING:** this will override any existing crontab):

```
$ crontab crontab_example.txt # (or something else if you renamed the file)
# Check that you have the jobs installed:
$ crontab -l
```

To remove the cron jobs, run:

```
$ crontab -r
```

## Parameters and environment variables

If you want to override default values of environment variables used in scripts, make a file called `.env` in the hfplogger folder, and write the variables there in format `ENV_VAR='VALUE'` separated by newline.
`.env` is sourced in the beginning of each shell script.

- Database connection parameters: see [db-server](db-server)
- `HFPV2_PORT`: Defaults to 5432, you may want to use some other port e.g. with a db in a container.
- `HFPV2_ROOTDIR`: Set this to an absolute path if you wish to have `data/` somewhere else than this `hfplogger` directory.
- `HFPV2_NO_GZ`: set this to any non-empty value, e.g. `true` if you wish NOT to keep compressed versions of csv files.
- These MUST be set in `.env` to enable Slack reporting: `HFPV2_SLACK_WEBHOOK_URL`, `HFPV2_SLACK_CHANNEL`, `HFPV2_SLACK_NAME`

Note that environment variables must be globally available to the cron jobs, for example, not only in your current shell session.

## Data files

```
data
├── gz
│   │   # Compressed csv files that were already transferred to database,
│   │   # if accepted to preserve them when transferring.
│   ├── hfp_v2_journey_ongoing_ALL_tram_20200110T134322Z.csv.gz
│   └── ...
├── logs
│   │   # Logs from subscribe.py jobs.
│   ├── hfp
│   │   ├── hfp_v2_journey_ongoing_ALL_tram_20200110T134322Z.log
│   │   └── ...
│   │   # Logs from csv to database jobs.
│   ├── _csv_to_db_20200110.log
│   │   # Logs prune files jobs.
│   │   # Log entries on different directories are piped to the same file per day.
│   ├── prune_files_20200110.log
│   │   # Logs from drop database chunks jobs.
│   ├── drop_db_chunks_20200110.log
│   └── ...
└── raw
    │   # Csv files from subscribe.py jobs, not yet transferred to database.
    ├── hfp_v2_journey_ongoing_ALL_tram_20200110T134322Z.csv
    └── ...
```

Files that are opened by a running process, e.g. log and csv files by `subscribe.py`, can be detected by `lsof -a -c python +D data/` (if run from within the project root).

## TODO stuff

- **TODO:** *prune files* deletes files older than `$1` days (by modification time) from directory `$2`, reports the deleted files to `data/logs/prune_files_[%Y%m%d].log` (one log file per day), and sends the number of files deleted to Slack.
Size of the directory on disk is reported too, before and after the deletions.
Run this once a day for each directory you want.
- **TODO:** *drop db chunks* removes database Timescale "chunks" (partitions) for timestamps older than `$1` days.
Table sizes on disk are reported as well, before and after dropping the chunks.
- **TODO:** system and network load monitoring
