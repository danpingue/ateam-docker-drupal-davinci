# A Team - Docker - Drupal8 - Da Vinci theme

## Features:
  - Docker
  - Docker-Compose
  - Drupal 8
  - PHP 7
  - Apache
  - MYSQL
  - PHPMyAdmin
  - Supervisor
  - NODE 
  - Bower and Gulp
  - Composer
  - Drupal console
  - Drush
  - Developer user
  - Multiproject drupal

## Base software (install last docker)
  - Uninstall old versions 
    ```sh
        $ sudo apt-get remove docker docker-engine docker.io
    ```
  - Install Docker CE
    ```sh
        $ sudo apt-get update
        
        $ sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common
            
        $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        
        $ sudo add-apt-repository \
           "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) \
           stable"
        $ sudo apt-get update
        
        $ sudo apt-get install docker-ce
    ```

## Customomise docker-compose.yml
  - Set DRUPAL_PROJECT to your default project name
  - Set DEVELOPER to your user
  - Set volumes to your developer user (change ocastano for your user)

## Run containers
  - Clone project and go to project folder 
  - Build images
    ```sh
        $ docker composer build
    ```
  - Run images
    ```sh
        $ docker composer up
    ```

## Ports and services
- PHPMyAdmin: http://localhost:7000
- Apache2 in dev container: http://localhost or http://localhost:8080


## Access to env-dev-d8 container

### root access 
    
```sh
    $ docker exec -it env-dev-d8 bash
```

### developer access

```sh
    $ docker exec -u YOUR_DEVELOPER_NAME -it env-dev-d8 bash
```

## Create composer drupal project in env-dev-d8 container

### root access (general project with default name in docker-compose.yml)
    
```sh
    $ docker exec -it env-dev-d8 bash
    $ cd /
    $ ./create-drupal-project.sh
    $ cd /var/www/$DRUPAL_PROJECT
```
> Open browser and go to: http://localhost

### developer access and custon project name

```sh
    $ docker exec -u YOUR_DEVELOPER_NAME -it env-dev-d8 bash
    $  ./create-drupal-project.sh YOUR_NAME_FOR_PROJECT
    $ cd Proyectos/YOUR_NAME_FOR_PROJECT
```
> Open browser and go to: http://localhost
 
## Access code drupal project in env-dev-d8 container

**The code is in src folder**
`If you created the project with sudo you can not access code, because the src folder will have root permissions`

## Change Dockerfile and recuild only env-dev-d8

```sh
    $ docker-compose build --force env-dev-d8
```

### Credits

| Codename | role |
| ------ | ------ |
| ocastano | Hannibal, team leader |
| nesta | Murdock, frontend head |
| dmarrufo | Baracus, backend brute force |
| lluvigne | Peck, backend pretty code |
