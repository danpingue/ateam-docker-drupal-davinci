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
  - Node
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

- Install last docker-compose version (current version: 1.17.0)
  ```sh
  $ sudo rm /usr/local/bin/docker-compose

  $ sudo curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

  $ sudo chmod +x /usr/local/bin/docker-compose
  ```

## Customomise docker-compose.yml
- Set DRUPAL_PROJECT to your default project name

## Run containers

- Clone project and go to project folder 

- Build images
  ```sh
  $ docker-compose build
  ```

- Run images
  ```sh
  $ docker-compose up
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

### Root access (general project with default name in docker-compose.yml)
    
```sh
$ docker exec -it env-dev-d8 bash

$ cd /

$ ./create-drupal-project.sh

$ cd /var/www/$DRUPAL_PROJECT
```

> Open browser and go to: http://localhost


### Developer access and custom project name

```sh
$ docker exec -u YOUR_DEVELOPER_NAME -it env-dev-d8 bash

$  ./create-user-drupal-project.sh YOUR_NAME_FOR_PROJECT

$ cd Proyectos/YOUR_NAME_FOR_PROJECT
```

> Open browser and go to: http://localhost


## Access code drupal project in env-dev-d8 container

**The code is in src folder**

`If you created the project with sudo you can not access code, because the src folder will have root permissions`

## Change Dockerfile and rebuild only env-dev-d8

```sh
$ docker-compose build --force env-dev-d8
```

## Delete all docker images and containers

```sh
# Stop all containerrs
$ docker stop $(docker ps -q)
# Delete all containers
$ docker rm $(docker ps -a -q)
# Delete all images
$ docker rmi $(docker images -q)
```


### ATeam - Credits

| Codename | Role |
| ------   | ------ |
| ocastano | Hannibal, fullstack, team leader |
| nefta    | Murdock, frontend, crazy head    |
| dmarrufo | Baracus, backend, brute force    |
| lluvigne | Peck, backend, pretty code       |
