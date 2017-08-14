# Set the base image to Ubuntu
FROM ubuntu:16.04

# Arguments and versions
ARG PHP_VERSION=7.0

# Environment Variables
ENV DEBIAN_FRONTEND noninteractive
ENV LOCALE en_US.UTF-8
ENV PHP_VERSION ${PHP_VERSION}

# Base Packages
RUN apt-get update -y

# Basic packages
RUN apt-get install -y locales git wget curl vim debconf-utils sudo build-essential autoconf libpcre3-dev rsync \
        software-properties-common python-software-properties

# Set locale
RUN locale-gen $LOCALE && update-locale LANG=$LOCALE


# Apache
RUN apt-get install -y apache2 apache2-utils libapache2-mod-geoip geoip-database
ADD configs/apache2/apache2-service.sh /apache2-service.sh
ADD configs/apache2/apache2-setup.sh /apache2-setup.sh
RUN chmod +x /*.sh
ADD configs/apache2/apache_default /etc/apache2/sites-available/000-default.conf
ADD configs/apache2/supervisor.conf /etc/supervisor/conf.d/apache2.conf
RUN /apache2-setup.sh

# PHP and PHP packages that are important to running dynamic PHP based applications with Apache2 Webserver support 
RUN sudo add-apt-repository ppa:ondrej/php
RUN sudo apt-get update
RUN apt-get install -y \
    php$PHP_VERSION \
    libapache2-mod-php$PHP_VERSION \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-common \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-enchant \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-gmp \
    php$PHP_VERSION-imap \
    php$PHP_VERSION-interbase \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-json \
    php$PHP_VERSION-ldap \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-memcache \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-mcrypt \
    php$PHP_VERSION-opcache \
    php-pear \
    php$PHP_VERSION-pspell \
    php$PHP_VERSION-readline \
    php$PHP_VERSION-recode \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-tidy \
    php$PHP_VERSION-xdebug \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-xmlrpc \
    php$PHP_VERSION-zip

ADD configs/php/php.ini /etc/php/$PHP_VERSION/apache2/php.ini

# Setup PHP.
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.0/apache2/php.ini
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.0/cli/php.ini

# Setup Apache.
# In order to run our Simpletest tests, we need to make Apache
# listen on the same port as the one we forwarded. Because we use
# 8080 by default, we set it up for that port.
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/default-ssl.conf
RUN echo "Listen 8080" >> /etc/apache2/ports.conf
RUN echo "Listen 8081" >> /etc/apache2/ports.conf
RUN echo "Listen 8443" >> /etc/apache2/ports.conf
RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:\*/' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/VirtualHost __default__:443/VirtualHost _default_:443 _default_:8443/' /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2ensite default-ssl.conf

# Setup PHPMyAdmin
RUN apt-get install phpmyadmin -y
RUN echo "\n# Include PHPMyAdmin configuration\nInclude /etc/phpmyadmin/apache.conf\n" >> /etc/apache2/apache2.conf
RUN sed -i -e "s/\/\/ \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\]/\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\]/g" /etc/phpmyadmin/config.inc.php
RUN sed -i -e "s/\$cfg\['Servers'\]\[\$i\]\['\(table_uiprefs\|history\)'\].*/\$cfg\['Servers'\]\[\$i\]\['\1'\] = false;/g" /etc/phpmyadmin/config.inc.php

# Setup MySQL, bind on all addresses.
RUN apt-get install -y mysql-server mysql-client 
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql: /var/run/mysqld
RUN sed -i -e 's/^bind-address\s*=\s*127.0.0.1/#bind-address = 127.0.0.1/' /etc/mysql/my.cnf
RUN /etc/init.d/mysql start && \
	mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO drupal@localhost IDENTIFIED BY 'drupal'"

# Setup SSH.
RUN apt-get install -y openssh-server
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
RUN mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor
RUN echo '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo '[program:mysql]\ncommand=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf


# Setup XDebug.
RUN echo "xdebug.max_nesting_level = 300" >> /etc/php/7.0/apache2/conf.d/20-xdebug.ini
RUN echo "xdebug.max_nesting_level = 300" >> /etc/php/7.0/cli/conf.d/20-xdebug.ini

# *******************************************************
# DRUPAL 
# *******************************************************

ARG DRUSH_VERSION=8.1.10
ARG DRUPAL_VERSION=8.3.6
ARG NODE_VERSION=6.10.0
ARG DRUPAL_ROOT=/var/www/html/web

ENV DRUSH_VERSION ${DRUSH_VERSION}
ENV DRUPAL_VERSION ${DRUPAL_VERSION}
ENV NODE_VERSION ${NODE_VERSION}
ENV DRUPAL_ROOT ${DRUPAL_ROOT}

# Installing nodejs from binaries
RUN cd /tmp && \
  curl -sL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" -o node-linux-x64.tar.gz && \
  tar -zxf "node-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
  rm node-linux-x64.tar.gz && \
  ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install bower and gulp-cli globally
RUN npm install --global bower gulp-cli

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# Update PATH variable to include Composer binaries.
ENV PATH "/root/.composer/vendor/bin:$PATH"

## Install Drush.
RUN composer global require drush/drush:$DRUSH_VERSION
RUN composer global update
# binding
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Install Drupal Console.
RUN curl https://drupalconsole.com/installer -L -o drupal.phar && \
	mv drupal.phar /usr/local/bin/drupal && \
	chmod +x /usr/local/bin/drupal
RUN drupal init


# Install Drupal.
RUN rm -rf /var/www
RUN cd /var && \
	drush dl drupal-$DRUPAL_VERSION && \
	mv /var/drupal* /var/www
RUN mkdir -p /var/www/sites/default/files && \
	chmod a+w /var/www/sites/default -R && \
	mkdir /var/www/sites/all/modules/contrib -p && \
	mkdir /var/www/sites/all/modules/custom && \
	mkdir /var/www/sites/all/themes/contrib -p && \
	mkdir /var/www/sites/all/themes/custom && \
	cp /var/www/sites/default/default.settings.php /var/www/sites/default/settings.php && \
	cp /var/www/sites/default/default.services.yml /var/www/sites/default/services.yml && \
	chmod 0664 /var/www/sites/default/settings.php && \
	chmod 0664 /var/www/sites/default/services.yml && \
	chown -R www-data:www-data /var/www/

RUN cd /var/www && \
	drush si -y standard --db-url=mysql://drupal:drupal@localhost/drupal --account-pass=admin && \
	drush dl admin_menu devel && \
	# In order to enable Simpletest, we need to download PHPUnit.
	composer install --dev && \
	drush en -y bartik
RUN cd /var/www && \
	drush cset system.theme default 'bartik' -y




# Start
# VOLUME ["/var/www/html","/var/log/apache2","/var/log/supervisor","/var/log/mysql","/var/lib/mysql"]
EXPOSE 80 3306 22 443

CMD ["supervisord", "-n"]
