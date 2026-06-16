FROM debian:bookworm-slim

RUN apt update && apt install -y mariadb-server \
	&& apt autoclean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/mysql /run/mysqld \
    && chown -R mysql:mysql /var/log/mysql /run/mysqld \
    && chmod 755 /run/mysqld

COPY conf/mariadb.conf.d/inception-mariadb.cnf \
	/etc/mysql/mariadb.conf.d/inception-mariadb.cnf

COPY tools/db_init.sh /db_init.sh

RUN chmod +x /db_init.sh

ENTRYPOINT ["/db_init.sh"]