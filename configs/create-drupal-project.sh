#!/bin/bash

cd /var/www && \
	drush si -y standard --db-url=mysql://root:$MYSQL_ROOT_PASSWORD@$MYSQL_HOST:3306/drupal --account-pass=admin --notify && \
	drush dl admin_menu devel && \
	composer install --dev && \
	drush en -y bartik && \ 

cd /var/www && \
	drush cset system.theme default 'bartik' -y