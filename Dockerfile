# Set the base image to Ubuntu
FROM ubuntu:16.04

# Arguments and versions
ARG PHP_VERSION=7.0
ARG DRUSH_VERSION=8.1.10
ARG NODE_VERSION=6.10.0
ARG DEVELOPER=developer

# Environment Variables
ENV DEBIAN_FRONTEND noninteractive
ENV LOCALE en_US.UTF-8
ENV PHP_VERSION ${PHP_VERSION}
ENV DRUSH_VERSION ${DRUSH_VERSION}
ENV NODE_VERSION ${NODE_VERSION}
ENV DEVELOPER ${DEVELOPER}

# Base Packages
RUN apt-get update -y

# Basic packages
RUN apt-get install -y locales git wget curl vim debconf-utils sudo build-essential autoconf libpcre3-dev rsync \
        software-properties-common python-software-properties

# Set locale
RUN locale-gen $LOCALE && update-locale LANG=$LOCALE

# Setup Apache.
RUN apt-get install -y apache2 apache2-utils libapache2-mod-geoip geoip-database
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/default-ssl.conf
RUN echo "Listen 8080" >> /etc/apache2/ports.conf
RUN echo "Listen 8081" >> /etc/apache2/ports.conf
RUN echo "Listen 8443" >> /etc/apache2/ports.conf
RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:\*/' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/VirtualHost __default__:443/VirtualHost _default_:443 _default_:8443/' /etc/apache2/sites-available/default-ssl.conf
RUN chown -R www-data:www-data /var/www/
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2ensite default-ssl.conf


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

# Config PHP.
ADD configs/php/php.ini /etc/php/$PHP_VERSION/apache2/php.ini
ADD configs/php/php.ini /etc/php/$PHP_VERSION/cli/php.ini

# Config XDebug.
RUN echo "xdebug.max_nesting_level = 300" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini
RUN echo "xdebug.max_nesting_level = 300" >> /etc/php/$PHP_VERSION/cli/conf.d/20-xdebug.ini

# Setup MySQL client.
RUN apt-get install -y mysql-client 


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
RUN echo '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf


# *******************************************************
# DRUPAL support
# *******************************************************


# ******************************************
# Start USER developer 
# Create user 
RUN mkdir /home/$DEVELOPER
RUN chown 1000:1000 -R /home/$DEVELOPER
RUN echo "$DEVELOPER:!:1000:1000:$DEVELOPER,,,:/home/$DEVELOPER:/bin/bash" >> /etc/passwd
RUN echo "$DEVELOPER:!:1000:" >> /etc/group
RUN echo "$DEVELOPER:*:99999:0:99999:7:::" >> /etc/shadow
RUN echo "$DEVELOPER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$DEVELOPER
RUN chmod 0440 /etc/sudoers.d/$DEVELOPER
ADD configs/user/bashrc /home/$DEVELOPER/.bashrc
#RUN source ~/.bashrc


# Change user for install dependencies
USER $DEVELOPER
WORKDIR /home/$DEVELOPER

RUN mkdir /home/$DEVELOPER/Proyectos
RUN chown $DEVELOPER:$DEVELOPER /home/$DEVELOPER/Proyectos

# Install node
RUN cd /home/$DEVELOPER
RUN curl -sL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" -o node-linux-x64.tar.gz
RUN sudo tar -zxf "node-linux-x64.tar.gz" -C /usr/local --strip-components=1 
RUN rm node-linux-x64.tar.gz 
RUN sudo ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install bower and gulp-cli globally
RUN sudo npm install --global bower gulp-cli

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php 
RUN sudo mv composer.phar /usr/local/bin/composer
RUN sudo chmod a+x /usr/local/bin/composer
ENV PATH "/home/$DEVELOPER/.composer/vendor/bin:$PATH"

## Install Drush.
RUN composer global require drush/drush:$DRUSH_VERSION
RUN composer global update

# Install Drupal Console.
RUN composer global require drupal/console:@stable

# Install Drupal Coder
RUN composer global require drupal/coder
RUN composer global require dealerdirect/phpcodesniffer-composer-installer

# Test it
RUN phpcs -i



# End USER developer
# ******************************************


# Copy script for create projects
ADD configs/create-drupal-project.sh /create-drupal-project.sh
RUN sudo chmod +x /create-drupal-project.sh

ADD configs/create-user-drupal-project.sh /home/$DEVELOPER/create-user-drupal-project.sh
RUN sudo chmod +x /home/$DEVELOPER/create-user-drupal-project.sh

# Change user to root
USER root

# Start
VOLUME ["/var/www/html","/var/log/apache2","/var/log/supervisor"]
EXPOSE 80 22 443

CMD ["supervisord", "-n"]






#docker exec -u ocastano -it env-dev-d8 bash