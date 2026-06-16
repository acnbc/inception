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

WORKDIR /var/www/html

COPY ./conf/inception-php-fpm.conf 

RUN wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar -xzf /tmp/wordpress.tar.gz -C /tmp
    cp -rn /tmp/wordpress/* /var/www/html || true
    rm -rf /tmp/wordpress
