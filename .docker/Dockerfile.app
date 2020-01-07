FROM php:7-fpm

# Set working directory for future docker commands
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y --quiet ca-certificates \
    build-essential \
    mariadb-client \
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
    iproute2 \
    libonig-dev \
    libmagickwand-dev

# Clear cache: keep the container slim
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

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

# Install composer: This could be removed and run in it's own container
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN echo "request_terminate_timeout = 3600" >> /usr/local/etc/php-fpm.conf
RUN echo "max_execution_time = 300" >> /usr/local/etc/php/php.ini

# Add user for laravel application
# NOTE: this requires the user on the host machine to be the same UID and GUI
#       find out by running `id` in a terminal on the host
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Make sure permissions match host and container
RUN chown www:www -R /var/www

# # Change current user to www
USER www
