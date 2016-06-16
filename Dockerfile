FROM alpine:3.3

MAINTAINER Fábio Luciano <fabioluciano@php.net>

ENV COMPOSER_HOME /usr/share/composer/
ENV TIMEZONE            America/Sao_Paulo
ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        100M

RUN apk update \
  && apk --update add make autoconf g++ gcc libc-dev curl ca-certificates bash  \
  && apk --update add nginx git supervisor tzdata \
  && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
  && echo "${TIMEZONE}" > /etc/timezone \
  && apk --update add php-mcrypt php-soap php-openssl php-gmp php-pdo_odbc \
    php-json php-dom php-pdo php-zip php-mysql php-sqlite3 php-apcu php-pear \
    php-pdo_pgsql php-bcmath php-gd php-xcache php-odbc php-pdo_mysql php-dev \
    php-pdo_sqlite php-gettext php-xmlreader php-xmlrpc php-bz2 php-memcache \
    php-mssql php-iconv php-pdo_dblib php-curl php-ctype php-fpm php-phar \
  && rm -rf /var/cache/apk/* \

  && sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php/php-fpm.conf \
  && sed -i "s|;*listen\s*=\s*127.0.0.1:9000|listen = 9000|g" /etc/php/php-fpm.conf \
  && sed -i "s|;*listen\s*=\s*/||g" /etc/php/php-fpm.conf \
  && sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php/php.ini \
  && sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php/php.ini \
  && sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php/php.ini \
  && sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php/php.ini \
  && sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php/php.ini \
  && sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php/php.ini \

  && mkdir /www \
  && apk del tzdata \
  && rm -rf /var/cache/apk/*

WORKDIR /tmp

RUN git clone https://github.com/phalcon/cphalcon \
  && cd cphalcon/build/ \
  && ./install \
  && rm -rf /tmp/* \
  && echo "extension=phalcon.so" > /etc/php/conf.d/phalcon.ini

ADD files/supervisord.conf /etc/supervisord.conf
ADD files/phalcon.conf /etc/nginx/nginx.conf

RUN mkdir /var/www/phalcon
RUN echo '<?php phpinfo() ?>' > /var/www/phalcon/index.php
# RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bkp

chmod a+rwx /var/www/phalcon


EXPOSE 80 443

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
