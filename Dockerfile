FROM oroinc/orocommerce-application:5.1.0 as oro_dev

USER root
ARG UID
ARG GID

# Add repolist
COPY docker/yum.repolist /etc/yum.repos.d/oraclelinux.repo

RUN microdnf clean all \
    && microdnf -y makecache \
    && microdnf install composer

# Install npm
RUN touch ~/.bashrc \
    && mkdir /var/nvm /usr/share/httpd/.npm\
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | NVM_DIR="/var/nvm" bash \
    && source ~/.bashrc \
    && nvm install 18.20.6 \
    && npm install -g npm@9.3.1 \
    && chmod a+x /var/nvm/versions/node/v18.20.6/bin/* \
    && ln -s /var/nvm/versions/node/v18.20.6/bin/node /usr/bin/node \
    && ln -s /var/nvm/versions/node/v18.20.6/bin/npm /usr/bin/npm \
    && chmod a+wx -R /usr/share/httpd/.npm

COPY docker/php.ini /etc/php.ini
COPY docker/php-cli.ini /etc/php-cli.ini

RUN usermod -u ${UID} www-data && groupmod -g ${GID} www-data
RUN rm -rf /run/php-fpm \
    && mkdir /run/php-fpm \
    && chown www-data:www-data -R /run/php-fpm /var/www/oro/var /var/www/oro/public

USER www-data

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

USER www-data

EXPOSE 9003
