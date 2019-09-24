FROM php:7.3-fpm

# Install base libs
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        jq \
        openssh-client \
        wget \
        git \
        libmemcached-dev \
        libz-dev \
        libpq-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        libssl-dev \
        libxml2-dev \
        libedit-dev \
        libc-client-dev \
        libkrb5-dev \
        libzookeeper-mt-dev \
        libpcre3-dev \
        libzip-dev \
        gcc \
        make \
        re2c \
        gettext-base \
        && \
    rm -r /var/lib/apt/lists/*

## Install PHP core modules
RUN docker-php-ext-install \
    soap \
    zip \
    ftp \
    sockets \
    bcmath \
    mbstring \
    pcntl \
    readline \
    posix \
    sysvmsg \
    sysvsem \
    sysvshm

# Install gd
RUN docker-php-ext-configure gd \
        --enable-gd-native-ttf \
        --with-jpeg-dir=/usr/lib \
        --with-freetype-dir=/usr/include/freetype2 && \
    docker-php-ext-install gd

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install pdo_mysql

# Install the PHP pdo_pgsql extention
RUN docker-php-ext-install pdo_pgsql

## Install Redis
RUN pecl install redis-5.0.2 && \
    docker-php-ext-enable redis

## Install Memcached
RUN pecl install memcached \
    && docker-php-ext-enable memcached

## Install IMAP
RUN docker-php-ext-configure imap --with-imap-ssl --with-kerberos && \
	docker-php-ext-install imap

## Install Zookeeper
RUN curl -L -o /tmp/zookeeper.tar.gz https://github.com/php-zookeeper/php-zookeeper/archive/v0.4.0.tar.gz \
    && mkdir -p /tmp/zookeeper \
    && tar xfz /tmp/zookeeper.tar.gz -C /tmp/zookeeper --strip-components=1 \
    && rm -r /tmp/zookeeper.tar.gz \
    && docker-php-ext-install /tmp/zookeeper \
    && rm -r /tmp/zookeeper

## Install Opcache
RUN docker-php-ext-install opcache && \
    docker-php-ext-enable opcache

# Install composer and add its bin to the PATH.
RUN curl -s http://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Install Phalcon
RUN curl -fsSL 'https://github.com/phalcon/cphalcon/archive/v3.4.4.tar.gz' -o phalcon.tar.gz \
    && mkdir -p phalcon \
    && tar -xf phalcon.tar.gz -C phalcon --strip-components=1 \
    && rm phalcon.tar.gz \
    && cd phalcon/build \
    && ./install \
    && cd ../../ \
    && rm -r phalcon \
    && docker-php-ext-enable phalcon

# Install New Relic Agent
RUN curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-9.1.0.246-linux.tar.gz \
    | tar -C /tmp -zx \
    && export NR_INSTALL_USE_CP_NOT_LN=1 \
    && export NR_INSTALL_SILENT=1 \
    && /tmp/newrelic-php5-*/newrelic-install install \
    && rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* \
    && rm -f /usr/local/etc/php/conf.d/newrelic.ini
COPY newrelic.ini.template /usr/local/etc/php/conf.d/newrelic.ini.template

# Set up entrypoint script to regenerate new relic config at container start
COPY entrypoint.sh /usr/local/bin
RUN chmod a=rx /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]