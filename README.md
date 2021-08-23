# Zotero Selfhost

Zotero Selfhost is a full packaged repository aimed to make on-premise [Zotero](https://www.zotero.org) deployment easier with the last versions of both Zotero client and server. It started from the work of Samuel Hassine: https://github.com/SamuelHassine/zotero-prime.git. Major changes include:

* Reorganize directories 
    - All source codes are put into src, client code in src/client, server code in /src/server. Modifications to the original source is maintained as patches in ./pachtes.
    - Dockerfile & docker-composer.yml are put in top level because we want to be able to copy the necessary source into container instead of mapping host direct to container volumes. This avoid polluting source directories with node_modules and other compile results.
    - some runtime configurations & scripts used by docker images are put in config/, and mapping to docker volumes by docker-composer.
    - we use some utility scripts to help patch/update the official sources.

* necessary fixes 
    - mysql upgrade to 5.7 due to the need of large key size support. utf8mb4 needs large key size, zotero-prime choose to change it into utf8 but it might lead to issues.
    - add mysql server params (set sql_mode) to deal with syntax compatible issues. e.g. allow the use of zero dates.
    - adjust some default parameters of dataserver to avoid web-library rate/concurrency limit errors.
    - use ubuntu 18.04 as default app-zotero base image. Avoid dependence on third party PPA repositories(they are often slow or even unvailable for the author). Build stream-server & tinymce-clean-serve into image instead of building them at run time. Add missing actions to get rid of some warnings. Add useful packages like vim
    - ...

## the Zotero eco-system

It is not easy to fully understand the Zotero eco-system. It is composed of many components, and each component might be implemented with a different language or technology. Used languages include javascript/python/php/c/c++/shell/html, technologies like node.js, reactive, XULRunner, mysql/apache/redis/websocket/elasticsearch/memcached/localstack/aws/phpadmin, and etc. What's more, docs are far from enough. Up to now, I have not yet seen a clear overall arichitecture description. 

Here is my current understanding of Zotero:

### Architecture

Overall Zotero is a client/server system with some server components and some client components, both servers and clients rely on some other aiding components.

The core of server part is dataserver, which provides zotero API services. Dataserver is implemented in PHP, structure data is stored in mysql database, while documents and fulltext data are stored using amazon S3 storage or webdav. Dataserver uses localstack for SNS/SQS, memcached to cached data to reduce pressure of database server, elasticsearch to support searches, redis to do request rate limit(seems to handle notifications too), and optional StatsD for statistics(I guess). 

There are two types of clients. One is the zotero client downloadable from zotero.org. It is a native executable built upon XULRunner. This client is versatile. First, it provides interfaces for us to operate(import/export/edit/search/organize etc.) on our materials and stores local data in a SQLite database(by default in ~/Zotero/). Second, it is extensible. We can run javascript code in a console(Tools->Developer->Run JavaScript) or write a plugin to interact with the client UI and operate on local data. Third, it has a builtin HTTP server to import data from connectors(browser plugin that sense data from web pages). Fourth, it provides a word processor integration API. Fiveth, it contains a lots of translators that can help to extrace contents from web pages and export them to other formats. The other one is web-library that provides browser based interface. Note: for API server, web-library is a client using its services; but for users, web-library is a server that providing web base interface for them to use zotero.

### important concepts

* connector. Zoteror connectors are some browser plugins that provide the ability to sense data from web pages. they enable us to save web data into zotero(through zotero client or directly to online zotero database).
* translator. The zotero client contains many translators, they allow Zotero to extract information from webpages, import and export items in various file formats (e.g. BibTeX, RIS, etc.), and look up items when given identifiers (e.g. DOIs or PubMed IDs). 
* library. Just like the physical library, it is used to store informations like books, articles, documents and more.
* collection/subcollection. Items in Zotero libraries can be organized with collections and tags. Collections allow hierarchical organization of items into groups and subgroups. The same item can belong to multiple collections and subcollections in your library at the same item. Collections are useful for filing items in meaningful groups (e.g., items for a particular project, from a specific source, on a specific topic, or for a particular course). You can import items directly to a specific collection or add them to collections after they are already in your library.
* tags. Tags (often called “keywords” in other contexts) allow for detailed characterization of an item. You can tag items based on their topics, methods, status, ratings, or even based on your own workflow (e.g., “to-read”). Items can have as many tags as you like, and you can filter your library (or a specific collection) to show items having a specific set of one or more tags.  Tags are portable, but collections are not. Copying items between Zotero libraries (My Library and group libraries) will transfer their tags, but not their collection placements. Both organizational methods have unique advantages and features. Experiment with both to see what works best for your own workflow.

## Server installation

### Dependencies and source code

* make sure docker and docker-compose are installed in your build host.
* Clone the repository (with **--recursive** because there are multiple level of submodules)*:
```bash
$ mkdir /path/to/your/app && cd /path/to/your/app
$ git clone --recursive <reporitory url here>
$ cd zotero-selfhost
```
* To faciliate future updates, necessary changes to official code are maintained as patches in
src/patches/, run in top level directory, run ./utils/patch.sh to apply them.

```bash
./utils/patch.sh
```

*Configure and run*:
```bash
$ sudo docker-compose up -d
```
docker-compose will pull(mysql, minio, redis, localstack, elasticsearch, memcached, phpadmin) or build(app-zotero) all necessary docker images for you.

app-zotero is the main container for dataserver/stream-server/tinymce-clean-server.

### Initialize 

*Initialize databases, s3 buckets and SNS*:
```bash
$ ./bin/init.sh  //run after docker-compose up
$ cd ..
```

*Available endpoints*:

| Name          | URL                                           |
| ------------- | --------------------------------------------- |
| Zotero API    | http://localhost:8080                         |
| Stream ws     | ws://localhost:8081                           |
| S3 Web UI     | http://localhost:8082                         |
| PHPMyAdmin    | http://localhost:8083                         |

*Default login/password*:

| Name          | Login                    | Password           |
| ------------- | ------------------------ | ------------------ |
| Zotero API    | admin                    | admin              |
| S3 Web UI     | zotero                   | zoterodocker       |
| PHPMyAdmin    | root                     | zotero             |

## Client installation

The official client source is almost usable. Only a few patches are needed
to change hard-coded *zotero.org* into your urls.  Patches are put in 
./src/patches/zotero-client/. 


In fact, you can direct download the clients from zotero website, and change
the file in zoter.jar:

```bash
$ unpack Zoter Client, cd into the directory
$ mkdir tmp && cd ./tmp
$ jar xvf ../zotero.jar
$ ... edit the ./resource/config.js file here
$ rm -f ../zotero.jar && jar cvf ../zotero.jar .
```bash

If you are running with both server and client in your machine, only change
./resource/config.js is enough. Otherwise, you need to change this file too:
chrome/content/zotero/xpcom/storage/zfs.js. Because the dataserver is modified 
to return S3 url of http://localhost:8080, client will try to use that to access
the S3 storage and fail with S3 return 0 errors. The following patch shows how to
change, but remember to change the domain name to your real one.

```
diff --git a/chrome/content/zotero/xpcom/storage/zfs.js b/chrome/content/zotero/xpcom/storage/zfs.js
index 794b5cbad..ff27a001d 100644
--- a/chrome/content/zotero/xpcom/storage/zfs.js
+++ b/chrome/content/zotero/xpcom/storage/zfs.js
@@ -636,6 +636,10 @@ Zotero.Sync.Storage.Mode.ZFS.prototype = {
 		}
 		
 		var blob = new Blob([params.prefix, file, params.suffix]);
+
+		// FIXME: change https://zotero.your.domain to your server link
+		var url = params.url.replace(/http:\/\/localhost:8082/, 'https://zotero.your.domain');
+		params.url = url;
 		
 		try {
 			var req = yield Zotero.HTTP.request(

```

The build process is the same as official one.

### Dependencies and source code

*Install dependencies for client build*:
```bash
$ sudo apt install npm
```

For [m|l|w]: m=Mac, w=Windows, l=Linux

*Run*:
```bash
$ cd client
$ ./config.sh
$ cd zotero-client
$ npm install
$ npm run build
$ cd ../zotero-standalone-build
$ ./fetch_xulrunner.sh -p [m|l|w]
$ ./fetch_pdftools
$ ./scripts/dir_build -p [m|l|w]
```

### First usage

*Run*:
```bash
$ ./staging/Zotero_VERSION/zotero(.exe)
```

*Connect with the default user and password*:

| Name          | Login                    | Password           |
| ------------- | ------------------------ | ------------------ |
| Zotero        | admin                    | admin              |

## deployment

For personal usage, you can run the server and client in the same machine and
it should be working. The source code is modified for that.

For intranet usage, change the client side's url, replace localhost with server
IP.

For internet usage, you can setup a website with ssl enabled, and use reverse 
proxy to get it back to internal servers. Of course, you can enable SSL and deploy
it directly in external servers, but I have not tried that.

## server management

There are no user management interface for now. You can use the script
./bin/create-user.sh to add some users.

## TODO

* Add web-library and user management interface. Web-library is working with
correct setting of urls, user & key. A simple login/register interface will
bring the experience almost the same with the official one.
