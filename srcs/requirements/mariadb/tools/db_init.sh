#!/bin/bash
set -e

DATADIR="/var/lib/mysql"

# First boot only: volume is empty
if [ ! -d "$DATADIR/mysql" ]; then
	echo "Initializing MariaDB..."

	mariadb-install-db --user=mysql --datadir="$DATADIR" > /dev/null

	# Start temporarily to run SQL
	mariadbd --user=mysql --daemonize

	# Wait until server accepts connections
	until mariadb-admin ping --silent; do
		sleep 1
	done

	# Fresh install: root connects via socket without password
	mariadb -uroot <<-EOSQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
	EOSQL

	mariadb-admin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi

exec mariadbd --user=mysql