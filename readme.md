# Docker Laravel

A docker-compose environment for simple PHP/MySQL development. Setup for Laravel by default.

## Basic Usage

Place your laravel project in `src`. (If you're just using PHP, you'll need to place your index file in `src/public`)

run `sudo docker-compose up -d` to start the environment. The first time around this will build the PHP dockerfile so it will take some time!

You should be able to navigate to `http://localhost:8080` to view your application.

If you get permissions errors on files, check your user ID on the host by running `id` in a terminal. The dockerfile is set to `1000`, if yours doesn't match, change the docker file `.docker/Dockerfile.app` to reflect your user id.

### Artisan commands

You can run artisan and composer commands from inside the PHP container. `sudo docker exec -it php-dev /bin/bash` will connect a persistent console. Use `php artisan migrate` to test the database connection is established (you may have to edit your `.env` file in your laravel project to match this setup).

## Removing containers/resetting database

Docker can persist volumes. Make sure they're removed if changing the database (eg renaming it):

Stop the docker containers
`sudo docker-compose down`

Delete all volumes from stopped containers
`sudo docker-compose rm -v`

