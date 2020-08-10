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
EXT_BACKUP_FILE="_gitlab_backup.tar"

BACKUP_FILE=$(get_most_recent_file "${BACKUP_DIR}/*$1*_gitlab*")
SECRETS_BACKUP_FILE=$(get_most_recent_file "${BACKUP_DIR}/*$1*_secrets*")

echo "Use ${BACKUP_DIR}/${BACKUP_FILE} to backup gitlab"
echo "Use ${BACKUP_DIR}/${SECRETS_BACKUP_FILE} to backup secrets"

exec_cmd "docker exec ${CONTAINER_NAME} mkdir -p ${CONTAINER_BACKUP_DIR}"
exec_cmd "docker cp ${BACKUP_DIR}/${BACKUP_FILE} ${CONTAINER_NAME}:${CONTAINER_BACKUP_DIR}/"
exec_cmd "docker exec ${CONTAINER_NAME} chown git:git ${CONTAINER_BACKUP_DIR}/${BACKUP_FILE}"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-ctl stop unicorn"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-ctl stop sidekiq"
exec_cmd "docker exec -it ${CONTAINER_NAME} gitlab-rake gitlab:backup:restore BACKUP=$(echo ${BACKUP_FILE} | sed -e s/${EXT_BACKUP_FILE}//g) force=yes --trace"
exec_cmd "docker cp ${BACKUP_DIR}/${SECRETS_BACKUP_FILE} ${CONTAINER_NAME}:${CONTAINER_BACKUP_DIR}/"
exec_cmd "docker exec ${CONTAINER_NAME} chown -R registry:git /var/opt/gitlab/gitlab-rails/shared/registry"
exec_cmd "docker exec ${CONTAINER_NAME} tar xzf ${CONTAINER_BACKUP_DIR}/${SECRETS_BACKUP_FILE}"
exec_cmd "docker exec ${CONTAINER_NAME} gitlab-ctl restart"
exec_cmd "docker exec ${CONTAINER_NAME} sh -c \"rm -rf ${CONTAINER_BACKUP_DIR}/*\""

echo "Restore with ${BACKUP_DIR}/${BACKUP_FILE} completed"