###############################################################################
# BASE
###############################################################################
# Install all the OS level packages required for the project
###############################################################################
FROM php:7-fpm as base

# Set working directory for future docker commands
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y --quiet ca-certificates \
    build-essential \
    libpng-dev \
    libxml2-dev \
    libxrender1 \
    wkhtmltopdf \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    libzip-dev \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    curl \
    libmcrypt-dev \
    msmtp \
    libonig-dev \
    libmagickwand-dev \
    iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions: Some extentions are better installed using this method than apt in docker
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install \
    pdo_mysql \
    exif \
    pcntl \
    xml \
    soap \
    bcmath \
    gd \
    zip

# Install Imagick
RUN pecl install -o -f imagick \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable imagick

# Install Redis
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

###############################################################################
# COMPOSER
###############################################################################
# Install composer dependencies
###############################################################################
FROM base as composer

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY ./composer.json /var/www/composer.json
# By NOT copying composer.lock, packages are free to update to their latest
# versions, following DevOps break quickly, fix quickly.
# COPY ./composer.lock /var/www/composer.lock
RUN composer install --no-dev --no-scripts --no-autoloader

COPY . /var/www

RUN composer install --no-dev
RUN composer dump-autoload -o

###############################################################################
# php-config
###############################################################################
# Do any PHP setup/config changes
###############################################################################
FROM base as php-config

# increase execution timeout
RUN echo "request_terminate_timeout = 3600" >> /usr/local/etc/php-fpm.conf
RUN echo "max_execution_time = 300" >> /usr/local/etc/php/php.ini

# Add PHP unit alias (assuming it's in the vendor directory like with Laravel)
RUN echo 'alias phpunit="vendor/bin/phpunit"' >> /etc/bash.bashrc

###############################################################################
# xdebug
###############################################################################
FROM base as xdebug

RUN pecl install xdebug

RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.default_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port = 9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey = VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_log = /tmp/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && docker-php-ext-enable xdebug

###############################################################################
# FPM
###############################################################################
# Create the PHP-FPM container
###############################################################################
FROM xdebug as fpm

# Add user for laravel application
# NOTE: this requires the user on the host machine to be the same UID and GUI
#       find out by running `id` in a terminal on the host
ARG UID
RUN echo "Setting docker user ID to $UID"
RUN groupadd -g $UID www
RUN useradd -u $UID -ms /bin/bash -g www www

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=php-config /usr/local/etc /usr/local/etc
COPY --from=php-config /etc/bash.bashrc /etc/bash.bashrc
COPY --from=composer /var/www /var/www

# Make sure permissions match host and container
RUN chown www:www -R /var/www

# # Change current user to www
USER www
