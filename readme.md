# Docker Laravel

A docker-compose environment for simple PHP/MySQL development. Setup for Laravel by default.

## Basic Usage


```
├── .docker                 # Docker files, includes and associated dockery things
├── docker-compose.yml      # the glue for this docker-compose magick
├── readme.md               # You're here!
└── src                     # Your Laravel project's code should be here
    └── public              # The default web directory, normal PHP code goes here if not using Laravel!

```
Place your laravel project in `src`. (If you're just using PHP, you'll need to place your index file in `src/public`)

run `sudo docker-compose up -d` to start the environment. The first time around this will build the PHP dockerfile so it will take some time!

You should be able to navigate to `http://localhost:8080` to view your application.

If you get permissions errors on files, check your user ID on the host by running `id` in a terminal. The dockerfile is set to `1000`, if yours doesn't match, change the docker file `.docker/Dockerfile.app` to reflect your user id.

**NOTE**: You may want to remove all the _*existing*_ repository information with `find . | grep "\.git/" | xargs rm -rf`, otherwise your git commands may work against this repository instead of your own!

### Exact steps I take

download, git clone or get the docker files to your local machine somehow and go into the directory.

run `composer create-project --prefer-dist laravel/laravel src` to create a new Laravel project in the `src` directory

I am using Laravel 6.x and need to edit settings in my `.env` file to match `docker-compose.yml`. I change the following settings:

```
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

run `docker-compose up -d` to create and run the containers.

I can now go to my browser and see the default Laravel welcome page.

I run `sudo docker exec -it php-dev bash` in a terminal so I can easily run my PHP artisan commands.

### Artisan commands

You can run artisan and composer commands from inside the PHP container. `sudo docker exec -it php-dev /bin/bash` will connect a persistent console. Use `php artisan migrate` to test the database connection is established (you may have to edit your `.env` file in your laravel project to match this setup).

## Horizon and Telescope

### Install Horizon

```
sudo docker exec -it php-dev composer require laravel/horizon
sudo docker exec -it php-dev php artisan horizon:install
sudo docker exec -it php-dev php artisan migrate
```

http://localhost:8080/horizon


### install Telescope

```
# Dev flag used for safety; you don't want to run _default_ telescope in production!
sudo docker exec -it php-dev composer require laravel/telescope --dev
sudo docker exec -it php-dev php artisan telescope:install
sudo docker exec -it php-dev php artisan migrate
php artisan telescope:publish
```

http://localhost:8080/telescope

## Removing containers/resetting database

Docker can persist volumes. Make sure they're removed if changing the database (eg renaming it):

Stop the docker containers
`sudo docker-compose down`

Delete all volumes from stopped containers
`sudo docker-compose rm -v`

