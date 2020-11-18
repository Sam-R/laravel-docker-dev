# Docker Laravel

A docker-compose environment for simple PHP/MySQL development. Setup for Laravel by default.

Runs PHP 7.4. For PHP 7.2 checkout the `php-7.2` branch.

| Service | URL |
| --- | --- |
| Your website | http://localhost:8080 |
| Horizon | http://localhost:8080/horizon |
| Telescope | http://localhost:8080/telescope |
| MailHog | http://localhost:8025 |
| -XDebug- | -port 9000- |


## Setup

clone this repository to your local machine:

```
git clone git@github.com:Sam-R/laravel-docker-dev.git
```

move into the project directory

```
cd laravel-docker-dev
```

setup a new Laravel codebase in the src folder

```
sudo docker run --rm --user $(id -u):$(id -g) -v $(pwd):/app composer create-project --prefer-dist laravel/laravel src
```

Make sure to setup and environment variables in the Laravel `src/.env`

Bring up the docker-compose environment (building the PHP containers)

```
sudo docker-compose up -d --build
```

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

If you get permissions errors on files, check your user ID on the host by running `id` in a terminal. The dockerfile is set to `1000`, if yours doesn't match, change the `docker-compose.yml` doing a search for "UID" and changing it to match your ID.

```
      args:
        - UID=1000 # change to be your new UID
```

There are multiple entries for this, so make sure you update all of them! You'll then need to run `sudo docker-compose up -d --build` to rebuild the PHP container with the new UID.


> **NOTE**: You may want to remove all the _*existing*_ repository information with `find . | grep "\.git/" | xargs rm -rf`, otherwise your git commands may work against this repository instead of your own!


### Database credentials

I am using Laravel 6.x and need to edit settings in my `.env` file to match `docker-compose.yml`. I change the following settings:

```
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### Artisan commands

You can run artisan and composer commands from inside the PHP container. `sudo docker-compose exec -it php /bin/bash` will connect a persistent console. Use `php artisan migrate` to test the database connection is established (you may have to edit your `.env` file in your laravel project to match this setup).

### Mailhog

To use mailhog, you need to setup your laravel `.env` file as follows:

```
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_FROM_ADDRESS=test@example.com
MAIL_FROM_NAME="${APP_NAME}"
```

Other `MAIL` lines should not be required and may cause errors, it's suggested you remove them.

## Horizon and Telescope

### Install Horizon

```
sudo docker-compose exec -it php composer require laravel/horizon
sudo docker-compose exec -it php php artisan horizon:install
sudo docker-compose exec -it php php artisan migrate
```

http://localhost:8080/horizon


### install Telescope

```
# Dev flag used for safety; you don't want to run _default_ telescope in production!
sudo docker-compose exec -it php composer require laravel/telescope --dev
sudo docker-compose exec -it php php artisan telescope:install
sudo docker-compose exec -it php php artisan migrate
php artisan telescope:publish
```

http://localhost:8080/telescope


### XDebug

XDebug is setup to talk to port 9001 on the docker host machine. You'll need to configure your IDE to accept connections on port 9001.

I'd suggest using PHPStorm or a free IDE like Visual Studio Code https://code.visualstudio.com/docs/languages/php with the PHP Debug pluging: https://marketplace.visualstudio.com/items?itemName=felixfbecker.php-debug Other options include Netbeans and Eclipse. Sublime text and Atom also have limted XDebug capabilities.

Under debug on visual studio code (left hand bar) click "add configuration". This is my complete configuration file:

```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for XDebug",
            "type": "php",
            "request": "launch",
            "port": 9001,
            "log": true,
            "externalConsole": false,
            "pathMappings": {
                "/var/www": "${workspaceFolder}/src"
            },
            "ignore": [
                "**/vendor/**/*.php"
            ]
        },
        {
            "name": "Launch currently open script",
            "type": "php",
            "request": "launch",
            "program": "${file}",
            "cwd": "${fileDirname}",
            "port": 9001
        }
    ]
}
```

You must change your container settings in `.docker/Dockerfile.app` and `docker-compose.yml`

#### Dockerfile.app changes

In `Dockerfile.app`, look for the following lines:

```
    && echo "xdebug.remote_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
```
If you're on Mac or windows, you may need to change this line to reflect your OS, EG `docker.for.mac.host.internal`

```
    && echo "xdebug.remote_port = 9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
```

if you are using a different port for xdebug, change this line

```
    && echo "xdebug.idekey = VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
```
and if you're using a different IDE you'll need to update the IDE KEY to match yours, EG `PHPSTORM`

#### docker-compose.yml

You may need to update the docker-compose.yml file with a different IP address for `host.docker.internal` on the php container

```
    extra_hosts:
      - "host.docker.internal:172.17.0.1"
```

I found this by running `ip -4 route list match 0/0 | awk '{print $3}'` while inside the nginx docker container:

```
docker-compose exec nginx sh

/ # ip -4 route list match 0/0 | awk '{print $3}'
172.17.0.1
```
and using that value to update the `docker-compose.yml` file, then rebuilding the stack using `docker-compose up -d --build`

### Xdebug Profiler

You can enable xdebug's profiler by amending the `Dockerfile.app` and uncommenting the lines under xdebug, as below.

You may want to update the output name for the profiled documents.

```
###############################################################################
# xdebug
###############################################################################
FROM base as xdebug

RUN pecl install xdebug \
    && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.default_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port = 9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey = VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_log = /tmp/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    # XDEBUG Profiling
    && echo 'xdebug.profiler_enable = 1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.profiler_output_name = "cachegrind.out.%c"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.profiler_output_dir = "/tmp"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.profiler_enable_trigger = 1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && docker-php-ext-enable xdebug
```

> **NOTE**: the `profiler_output_dir` must be mounted in the docker-compose.yml file in order to be visible by your profiling tool

Now change the `docker-compose.yml` file to add mount points for `/tmp` under any PHP container you wish to profile.

```
      # OPTIONAL: add the xdebug profiler path.
      # This requires you to edit the Dockerfile.app and uncomment the profiler options
      - ./xdebug-profiler:/tmp
```

finally rebuild the stack `sudo docker-compose up -d --build` to apply the changes

> **NOTE**: the xdebug profiler can generate large files, so make sure you disable it when you don't need it and keep the folder size in check through manual deletion

## Removing containers/resetting database

Docker can persist volumes. Make sure they're removed if changing the database (eg renaming it):

Stop the docker containers
`sudo docker-compose down`

Delete all volumes from stopped containers
`sudo docker-compose rm -v`

