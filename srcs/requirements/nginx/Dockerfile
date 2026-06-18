FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y nginx \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/home

COPY conf/inception-nginx.conf /etc/nginx/nginx.conf

COPY tools/nginx-init.sh /usr/local/bin/nginx-init.sh

RUN chmod +x ngnix-init.sh

ENTRYPOINT ["/usr/local/bin/nginx-init.sh"]
