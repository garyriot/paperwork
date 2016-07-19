#Paperwork aims to be an open-source, self-hosted alternative to services like Evernote ®, Microsoft OneNote #® or Google Keep ®.
#Paperwork is written in PHP, utilising the beautiful Laravel 4 framework. It provides a modern web UI, #built on top of AngularJS & Bootstrap 3, as well as an open API for third party integration.
#For the back-end part a MySQL database stores everything. With such common requirements (Linux, Apache, #MySQL, PHP), Paperwork will be able to run not only on dedicated servers, but also on small to mid-size NAS #devices (Synology ®, QNAP ®, etc.).

FROM centurylink/apache-php:latest
MAINTAINER Gary Guo  <garyriot@gmail.com>

# Install packages
RUN apt-get update && \
 DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
 #DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor pwgen && \
 apt-get -y install mysql-server mysql-client libmcrypt4 php5-mcrypt php5-json php5-curl \
 php5-ldap php5-cli nodejs nodejs-legacy npm git git-core

#Fetch the latest Paperwork code
RUN cd /tmp && \
 git clone https://github.com/twostairs/paperwork.git && \
 cd /tmp/paperwork/frontend && \
 cp /tmp/paperwork/frontend/deploy/apache.conf /etc/apache2/sites-enabled/000-default.conf  && \
 cp -r * /app

# Override default apache conf
##ADD ./deploy/apache.conf /etc/apache2/sites-enabled/000-default.conf

# Configure /app folder
RUN a2enmod rewrite && php5enmod mcrypt && \
    mkdir -p /app && rm -rf /var/www/html && ln -s /app/public /var/www/html

# Copy application + install dependencies
WORKDIR /app

RUN \
    # Allow writing access into cache storage
    find ./app/storage -type d -print0 | xargs -0 chmod 0755 && \
    find ./app/storage -type f -print0 | xargs -0 chmod 0644 && \
    # Install dependencies and build the scripts and styles
    composer install && npm update  && \
    npm install -g gulp && npm install  && \
    # Fix permissions for apache \
    chown -R www-data:www-data /app && chmod +x /app/docker-runner.sh

# Override environment to ensure laravel is running migrations.
RUN sed -i 's/return $app;//' /app/bootstrap/start.php
RUN echo '$env = $app->detectEnvironment(function() { return "development"; }); return $app;' >> /app/bootstrap/start.php

ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#CMD ["/app/docker-runner.sh"]
# VOLUME ["/config"]
# Clean up APT when done.
 RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
