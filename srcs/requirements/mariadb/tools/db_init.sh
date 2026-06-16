#!/bin/bash
set -e

DATADIR="/var/lib/mysql"
INIT_MARKER="${DATADIR}/.inception-init-done"

mkdir -p /var/log/mysql /run/mysqld
chown -R mysql:mysql /var/log/mysql /run/mysqld

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

run_init_sql() {
	mariadbd --user=mysql &
	mariadbd_pid=$!

	until mariadb-admin ping --silent; do
		sleep 1
	done

	mariadb -uroot <<-EOSQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
		FLUSH PRIVILEGES;
	EOSQL

	mariadb-admin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
	wait "${mariadbd_pid}" 2>/dev/null || true
}

if [ ! -f "${INIT_MARKER}" ]; then
	echo "Initializing MariaDB..."

	if [ ! -d "${DATADIR}/mysql" ]; then
		mariadb-install-db --user=mysql --datadir="${DATADIR}" > /dev/null
	fi

	run_init_sql
	touch "${INIT_MARKER}"
	chown mysql:mysql "${INIT_MARKER}"
fi

exec mariadbd --user=mysql