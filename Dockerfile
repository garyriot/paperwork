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
 php5-ldap php5-cli nodejs nodejs-legacy npm git git-core openssh-server openssh-client

#Fetch the latest Paperwork code
RUN cd /tmp && \
 git clone https://github.com/twostairs/paperwork.git && \
 cd /tmp/paperwork/frontend && \
 cp /tmp/paperwork/frontend/deploy/apache.conf /etc/apache2/sites-enabled/000-default.conf  && \
 cp -r * /app

RUN service mysql start &&\  
    mysql -e "grant all privileges on *.* to 'root'@'%' identified by 'letmein';"&&\  
    mysql -e "grant all privileges on *.* to 'root'@'localhost' identified by 'letmein';"&&\  
    mysql -u root -pletmein -e "CREATE DATABASE IF NOT EXISTS paperwork DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" && \
    mysql -u root -pletmein -e "CREATE USER 'paperwork'@'localhost' IDENTIFIED BY 'paperwork'" && \
    mysql -u root -pletmein -e "GRANT ALL PRIVILEGES ON paperwork.* TO 'paperwork'@'localhost'"  && \
    mysql -u root -pletmein -e "FLUSH PRIVILEGES" && \
    mysql -u root -pletmein -e "show databases;" 
    
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
    composer install && npm update && npm install && \
    npm install -g gulp bower && bower --allow-root install && gulp && \

    # Fix permissions for apache \
    chown -R www-data:www-data /app && chmod +x /app/docker-runner.sh


#RUN chmod -R 777 /app/app/storage/logs/

# Override environment to ensure laravel is running migrations.
RUN sed -i 's/return $app;//' /app/bootstrap/start.php
RUN echo '$env = $app->detectEnvironment(function() { return "development"; }); return $app;' >> /app/bootstrap/start.php

ADD css /app/public
ADD js /app/js
ADD database.json /app/app/storage/config/
#ADD paperwork.json /app/app/storage/config/
#ADD setup.php /app/public/
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

# CMD ["/app/docker-runner.sh"]
# VOLUME ["/config"]
# Clean up APT when done.
 # RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
