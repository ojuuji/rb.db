# rb.db ![build status](https://github.com/ojuuji/rb.db/actions/workflows/build-db.yml/badge.svg)

Documentation is best read on GitHub Pages: [https://ojuuji.github.io/rb.db/](https://ojuuji.github.io/rb.db/)

## How to Build

The easiest way is to fork the repository and build using GitHub Actions.

After you forked repository, go to `Actions` tab → select `build` workflow → click `Run workflow` split button → click `Run workflow` button. The build workflow will start, and once it completes, the database will be published in the Releases section of the repository.

If you want to build on a schedule, first enable scheduled workflow (they are disabled by default in forks). Go to `Actions` tab → select `schedule` workflow → click `Enable workflow` button. It is also recommended to update [cron expression](https://github.com/ojuuji/rb.db/blob/master/.github/workflows/schedule.yml#L5) in this case (set different time).

### Local Build

To build `rb.db` locally you need Python (tested on 3.12), SQLite3 (3.37 or above), and Bash (on Windows you can use Git Bash). Run these commands in Bash shell:

```sh
git clone https://github.com/ojuuji/rb.db.git
cd rb.db
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
./build.sh
```

Or run `./build.sh -rbonly` if you want to generate `rb.db` containing only [Rebrickable tables](https://ojuuji.github.io/rb.db/#rebrickable-tables) without [custom tables](https://ojuuji.github.io/rb.db/#custom-tables).

On Windows you might have better luck with `py -m venv .venv` command instead of `python -m venv .venv`. Also use `source .venv/Scripts/activate` instead of `source .venv/bin/activate`.

If `build.sh` complains about missing `sqlite3` executable, an archive containing prebuilt `sqlite3.exe` for Windows can be downloaded from [SQLite Download Page](https://www.sqlite.org/download.html). On Linux this is usually solved by installing `sqlite` package (via `dnf install sqlite` or equivalent for other package managers).

After the script completes, you will find the generated `rb.db` file in the `data` directory.
