FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
	php-intl \
    php-mysql \
	php-opcache \
    php-curl \
    php-mbstring \
    php-xml \
    php-zip \
    php-gd \
    curl \
	wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html

COPY ./conf/inception-php-fpm.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /usr/src \
    && rm /tmp/wordpress.tar.gz

COPY ./conf/inception-wordpress.conf /etc/wordpress/wp-config.php

COPY --chmod=755 tools/wordpress-init.sh /usr/local/bin/wordpress-init.sh

ENTRYPOINT ["/usr/local/bin/wordpress-init.sh"]