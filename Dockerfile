FROM php:7.2-fpm

RUN apt-get update \
 && apt-get install -y \
      gnupg \
 && curl http://nginx.org/keys/nginx_signing.key | apt-key add - \
 && echo "deb http://nginx.org/packages/debian/ stretch nginx" > /etc/apt/sources.list.d/nginx.list \
 && echo "deb-src http://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
 && apt-get update \
 && apt-get install -y \
      nginx \
      supervisor \
 && rm -rf /var/lib/apt/lists/* \
 && chown -R nginx:nginx /var/cache/nginx \
 && chmod -R 0777 /var/cache/nginx \
 && ln -sf /proc/1/fd/1 /var/log/nginx/access.log \
 && ln -sf /proc/1/fd/2 /var/log/nginx/error.log

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 && echo "date.timezone=UTC" | tee /usr/local/etc/php/conf.d/date.ini \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git \
      libfreetype6-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      zlib1g-dev \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && docker-php-ext-install -j$(nproc) \
      bcmath \
      exif \
      intl \
      gd \
      pdo \
      pdo_mysql \
      zip \
 && rm -rf /var/lib/apt/lists/*

RUN docker-php-source extract \
 && mkdir -p /tmp/xdebug \
 && curl -o - -L https://github.com/xdebug/xdebug/archive/master.tar.gz | tar xvzf - -C /tmp/xdebug --strip-components=1 \
 && cd /tmp/xdebug \
 && phpize \
 && ./configure --enable-xdebug \
 && make \
 && make install \
 && echo "[xdebug]" | tee -a /usr/local/etc/php/conf.d/xdebug.ini \
 && echo "zend_extension=xdebug.so" | tee -a /usr/local/etc/php/conf.d/xdebug.ini \
 && echo "xdebug.idekey=PHPSTORM" | tee -a /usr/local/etc/php/conf.d/xdebug.ini \
 && echo "xdebug.remote_autostart=on" | tee -a /usr/local/etc/php/conf.d/xdebug.ini \
 && echo "xdebug.remote_enable=on" | tee -a /usr/local/etc/php/conf.d/xdebug.ini \
 && echo "xdebug.remote_host=192.168.99.1" | tee -a /usr/local/etc/php/conf.d/xdebug.ini \
 && cd /tmp \
 && rm -rf /tmp/xdebug \
 && docker-php-source delete

COPY ops/docker-compose/app/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY ops/docker-compose/app/supervisor/supervisor.conf /etc/supervisor/conf.d/supervisor.conf

ENV XDEBUG_CONFIG "idekey=PHPSTORM"
ENV PHP_IDE_CONFIG "serverName=sylius.local"

RUN apt-get update \
 && apt-get install -y apt-transport-https \
 && curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo "deb https://deb.nodesource.com/node_8.x stretch main" > /etc/apt/sources.list.d/nodesource.list \
 && echo "deb-src https://deb.nodesource.com/node_8.x stretch main" >> /etc/apt/sources.list.d/nodesource.list \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update \
 && apt-get install -y \
      nodejs \
      yarn \
 && rm -rf /var/lib/apt/lists/*

RUN usermod -u 1000 www-data

WORKDIR /app

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n"]
