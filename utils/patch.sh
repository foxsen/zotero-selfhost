#!/bin/bash

patch_dataserver=0
patch_zotero_client=1
patch_web_library=1

if [ $patch_dataserver == 1 ] ; then
  cd server/dataserver
  for p in ../../patches/dataserver/*.patch; do
    echo $p
    patch -p 1 < $p
  done
  cd ./include && tar -xzvf ../../../patches/dataserver/Zend.tar.gz
  cd ../../..
fi

if [ $patch_zotero_client == 1 ] ; then
  cd client/zotero-client
  for p in ../../patches/zotero-client/*.patch; do
    echo $p
    patch -p 1 < $p
  done
  cd ../..
fi

if [ $patch_web_library == 1 ] ; then
  cd client/web-library
  for p in ../../patches/web-library/*.patch; do
    echo $p
    patch -p 1 < $p
  done
  cd ../..
fi
