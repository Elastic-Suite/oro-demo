FROM oraclelinux:8 as builder

RUN dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf install -y \
    https://rpms.remirepo.net/enterprise/remi-release-8.rpm

RUN dnf module reset -y php && \
    dnf module enable -y php:remi-8.4

RUN dnf install -y curl make php php-cli php-xdebug && \
    dnf clean all

FROM oroinc/orocommerce-application:6.1.0 as oro_install

USER root
ARG UID
ARG GID

COPY --from=builder /usr/bin/make /usr/bin/make

# Install npm
RUN touch ~/.bashrc \
    && mkdir -p /var/nvm /usr/share/httpd/.npm\
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | NVM_DIR="/var/nvm" bash \
    && source ~/.bashrc \
    && nvm install 22.9.0 \
    && chmod a+x /var/nvm/versions/node/v22.9.0/bin/* \
    && chmod a+wx -R /usr/share/httpd/.npm \
    && ln -s /var/nvm/versions/node/v22.9.0/bin/node /usr/bin/node \
    && ln -s /var/nvm/versions/node/v22.9.0/bin/npm /usr/bin/npm \
    && ln -s /var/nvm/versions/node/v22.9.0/bin/npx /usr/bin/npx

RUN usermod -u ${UID} www-data && groupmod -g ${GID} www-data
RUN mkdir -p /home/www-data /run/php-fpm /var/log/nginx/ /var/www/oro/public /var/www/oro/var/cache /var/www/oro/var/logs /var/www/oro/node_modules /opt/oro-nginx
RUN chown www-data:www-data -R /etc/security /home/www-data /run/php-fpm /var/log/nginx /var/www/oro/public /var/www/oro/var /var/www/oro/node_modules /opt/oro-nginx /opt/oro-nginx-tool
RUN chmod a+w -R /opt/oro-nginx /opt/oro-nginx-tool

WORKDIR /var/www/oro

EXPOSE 80

FROM oroinc/runtime:6.1-latest as oro_dev

USER root
ARG UID
ARG GID

RUN usermod -u ${UID} www-data && groupmod -g ${GID} www-data
RUN mkdir -p /home/www-data /run/php-fpm /var/log/nginx/ /var/www/oro/public /var/www/oro/var/cache /var/www/oro/var/logs /opt/oro-nginx /var/www/oro/node_modules
RUN chown www-data:www-data -R /home/www-data /var/log/nginx /opt/oro-nginx /var/www/oro/node_modules

WORKDIR /var/www/oro

USER www-data

EXPOSE 80

FROM oro_dev as oro_xdebug

USER root

COPY --from=builder /usr/lib64/php/modules/xdebug.so /usr/lib64/php/modules/xdebug.so
RUN echo "zend_extension=xdebug.so" > /etc/php.d/15-xdebug.ini && \
    echo "xdebug.mode=debug" >> /etc/php.d/15-xdebug.ini && \
    echo "xdebug.client_host=host.docker.internal" >> /etc/php.d/15-xdebug.ini && \
    echo "xdebug.client_port=9003" >> /etc/php.d/15-xdebug.ini && \
    echo "opcache.enable=0" >> /etc/php.d/15-xdebug.ini

USER www-data

EXPOSE 9003
