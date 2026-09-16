FROM php:8.3-apache
RUN docker-php-ext-install pdo_mysql \
    && a2enmod rewrite \
    && sed -ri 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
COPY shared-hosting/public/ /var/www/html/
RUN mkdir -p /var/lib/raha-sync \
    && chown -R www-data:www-data /var/lib/raha-sync
