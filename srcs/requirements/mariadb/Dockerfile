FROM debian:bookworm-slim

RUN apt update && apt install -y mariadb-server \
	&& apt autoclean && rm -rf /var/lib/apt/lists/*

COPY conf/mariadb.conf.d/inception-mariadb.cnf \
	/etc/mysql/mariadb.conf.d/inception-mariadb.cnf

COPY tools/db_init.sh ./db_init.sh

RUN chmod +x /db_init.sh

ENTRYPOINT ["/db_init.sh"]