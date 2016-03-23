#!/bin/bash

# Everything that needs to happen in order for the Azure PostgreSQL instance to replicate from AWS
# Right now, paths are hard-coded to PostgreSQL 9.3 install paths. 

MASTERIP=""  #"10.0.1.4"
PGPASSWORD=""  #"somestrongreplicationpassword"

function usage
{
    echo
    echo "usage: $0 --masterip PSQL-MASTER-IP --replpassword PSQL-REPLICATION-ROLE-PASSWD"
    echo
    echo "    --masterip:  IP address of the PostgreSQL master DB" 
    echo "    --replpassword:  password of the PostgreSQL replication role"
    echo 
}

if [ "$1" == "" ]; then
    usage 
	exit 1 
fi

while [ "$1" != "" ]; do
    case $1 in
        --masterip )           
            shift
            MASTERIP="$1"
            ;;
        --replpassword )           
            shift
            PGPASSWORD="$1"
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

if [ "$MASTERIP" == "" ] || [ "$PGPASSWORD" == "" ]; then 
    # We need both command-line arguments in order to continue. 
	echo "ERROR:  Required command line arguments are missing"
    usage
    exit 1
fi

# shutdown the PostgreSQL server
sudo /etc/init.d/postgresql stop

# Update configuration for hot standby. 
# For a discussion on some good values for these parameters, see: 
# https://wiki.postgresql.org/wiki/Binary_Replication_Tutorial#Starting_Replication_with_only_a_Quick_Master_Restart
echo "Adding the Replicaiton and WAL settings to postgresql.conf"
echo "
wal_level = hot_standby
checkpoint_segments = 16
max_wal_senders = 5
wal_keep_segments = 32
hot_standby = on" | sudo tee -a /etc/postgresql/9.3/main/postgresql.conf
echo

# remove the current postgresql data directory on the slave
DIRTOREMOVE="/var/lib/postgresql/9.3/main"
echo "Removing directory $DIRTOREMOVE"
set -x
sudo -u postgres rm -rf $DIRTOREMOVE
set +x
echo

# restore the master db on the slave
#PGPASSWORD="somestrongreplicationpassword" 
echo "Restoring from master server ${MASTERIP}" 
set -x
sudo -u postgres pg_basebackup -h ${MASTERIP} -D /var/lib/postgresql/9.3/main -v -P -U replication --xlog-method=stream
set +x
echo

# Create a recovery.conf file on the slave in the data directory
echo "Create a recovery.conf file on the slave in the data directory with the following: " 
echo "
# Note that recovery.conf must be in $PGDATA directory.
# It should NOT be located in the same directory as postgresql.conf

# Specifies whether to start the server as a standby. In streaming replication,
# this parameter must to be set to on.
standby_mode          = 'on'

# Specifies a connection string which is used for the standby server to connect
# with the primary.
primary_conninfo      = 'host=${MASTERIP} port=5432 user=replication password=${PGPASSWORD}'

# Specifies a trigger file whose presence should cause streaming replication to
# end (i.e., failover).
trigger_file = '/var/lib/postgresql/9.3/main/failover.trigger'

# Specifies a command to load archive segments from the WAL archive. If
# wal_keep_segments is a high enough number to retain the WAL segments
# required for the standby server, this may not be necessary. But
# a large workload can cause segments to be recycled before the standby
# is fully synchronized, requiring you to start again from a new base backup.
#restore_command = 'cp /path_to/archive/%f \"%p\"'
" | sudo tee -a /var/lib/postgresql/9.3/main/recovery.conf
echo

#Restart PostgreSQL
sudo /etc/init.d/postgresql start
