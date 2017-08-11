############################################################
# Dockerfile to build Drupal and LAMP Installed Containers
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu:16.04

# Set the enviroment variable
ENV DEBIAN_FRONTEND noninteractive

# Install required packages
RUN apt-get clean all
RUN apt-get update && \
    # base depends
    apt-get install -y locales wget curl sudo git vim less unzip re2c rsync \
    build-essential libpcre3-dev software-properties-common automake make autoconf \
    bash-completion supervisor openssh-server openssh-client \
    # stack services depends
    apache2 apache2-utils mysql-client mysql-server libapache2-mod-php libapache2-mod-geoip geoip-database \
    # php depends
    php \
    php-bcmath \
    php-cli \
    php-curl \
    php-dba \
    php-dev \
    php-enchant \
    php-gd \
    php-gmp \
    php-imap \
    php-interbase \
    php-intl \
    php-json \
    php-ldap \
    php-mbstring \
    php-memcache \
    php-mysql \
    php-opcache \
    php-pear \
    php-pspell \
    php-readline \
    php-recode \
    php-tidy \
    php-xdebug \
    php-xml \
    php-xmlrpc \
    php-zip \
    php7-fpm \
    && \

# Setup ssh
RUN mkdir -p /var/run/sshd


# Add shell scripts for starting apache2
ADD apache2-start.sh /apache2-start.sh

# Add shell scripts for starting mysql
ADD mysql-start.sh /mysql-start.sh
ADD run.sh /run.sh

# Give the execution permissions
RUN chmod 755 /*.sh

# Add the Configurations files
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-lamp.conf /etc/supervisor/conf.d/supervisord-lamp.conf


# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Enviroment variable for setting the Username and Password of MySQL
ENV MYSQL_USER root
ENV MYSQL_PASS root

# Drupal Database name $PROJECT_NAME
ENV DRUPAL_DBNAME drupal

# Add MySQL utils
ADD create_database.sh /create_database.sh
ADD mysql_user.sh /mysql_user.sh
RUN chmod 755 /*.sh


# Add volumes for MySQL 
VOLUME ["/var/log/apache2","/var/log/supervisor","/var/log/mysql","/var/lib/mysql", "/etc/mysql"]

# INSTALL DRUPAL

ARG DRUSH_VERSION=8.1.10
ARG DRUPAL_VERSION=8
ARG NODE_VERSION=6.10.0
ARG DRUPAL_ROOT=/var/www/html/web

ENV DRUSH_VERSION ${DRUSH_VERSION}
ENV DRUPAL_VERSION ${DRUPAL_VERSION}
ENV NODE_VERSION ${NODE_VERSION}
ENV DRUPAL_ROOT ${DRUPAL_ROOT}


# Install uploadprogress php extension from a php-7-supported src
RUN /bin/bash -c 'cd /tmp/ && \
      git clone https://github.com/Jan-E/uploadprogress.git && \
      cd uploadprogress && \
      phpize && \
      ./configure && make && make install && \
      echo "extension=uploadprogress.so" > /etc/php/7.0/mods-available/uploadprogress.ini && \
      phpenmod uploadprogress'

# Install Composer
RUN curl -k -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

# Installing nodejs from binaries
RUN cd /tmp && \
  curl -sL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" -o node-linux-x64.tar.gz && \
  tar -zxf "node-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
  rm node-linux-x64.tar.gz && \
  ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install bower and gulp-cli globally
RUN npm install --global bower gulp-cli

# Install PHPUnit
RUN curl -sSL https://phar.phpunit.de/phpunit.phar -o phpunit.phar && \
        chmod +x phpunit.phar && \
        mv phpunit.phar /usr/local/bin/phpunit

## Install Drush.
RUN composer global require drush/drush:$DRUSH_VERSION && \
    mv $HOME/.composer /usr/local/share/composer && \
    ln -s /usr/local/share/composer/vendor/drush/drush/drush /usr/local/bin/drush

## Install drupal console
RUN curl https://drupalconsole.com/installer -L -o /usr/local/bin/drupal && \
    chmod +x /usr/local/bin/drupal

# Configure php.ini
RUN sed -i \
        -e "s/^expose_php.*/expose_php = Off/" \
        -e "s/^;date.timezone.*/date.timezone = UTC/" \
        -e "s/^memory_limit.*/memory_limit = -1/" \
        -e "s/^max_execution_time.*/max_execution_time = 300/" \
        -e "s/^; max_input_vars.*/max_input_vars = 2000/" \
        -e "s/^post_max_size.*/post_max_size = 512M/" \
        -e "s/^upload_max_filesize.*/upload_max_filesize = 512M/" \
        -e "s/^error_reporting.*/error_reporting = E_ALL/" \
        -e "s/^display_errors.*/display_errors = On/" \
        -e "s/^display_startup_errors.*/display_startup_errors = On/" \
        -e "s/^track_errors.*/track_errors = On/" \
        -e "s/^mysqlnd.collect  _memory_statistics.*/mysqlnd.collect_memory_statistics = On/" \
        /etc/php7/php.ini && \

    echo "error_log = \"/proc/self/fd/2\"" | tee -a /etc/php/7.0/apache2/php.ini


# Create user www-data
RUN addgroup -g 82 -S www-data && \
	adduser -u 82 -D -S -G www-data www-data

# Create work dir
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www

# Init www-data user
USER www-data
RUN composer global require hirak/prestissimo:^0.3 --optimize-autoloader && \
    rm -rf ~/.composer/.cache && \
    drupal init --override

USER root
# CMD docker-entrypoint.sh


# Set the port
EXPOSE 80 3306

# Execut the run.sh 
CMD ["/run.sh"]
