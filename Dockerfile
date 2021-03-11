# Use the official Docker Hub Ubuntu 18.04 base image
FROM ubuntu:18.04

RUN sed -i -e 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list
RUN sed -i -e 's/deb http:\/\/security/#deb http:\/\/security/' /etc/apt/sources.list
RUN sed -i -e 's/deb https:\/\/security/#deb https:\/\/security/' /etc/apt/sources.list

# Update the base image
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

# Setup PHP5
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common apt-utils
#RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install pkg-config re2c
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 libapache2-mod-php7.2 sudo rsyslog wget mysql-client curl unzip
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php7.2-cli php7.2-xml php7.2-mysql php7.2-pgsql php7.2-json php7.2-curl php7.2-mbstring php7.2-intl php7.2-redis php7.2-dev composer vim php-http-request2 php-memcached php-igbinary php-msgpack
#RUN DEBIAN_FRONTEND=noninteractive pecl channel-update pecl.php.net

RUN sed -i 's/memory_limit = 128M/memory_limit = 1G/g' /etc/php/7.2/apache2/php.ini
RUN sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/7.2/apache2/php.ini
RUN sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.2/apache2/php.ini
RUN sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.2/cli/php.ini
RUN sed -i 's/display_errors = On/display_errors = Off/g' /etc/php/7.2/apache2/php.ini
RUN sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/g' /etc/php/7.2/apache2/php.ini

# Setup igbinary
#RUN DEBIAN_FRONTEND=noninteractive pecl install igbinary
#RUN echo "extension=igbinary.so" > /etc/php/7.2/mods-available/igbinary.ini
#RUN ln -sf /etc/php/7.2/mods-available/igbinary.ini /etc/php/7.2/cli/conf.d/20-igbinary.ini
#RUN ln -sf /etc/php/7.2/mods-available/igbinary.ini /etc/php/7.2/apache2/conf.d/20-igbinary.ini
RUN phpenmod igbinary

# Setup Memcached
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libmemcached11 libmemcachedutil2 build-essential libmemcached-dev libz-dev libxml2-dev zlib1g-dev libicu-dev g++
#RUN DEBIAN_FRONTEND=noninteractive pecl download memcached-3.0.4 && tar xvzf memcached-3.0.4.tgz && cd memcached-3.0.4 && phpize && ./configure --enable-memcached-igbinary && make && make install
#RUN echo "extension=memcached.so" > /etc/php/7.2/mods-available/memcached.ini
#RUN ln -sf /etc/php/7.2/mods-available/memcached.ini /etc/php/7.2/cli/conf.d/20-memcached.ini
#RUN ln -sf /etc/php/7.2/mods-available/memcached.ini /etc/php/7.2/apache2/conf.d/20-memcached.ini

RUN phpenmod msgpack && phpenmod memcached

# HTTP_Request2
# RUN DEBIAN_FRONTEND=noninteractive pear install HTTP_Request2

# Setup awscli
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install python python-pip git wget rinetd awscli
#RUN DEBIAN_FRONTEND=noninteractive pip install awscli

# Setup Apache2
RUN a2enmod headers
RUN a2enmod rewrite

# Enable the new virtualhost
COPY config/zotero.conf /etc/apache2/sites-available/
RUN a2dissite 000-default
RUN a2ensite zotero

# Override gzip configuration
COPY config/gzip.conf /etc/apache2/conf-available/
RUN a2enconf gzip

# AWS local credentials
RUN mkdir ~/.aws  && bash -c 'echo -e "[default]\nregion = us-east-1" > ~/.aws/config' && bash -c 'echo -e "[default]\naws_access_key_id = zotero\naws_secret_access_key = zoterodocker" > ~/.aws/credentials'

# Chown log directory
RUN chown 33:33 /var/log/apache2

# Rinetd
RUN echo "0.0.0.0		8082		minio		9000" >> /etc/rinetd.conf

# Expose and entrypoint
COPY config/entrypoint.sh /
RUN chmod +x /entrypoint.sh
EXPOSE 80/tcp
EXPOSE 81/TCP
EXPOSE 82/TCP
ENTRYPOINT ["/entrypoint.sh"]

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install npm nodejs

COPY ./src/server/dataserver/ /var/www/zotero/
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN cd /var/www/zotero && composer install

COPY ./src/server/stream-server/ /var/www/stream-server/
RUN cd /var/www/stream-server && npm i
COPY ./src/server/tinymce-clean-server/ /var/www/tinymce-clean-server/
RUN cd /var/www/tinymce-clean-server && npm i

VOLUME /var/www/zotero/errors
