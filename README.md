# sphinxsearch-docker-image

[![Docker build](https://github.com/michal-izewski/sphinxsearch/actions/workflows/docker-build.yml/badge.svg)](https://github.com/michal-izewski/sphinxsearch/actions/workflows/docker-build.yml)

Docker image for **Sphinx 2.2.11** on CentOS 7.

Sphinx 2.2 and CentOS 7 are both end-of-life and unmaintained upstream. This
image is kept building and reasonably patched (pinned checksums on every
downloaded package, current CentOS/EPEL archive mirrors) but the underlying
software is not receiving security fixes anymore. Pinned here deliberately
for an existing production deployment — not a starting point for a new one.

## Quick start

```yaml
services:
  sphinxsearch:
    image: michalizewski/sphinxsearch-2.2
    container_name: sphinxsearch-2.2
    restart: always
    ports:
      - 127.0.0.1:9306:9306
      - 127.0.0.1:9312:9312
    volumes:
      - /etc/docker/sphinxsearch/etc:/etc/sphinx
      - /etc/docker/sphinxsearch/cron:/var/spool/cron
      - /etc/docker/sphinxsearch/data:/var/lib/sphinx
      - /etc/docker/sphinxsearch/log:/var/log/sphinx
```

The image ships with no `sphinx.conf` — `/etc/sphinx` is wiped at build time
and declared as a volume, so you must bind-mount your own config into it
before the container will do anything useful. See
[`data/conf/sphinx.conf`](data/conf/sphinx.conf) for an example (values in
it are placeholders, not real credentials).

## Ports

| Port | Purpose |
|------|---------|
| 9312 | Sphinx native (`searchd`) protocol |
| 9306 | SphinxQL / MySQL wire protocol (`mysql41`) |
| 873  | rsync daemon, only listens if `RSYNC=YES` |

## Volumes

| Path | Contents |
|------|----------|
| `/etc/sphinx` | `sphinx.conf` and any files it includes |
| `/var/lib/sphinx` | index data, binlogs, RT indexes |
| `/var/log/sphinx` | `searchd`/`indexer`/cron logs |
| `/var/spool/cron` | the `sphinx` user's crontab |

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `RSYNC` | `NO` | set to `YES` to start an rsync daemon serving `RSYNC_VOLUME` |
| `RSYNC_VOLUME` | `/var/lib/sphinx` | path the rsync daemon exports |
| `RSYNC_READONLY` | `yes` | rsync daemon `read only` setting |
| `RSYNC_OWNER` / `RSYNC_GROUP` | `sphinx` | rsync daemon `uid`/`gid` |
| `RSYNC_ALLOW` | `192.168.0.0/16 172.16.0.0/12` | rsync `hosts allow` |
| `HOST_IP` | unset | if set, added to `/etc/hosts` pointing at the container's default gateway (useful when `sphinx.conf` needs to reach a service on the Docker host) |
| `SPHINX_HOST` | `127.0.0.1` | host the `console` command connects to |
| `SPHINX_PORT` | `9306` | port the `console` command connects to |

## Commands

The entrypoint dispatches on the first argument:

```sh
docker run ... michalizewski/sphinxsearch-2.2 <command> [args]
```

| Command | Behaviour |
|---------|-----------|
| `sphinx` | long-running mode: starts cron, then `searchd` in the foreground. If invoked as `sphinx indexer [indexes]` (default `--all`), also runs the indexer once first — guarded by a marker file, so a container restart won't reindex again |
| `indexer [indexes]` | one-off `indexer --rotate`, default `--all`, then exits |
| `crontab` | opens the `sphinx` user's crontab in `vim` for editing |
| `console` | opens a `mysql` client against `SPHINX_HOST:SPHINX_PORT` (SphinxQL) |
| `editconfig` | opens `/etc/sphinx/sphinx.conf` in `vim` |
| `log` | `tail -f` on everything under `/var/log/sphinx` |
| anything else | executed as-is (`exec "$@"`) |

`CMD` defaults to `sphinx indexer`, i.e. running the image with no arguments
reindexes everything once and then starts `searchd`.

## Bundled dictionaries

Sphinx's `ru`, `en` and `de` lemmatizer dictionaries are baked into the
image under `/var/lib/sphinx/_dict/`.
