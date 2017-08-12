# Set the base image to Ubuntu
FROM ubuntu:16.04

# Environment Variables
ENV DEBIAN_FRONTEND noninteractive
ENV LOCALE en_US.UTF-8

# Base Packages
RUN apt-get update -y
# RUN apt-get upgrade -y

#RUN apt-get install -y net-tools iputils-ping iproute2 sysstat iotop tcpdump tcpick bwm-ng tree strace screen inotify-tools socat 
# software-properties-common  emacs python-minimal fontconfig ssmtp mailutils bash-completion less unzip

# Basic packages
RUN apt-get install -y locales git wget curl vim debconf-utils sudo build-essential automake make autoconf libpcre3-dev rsync

# Supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

# Set locale
RUN locale-gen $LOCALE && update-locale LANG=$LOCALE

# SSH
RUN apt-get install -y openssh-server
ADD configs/ssh/supervisor.conf /etc/supervisor/conf.d/ssh.conf
RUN mkdir -p /var/run/sshd

# Apache
RUN apt-get install -y apache2 apache2-utils libapache2-mod-php libapache2-mod-geoip geoip-database
ADD configs/apache2/apache2-service.sh /apache2-service.sh
ADD configs/apache2/apache2-setup.sh /apache2-setup.sh
RUN chmod +x /*.sh
ADD configs/apache2/apache_default /etc/apache2/sites-available/000-default.conf
ADD configs/apache2/supervisor.conf /etc/supervisor/conf.d/apache2.conf
RUN /apache2-setup.sh

# PHP
RUN apt-get install -y \
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
    php-soap \
    php-tidy \
    php-xdebug \
    php-xml \
    php-xmlrpc \
    php-zip

ADD configs/php/php.ini /etc/php/apache2/conf.d/30-docker.ini


# MySQL
RUN apt-get install -y mysql-server mysql-client 
ADD configs/mysql/mysql-setup.sh /mysql-setup.sh
RUN chmod +x /*.sh
ADD configs/mysql/my.cnf /etc/mysql/my.cnf
ADD configs/mysql/supervisor.conf /etc/supervisor/conf.d/mysql.conf
RUN mkdir -p /var/run/mysqld && \
        chown -R mysql: /var/run/mysqld
# RUN /mysql-setup.sh

# PHPMyAdmin
RUN (echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/app-password password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/app-password-confirm password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/mysql/admin-pass password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/mysql/app-pass password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections)
RUN apt-get install phpmyadmin -y
ADD configs/phpmyadmin/config.inc.php /etc/phpmyadmin/conf.d/config.inc.php
RUN chmod 755 /etc/phpmyadmin/conf.d/config.inc.php
ADD configs/phpmyadmin/phpmyadmin-setup.sh /phpmyadmin-setup.sh
RUN chmod +x /phpmyadmin-setup.sh
# RUN /phpmyadmin-setup.sh

# Start
VOLUME ["/var/www/html","/var/log/apache2","/var/log/supervisor","/var/log/mysql","/var/lib/mysql"]
EXPOSE 22 80 3306

CMD ["supervisord", "-n"]