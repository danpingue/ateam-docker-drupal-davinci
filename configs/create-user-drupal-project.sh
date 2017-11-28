#!/bin/bash

DRUPAL_PROJECT=$1
DEVELOPER_HOME=/home/$DEVELOPER/Proyectos

sudo chown $DEVELOPER:$DEVELOPER $DEVELOPER_HOME

cd $DEVELOPER_HOME

composer create-project drupal-composer/drupal-project:$DRUPAL_VERSION_MAYOR.x-dev $DRUPAL_PROJECT --stability dev --no-interaction

cd $DRUPAL_PROJECT/web
drush si -y standard --db-url=mysql://root:$MYSQL_ROOT_PASSWORD@$MYSQL_HOST:3306/$DRUPAL_PROJECT --account-pass=admin 
#  --locale=es 

cd $DEVELOPER_HOME/$DRUPAL_PROJECT/
composer require drupal/ctools
composer require drupal/admin_toolbar
composer require drupal/da_vinci

cd $DEVELOPER_HOME/$DRUPAL_PROJECT/web
drush en ctools -y
drush en admin_toolbar -y
drush en da_vinci -y

# drush cset system.theme default 'da_vinci' -y

sudo ln -s $DEVELOPER_HOME/$DRUPAL_PROJECT /var/www/$DRUPAL_PROJECT

sudo chown -R www-data:www-data /var/www/
