#!/bin/sh

MYSQL="mysql -h mysql -P 3306 -u root -pzotero"

echo "INSERT INTO libraries VALUES (${1}, 'user', CURRENT_TIMESTAMP, 0, 1)" | $MYSQL zotero_master
echo "INSERT INTO users VALUES (${1}, ${1}, '${2}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" | $MYSQL zotero_master
echo "INSERT INTO groupUsers VALUES (1, ${1}, 'member', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" | $MYSQL zotero_master
echo "INSERT INTO users VALUES (${1}, '${2}', MD5('${3}'))" | $MYSQL zotero_www
echo "INSERT INTO users_email (userID, email) VALUES (${1}, '${4}')" | $MYSQL zotero_www
echo "INSERT INTO shardLibraries VALUES (${1}, 'user', 0, 0)" | $MYSQL zotero_shard_1

