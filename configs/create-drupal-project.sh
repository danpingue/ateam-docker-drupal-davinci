#!/bin/bash

cd /var/www

composer create-project drupal-composer/drupal-project:8.x-dev $DRUPAL_PROJECT --stability dev --no-interaction

cd $DRUPAL_PROJECT/web
drush si -y standard --db-url=mysql://root:$MYSQL_ROOT_PASSWORD@$MYSQL_HOST:3306/$DRUPAL_PROJECT --account-pass=admin 

cd /var/www/$DRUPAL_PROJECT/
composer require drupal/ctools
composer require drupal/da_vinci
composer require drupal/geolocation
composer require drupal/panels
composer require drupal/paragraphs

cd /var/www/$DRUPAL_PROJECT/web
drush cset system.theme default 'da_vinci' -y

chown -R www-data:www-data /var/www/