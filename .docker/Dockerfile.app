FROM php:7.2-fpm

# Set working directory for future docker commands
WORKDIR /var/www/html

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    mariadb-client \
    libpng-dev \
    libxml2-dev \
    libxrender1 \
    wkhtmltopdf \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    curl \
    libmagickwand-dev

# Clear cache: keep the container slim
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions: Some extentions are better installed using this method than apt in docker
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl xml soap
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd
RUN pecl install imagick
RUN docker-php-ext-enable imagick

# Install composer: This could be removed and run in it's own container
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
# NOTE: this requires the user on the host machine to be the same UID and GUI
#       find out by running `id` in a terminal on the host
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Make sure permissions match host and container
RUN chown www:www -R /var/www/html

# # Change current user to www
USER www

# We should do this as a command once the container is up.
# Leaving here incase someone wants to enable it here...
#RUN composer install && composer dump-autoload -o
