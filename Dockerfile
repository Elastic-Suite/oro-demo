FROM oroinc/orocommerce-application:5.1.0 as oro_dev

USER root
ARG UID
ARG GID

# Add repolist
COPY docker/yum.repolist /etc/yum.repos.d/oraclelinux.repo

RUN microdnf clean all \
    && microdnf -y makecache \
    && microdnf install composer

COPY docker/php.ini /etc/php.ini
COPY docker/php-cli.ini /etc/php-cli.ini

RUN usermod -u ${UID} www-data && groupmod -g ${GID} www-data
RUN rm -rf /run/php-fpm \
    && mkdir /run/php-fpm \
    && chown www-data:www-data /run/php-fpm /var/www/oro/var/cache /var/www/oro/var/data

EXPOSE 80

FROM oro_dev as oro_xdebug

USER root

RUN microdnf install php-pecl-xdebug

RUN echo "zend_extension=xdebug.so" > /etc/php.d/15-xdebug.ini && \
    echo "xdebug.mode=debug" >> /etc/php.d/15-xdebug.ini && \
    echo "xdebug.remote_enable=1" >> /etc/php.d/15-xdebug.ini && \
    echo "xdebug.remote_host=host.docker.internal" >> /etc/php.d/15-xdebug.ini && \
    echo "xdebug.remote_port=9003" >> /etc/php.d/15-xdebug.ini && \
    echo "opcache.enable=0" >> /etc/php.d/15-xdebug.ini

EXPOSE 9003
