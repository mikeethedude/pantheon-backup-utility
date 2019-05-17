#!/usr/bin/env bash


############################################
# Pantheon Backup Utility (Lando Edition)
# mgoulding 5/15/19
#
# There really isn't any use for this outside of Pantheon
############################################

# Setting variables from arguments and other necessary items
SITE=$1
ENV=$2
TYPE=$3

# Running this script from the private/scripts directory
cd "${0%/*}"
BACKUP_DIR="../../reference"

# Creating backup of type on the Pantheon environment
create_backup() {

  CREATE_BACKUP="$(lando terminus backup:create ${SITE}.${ENV})"

  echo "$CREATE_BACKUP"
}

# Cleaning up directory on clean exit.
cleanup_dir() {
DELETE="$(rm -rf ${BACKUP_DIR}/* 2>&-)"

echo "Cleaning up backup directory ..."
echo "$DELETE"

}

db_backup() {

echo "Getting latest database backup for ${ENV}.${SITE}"

# Getting backup file
BACKUP="$(lando terminus backup:get ${SITE}.${ENV} --element=db --to=${BACKUP_DIR}/db.sql.gz)"
echo "$BACKUP"

wait $!

# Checking to see if we returned successful with a backup. Otherwise exiting.
if [ $? != 0 ]
then

echo "Pantheon backup failed. Please check displayed error and try again"
exit
fi

# Importing db
echo "Importing DB Backup..."
IMPORT="$(lando db-import ${BACKUP_DIR}/db.sql.gz)"
echo "$IMPORT"

wait $!

echo "Database Backup Complete!"

cleanup_dir
}

file_backup() {

  echo "Getting latest file backup for ${ENV}-${SITE}"
  echo "Sit tight. This one can take some time to get a response ..."

  # Getting backup file
  echo "Getting backup for @pantheon.${SITE}.${ENV}:%files"
  BACKUP="$(lando terminus backup:get ${SITE}.${ENV} --element=files --to=${BACKUP_DIR}/files.tar.gz)"
  echo "$BACKUP"

  wait $!

  # Checking to see if we returned successful with a backup. Otherwise exiting.
  if [ $? != 0 ]
  then

  echo "Pantheon backup failed. Please check displayed error and try again"
  exit
  fi

  EXTRACTED=$(tar -xzf ${BACKUP_DIR}/files.tar.gz -C ../../sites/default/files --strip 1)
  echo "$EXTRACTED"

  wait $!

  echo "File backup complete!"

  cleanup_dir
}

# Testing to make sure we have the first two params before we continue.
if [ -n "$SITE" ] && [ -n "$ENV" ]
then

echo "Would you like to create a new backup for this site?(y/n)"
read -n 1 create

if [ "$create" == "y" ]; then
echo -e "\nCreating backup..."
echo "This is going to take a few minutes."
create_backup
wait $!
fi

wait $!

case $TYPE in
"db" )
db_backup

exit
;;
"files" )
file_backup

exit
;;
"all"|"" )
db_backup

$!

file_backup

exit
;;
esac

# Required parameters missing. Giving brief explanation of usage
else
echo "This command expects an environment and optional type parameters to work properly."
echo "Example - pbackup env1 db or pbackup env1 create"
exit 1
fi

# Handling the script being exited before completion.
trap cleanup_dir SIGHUP SIGINT SIGTERM
