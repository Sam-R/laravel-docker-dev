###############################################################################
# BASE
###############################################################################
# Install all the OS level packages required for the project
###############################################################################
FROM php:8-fpm as base

# Set working directory for future docker commands
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y --quiet \
    ca-certificates \
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
    redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable imagick \
    redis

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

RUN composer install --no-dev && \
    composer dump-autoload -o

###############################################################################
# php-config
###############################################################################
# Do any PHP setup/config changes
###############################################################################
FROM base as php-config

# increase execution timeout and
# Add PHP unit alias (assuming it's in the vendor directory like with Laravel)
RUN echo "request_terminate_timeout = 3600" >> /usr/local/etc/php-fpm.conf && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/php.ini && \
    echo 'alias phpunit="vendor/bin/phpunit"' >> /etc/bash.bashrc

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
    # && echo 'xdebug.profiler_enable = 1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    # && echo 'xdebug.profiler_output_name = "cachegrind.out.%c"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    # && echo 'xdebug.profiler_output_dir = "/tmp"' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    # && echo 'xdebug.profiler_enable_trigger = 1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && docker-php-ext-enable xdebug

###############################################################################
# FPM
###############################################################################
# Create the PHP-FPM container
###############################################################################
FROM xdebug as fpm

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=php-config /usr/local/etc /usr/local/etc
COPY --from=php-config /etc/bash.bashrc /etc/bash.bashrc
COPY --from=composer /var/www /var/www

# Add user for laravel application
# and make sure permissions match host and container
# NOTE: this requires the user on the host machine to be the same UID and GUI
#       find out by running `id` in a terminal on the host
ARG UID=1000
RUN groupadd -g ${UID} www && \
    useradd -u ${UID} -ms /bin/bash -g www www && \
    chown www:www -R /var/www

# Change current user to www
USER www
