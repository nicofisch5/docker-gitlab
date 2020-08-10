# docker-gitlab

This repository contains a dockerized [gitlab](https://about.gitlab.com/) server instance.

## Requirements

This project uses [docker](https://www.docker.com/what-docker) and
[docker-compose](https://docs.docker.com/compose/overview/) to simplify
dependencies and deployment.

Note: Tested on Ubuntu 20.04

### Tested versions

- [docker](https://docs.docker.com/install) (Tested: v19.03.8)
- [docker-compose](https://docs.docker.com/compose/install) (Tested: v1.25.0)

## Configuration

### Traefik

This project is working with Traefik.

### Env variables

In order to copy the default environment variables and set your local configuration, copy the .env.example file

```bash
cp .env.example .env
```
## Hostname

Make sure to add the hostnames configured in `.env` file to you `/etc/hosts` file:

```bash
127.0.0.1 gitlab.devl # check value in .env
```

## Installation

### Gitlab

Simply run the docker-compose command below:

```bash
docker-compose up -d
```

Then, navigate to https://gitlab.devl in your favorite browser.

The installation process can take a while, look container logs (when displaying logs about `/var/log/gitlab/gitlab-rails/production_json.log` it's finish).

Or you can fetch the health-check with this command :
```
docker-compose exec gitlab-server curl -s -o /dev/null -w "%{http_code}" http://localhost/-/health
```

## Tools

### Backup

#### Create backup

This command will create a backup of gitlab but will exclude registry data:

``
$ docker exec -it gitlab-server gitlab-rake gitlab:backup:create SKIP="registry"
``

This command will generate a tar in "/var/opt/gitlab/backups" in docker volume "gitlab-server-var".

## Backup & Restore

### Backup

To do a full backup, simply run the following script:

```bash
./bin/backup.sh
```

This script will
* stop the containers
* do the backup
* copy the file in the `backup` folder (inside the root project directory)
* re-run the containers

### Restore

To do a full restore, simply run the following script:

```bash
./bin/restore.sh [{{ backup_timestamp }}]
```

Note: You can optionally pass the desired file timestamp (without the `backup` folder path).
If not present, it will restore the last backup present in the `backup` folder.

This script will
* stop the containers
* do the restore
* re-run the containers