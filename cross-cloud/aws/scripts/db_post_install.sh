#!/bin/bash

# Everything that needs to happen in order for the db to allow replication to Azure.
# This will
# 1)  Create the REPLICATION role for login using the command-line argument
# for the password
# 2)  Add an entry to hba.conf to allow replication login from the Azure
# subnet 10.0.1.0/24
# 3)  Add config entries to postgresql.conf to listen for connections

# Set "trap" on ERR to be inherited by functions
set -o errtrace

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function
SOURCEFILE=$0
trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  # Ensure tracing is disabled from possibly being set elsewhere in the script
  set +x
  echo "====== ERROR or Interruption, [`date`], ${SOURCEFILE}, line ${1}, exit code ${2}"
  exit ${2}
}

# Determine if running as root or not.  If not, use SUDO
SUDO=''
if [ "$EUID" != "0" ]; then
  SUDO='sudo'
fi

logger()
{
  echo "====== [`date`], ${SOURCEFILE}, $*"
}

usage()
{
  echo
  echo "usage: $0 --replpassword PSQL-REPLICATION-ROLE-PASSWD"
  echo
  echo "    --replpassword:  password of the PostgreSQL replication role this script creates"
  echo
}

REPLPASSWORD=""

logger "STARTING, command line params [$@]"

# If no command-line arguements, just print the usage and exit.
if [ "$1" == "" ]; then
  usage
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    --replpassword )
      shift
      REPLPASSWORD="$1"
      ;;
    -h | -? | --help )
      usage
      exit
      ;;
    * )
      usage
      exit 1
      ;;
  esac
  shift
done

if [ "$REPLPASSWORD" == "" ]; then
	# We need the password from the command line
	echo "ERROR:  Required --replpassword command line argument missing"
	usage
	exit 1
fi

# Create the replication role on the master as user "postgres"
echo "Create the replication role on the master"
su postgres -l -c "psql -c \"CREATE ROLE replication with REPLICATION PASSWORD '$REPLPASSWORD' LOGIN;\""

# Allow the replication role to authenticate to the server from the subnet where the
# PostgreSQL standyby server is located
echo "Allow replication role login from specific subnet in hba.conf"
echo 'host    replication     replication     10.0.1.0/24             md5' | \
  $SUDO tee -a /etc/postgresql/9.3/main/pg_hba.conf

# Setup streaming replication on the master.
# uncomment and set some config variables
echo "Listen for PostgreSQL connections on all local interfaces and set WAL params in postgresql.conf"
echo "
listen_addresses = '*'
wal_level = hot_standby
checkpoint_segments = 16
max_wal_senders = 5
wal_keep_segments = 32" | $SUDO tee -a /etc/postgresql/9.3/main/postgresql.conf

#restart the POSTGRESQL server
echo "Restart PostgreSQL"
$SUDO /etc/init.d/postgresql restart

logger "COMPLETED"
