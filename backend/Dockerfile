#FROM php:8.0-apache
#
#RUN apt update \
#        && apt install -y \
#            g++ \
#            libicu-dev \
#            libpq-dev \
#            libzip-dev \
#            zip \
#            zlib1g-dev \
#        && docker-php-ext-install \
#            intl \
#            opcache \
#            pdo \
#            pdo_mysql \
#            mysqli \
#        && a2enmod rewrite
#
#COPY . /var/www/html/
#RUN chown -R www-data:www-data /var/www/html/storage
#COPY apache.conf /etc/apache2/sites-available/000-default.conf

FROM ubuntu:21.10

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt install -y \
            php \
            php-mysql \
            php-xml \
            php-curl \
            curl \
            git \
            unzip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY . /app
WORKDIR /app

RUN composer install

CMD ["php", "artisan", "serve", "--host=0.0.0.0"]

