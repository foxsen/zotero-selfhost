#!/bin/bash

SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")/..

cd $BASEDIR

patch_dataserver=1
patch_zotero_client=1
patch_web_library=1

if [ $patch_dataserver == 1 ] ; then
  cd src/server/dataserver
  for p in ${BASEDIR}/src/patches/dataserver/*.patch; do
    echo $p
    patch -p 1 < $p
  done
  cd ./include && tar -xzvf ${BASEDIR}/src/patches/dataserver/Zend.tar.gz
  cd $BASEDIR
fi

if [ $patch_zotero_client == 1 ] ; then
  cd src/client/zotero-client
  for p in ${BASEDIR}/src/patches/zotero-client/*.patch; do
    echo $p
    patch -p 1 < $p
  done
  cd $BASEDIR
fi

if [ $patch_web_library == 1 ] ; then
  cd src/server/web-library
  for p in ${BASEDIR}/src/patches/web-library/*.patch; do
    echo $p
    patch -p 1 < $p
  done
  cd $BASEDIR
fi
