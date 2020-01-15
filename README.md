# Record public transit high-frequency positioning data

See [Digitransit HFP documentation](https://digitransit.fi/en/developers/apis/4-realtime-api/vehicle-positions/).

This is a tool for recording HFP v2 feed for later use.

## Usage

**TODO:** set HFPV2_ROOTDIR, crontab installation, jobs.txt

- *[db-server](db-server)* is a PostgreSQL database with [TimescaleDB](https://docs.timescale.com/latest/main) extension for storing certain aspects of the HFP data, such as vehicle position events, or traffic light priority events.
Install PostgreSQL and TimescaleDB on the server and run SQL scripts in [db-server/init](db-server/init), or run the db-server in Docker.
  - **TODO:** DB schemata covering all types of HFP events.
  Currently, only some of them are supported.
- *[subscriber](subscriber)*: `subscribe.py` subscribes to an HFP topic `--topic` for a given amount `--duration` of seconds and saves the data of given payload fields to a csv file.
Run this preferably as a cronjob, and give a few more seconds than the job interval is, so you get overlapping rather than missing data.
Run `python subscribe.py --help` for more details.
  - **TODO:** check / remove docker stuff, test and document running from crontab
- **TODO:** *csv to database* routine takes all the csv files in `data/raw/` that are not opened by the subscription process, copies their contents into the database, and either compresses the raw csv files to `data/gz/` or simply deletes them.
Results, such as number of lines read vs. copied to database per raw file, are reported into `data/logs/csv_to_db_[%Y%m%d].log` (one log file per day), and sent to Slack.
Run this e.g. once a day.
The database schema must comply with the structure of the csv data collected, of course.
- **TODO:** *prune files* deletes files older than `$1` days (by modification time) from directory `$2`, reports the deleted files to `data/logs/prune_files_[%Y%m%d].log` (one log file per day), and sends the number of files deleted to Slack.
Size of the directory on disk is reported too, before and after the deletions.
Run this once a day for each directory you want.
- **TODO:** *drop db chunks* removes database Timescale "chunks" (partitions) for timestamps older than `$1` days.
Table sizes on disk are reported as well, before and after dropping the chunks.
- **TODO:** system and network load monitoring

## Parameters / environment variables

Must be globally available for the user running the above processes:

- `HFPV2_PGPORT`, `HFPV2_PGUSER`, `HFPV2_PGDB`: parameters for Postgres connection
- `HFPV2_PGPASSWORD`: Postgres password of the above user, used as `PGPASSWORD` for `psql`
- **TODO:** OR just configure the user's `.pgpass`?
- `HFPV2_ROOTDIR`: full path of the `hfplogger` project directory.
`data/` as well as script locations are relative to this.
- `HFPV2_CSV_KEEP_GZ`: set this to any value, e.g. `true`, to always keep and compress raw csv files when running *csv to database* job

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
