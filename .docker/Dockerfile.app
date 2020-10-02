FROM php:7-fpm

# Set working directory for future docker commands
WORKDIR /var/www/html

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

# Xdebug
# Note that "host.docker.internal" is not currently supported on Linux. This nasty hack tries to resolve it
# Source: https://github.com/docker/for-linux/issues/264
RUN ip -4 route list match 0/0 | awk '{print $3" host.docker.internal"}' >> /etc/hosts

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

# Install Redis, Imagick xDebug (Optional, but reccomended) and clear temp files
RUN pecl install -o -f redis \
    imagick \
    xdebug \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis \
    imagick \
    xdebug

# Install composer: This could be removed and run in it's own container
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# xdebug.remote_connect_back = true does NOT work in docker
RUN echo '\n\
[Xdebug]\n\
xdebug.remote_enable=true\n\
xdebug.remote_autostart=true\n\
xdebug.remote_port=9000\n\
xdebug.remote_host=docker.host.internal\n'\
>> /usr/local/etc/php/php.ini

RUN echo "request_terminate_timeout = 3600" >> /usr/local/etc/php-fpm.conf
RUN echo "max_execution_time = 300" >> /usr/local/etc/php/php.ini

# Xdebug
# Note that "host.docker.internal" is not currently supported on Linux. This nasty hack tries to resolve it
# Source: https://github.com/docker/for-linux/issues/264
#RUN ip -4 route list match 0/0 | awk '{print $3" host.docker.internal"}' >> /etc/hosts
RUN ip -4 route list match 0/0 | awk '{print "xdebug.remote_host="$3}' >> /usr/local/etc/php/php.ini

# Add user for laravel application
# NOTE: this requires the user on the host machine to be the same UID and GUI
#       find out by running `id` in a terminal on the host
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Make sure permissions match host and container
RUN chown www:www -R /var/www/html

# # Change current user to www
USER www

# Copy in a custom PHP.ini file
# INCOMPLETE/UNTESTED
#COPY source /usr/local/etc/php/php.ini

# We should do this as a command once the container is up.
# Leaving here incase someone wants to enable it here...
#RUN composer install && composer dump-autoload -o
