#!/usr/bin/env bash

set -e

exec_cmd () {
    echo Exec : $@
    sh -c "$@"
}

get_most_recent_file () {
    ls -t $1 | head -n1 | xargs -n1 basename
}

PROJECT_PATH=$(cd $(dirname $(dirname $0)) && pwd)
CONTAINER_NAME=gitlab-server
CONTAINER_BACKUP_DIR=/var/opt/gitlab/backups
BACKUP_DIR=${PROJECT_PATH}/backup
SECRETS_BACKUP_PATH=/etc/gitlab/gitlab-secrets.json

exec_cmd "mkdir -p ${BACKUP_DIR}"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-ctl stop unicorn"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-ctl stop sidekiq"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-rake gitlab:backup:create SKIP=registry,artifacts"
exec_cmd "docker cp ${CONTAINER_NAME}:${CONTAINER_BACKUP_DIR}/. ${BACKUP_DIR}/"
LAST_TIMESTAMP="$(cut -d'_' -f1 <<<"$(get_most_recent_file "${BACKUP_DIR}/")")"
SECRETS_FULL_BACKUP_NAME=${LAST_TIMESTAMP}_$(date +"%Y_%m_%d")_secrets_backup.tar
exec_cmd "docker exec ${CONTAINER_NAME} tar czf ${CONTAINER_BACKUP_DIR}/${SECRETS_FULL_BACKUP_NAME} ${SECRETS_BACKUP_PATH}"
exec_cmd "docker cp ${CONTAINER_NAME}:${CONTAINER_BACKUP_DIR}/${SECRETS_FULL_BACKUP_NAME} ${BACKUP_DIR}/"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-ctl start"
exec_cmd "docker exec ${CONTAINER_NAME} sh -c \"rm -rf ${CONTAINER_BACKUP_DIR}/*\""

exec_cmd "find ${BACKUP_DIR} -type f -mtime +15 -name '*' -execdir rm -- '{}' \;"

echo "Backup finished at $(date +"%H-%M_%Y_%m_%d")."
