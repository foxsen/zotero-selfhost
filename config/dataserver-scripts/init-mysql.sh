#!/bin/sh

MYSQL="mysql -h mysql -P 3306 -u root -pzotero"

echo "SET @@global.innodb_large_prefix = 1;" | $MYSQL
#echo "SET GLOBAL sql_mode='' " | $MYSQL
echo "set global sql_mode = '' " | $MYSQL
echo "DROP DATABASE IF EXISTS zotero_master" | $MYSQL
echo "DROP DATABASE IF EXISTS zotero_shard_1" | $MYSQL
echo "DROP DATABASE IF EXISTS zotero_shard_2" | $MYSQL
echo "DROP DATABASE IF EXISTS zotero_ids" | $MYSQL
echo "DROP DATABASE IF EXISTS zotero_www" | $MYSQL

echo "CREATE DATABASE zotero_master" | $MYSQL
echo "CREATE DATABASE zotero_shard_1" | $MYSQL
echo "CREATE DATABASE zotero_shard_2" | $MYSQL
echo "CREATE DATABASE zotero_ids" | $MYSQL
echo "CREATE DATABASE zotero_www" | $MYSQL

# Load in master schema
$MYSQL zotero_master < master.sql
$MYSQL zotero_master < coredata.sql

# Set up shard info
echo "INSERT INTO shardHosts VALUES (1, 'mysql', 3306, 'up');" | $MYSQL zotero_master
echo "INSERT INTO shards VALUES (1, 1, 'zotero_shard_1', 'up', '1');" | $MYSQL zotero_master
echo "INSERT INTO shards VALUES (2, 1, 'zotero_shard_2', 'up', '1');" | $MYSQL zotero_master

# Create first group & user
echo "INSERT INTO libraries VALUES (1, 'user', CURRENT_TIMESTAMP, 0, 1)" | $MYSQL zotero_master
echo "INSERT INTO libraries VALUES (2, 'group', CURRENT_TIMESTAMP, 0, 2)" | $MYSQL zotero_master
echo "INSERT INTO users VALUES (1, 1, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" | $MYSQL zotero_master
echo "INSERT INTO groups VALUES (1, 2, 'Shared', 'shared', 'Private', 'members', 'all', 'members', '', '', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1)" | $MYSQL zotero_master
echo "INSERT INTO groupUsers VALUES (1, 1, 'owner', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" | $MYSQL zotero_master

# Load in www schema
$MYSQL zotero_www < www.sql

echo "INSERT INTO users VALUES (1, 'admin', MD5('admin'), 'normal')" | $MYSQL zotero_www
echo "INSERT INTO users_email (userID, email) VALUES (1, 'admin@zotero.org')" | $MYSQL zotero_www
echo "INSERT INTO storage_institutions (institutionID, domain, storageQuota) VALUES (1, 'zotero.org', 10000)" | $MYSQL zotero_www
echo "INSERT INTO storage_institution_email (institutionID, email) VALUES (1, 'contact@zotero.org')" | $MYSQL zotero_www


# Load in shard schema
cat shard.sql | $MYSQL zotero_shard_1
cat triggers.sql | $MYSQL zotero_shard_1
cat shard.sql | $MYSQL zotero_shard_2
cat triggers.sql | $MYSQL zotero_shard_2

echo "INSERT INTO shardLibraries VALUES (1, 'user', CURRENT_TIMESTAMP, 0)" | $MYSQL zotero_shard_1
echo "INSERT INTO shardLibraries VALUES (2, 'group', CURRENT_TIMESTAMP, 0)" | $MYSQL zotero_shard_2

# Load in schema on id servers
$MYSQL zotero_ids < ids.sql

