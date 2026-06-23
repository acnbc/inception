FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y nginx openssl gettext-base \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY conf/inception-nginx.conf.template /etc/nginx/nginx.conf.template

COPY --chmod=755 tools/nginx-init.sh /usr/local/bin/nginx-init.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-init.sh"]
