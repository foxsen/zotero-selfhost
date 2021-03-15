#!/bin/sh

MYSQL="mysql -h mysql -P 3306 -u root -pzotero"

echo "SELECT * FROM users;" | $MYSQL zotero_master
