#!/bin/bash
set -e

HTML="/var/www/html"
WP_SRC="/usr/src/wordpress"
WP_CONFIG_SRC="/etc/wordpress/wp-config.php"
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/credentials)
WORDPRESS_USER2_PASSWORD=$(cat /run/secrets/db_password)
DOMAIN_NAME="anogueir.42.fr"

# 1. WordPress no volume (primeiro arranque)
if [ ! -f "${HTML}/index.php" ]; then
	echo "Copying WordPress files into volume..."
	cp -a "${WP_SRC}/." "${HTML}/"
fi

# 2. wp-config.php no volume (lê env + secret em runtime)
if [ ! -f "${HTML}/wp-config.php" ]; then
	echo "Copying wp-config.php..."
	cp "${WP_CONFIG_SRC}" "${HTML}/wp-config.php"
fi

# 3. Salts (o teu config não tem AUTH_KEY, etc.)
if ! grep -q "AUTH_KEY" "${HTML}/wp-config.php"; then
	wp config shuffle-salts --path="${HTML}" --allow-root
fi

# 4. Esperar MariaDB (ligação real, sem boot completo do WordPress)
until php -r '
  $m = @new mysqli(
    getenv("WORDPRESS_DB_HOST"),
    getenv("MYSQL_USER"),
    trim(file_get_contents("/run/secrets/db_password")),
    getenv("MYSQL_DATABASE")
  );
  exit($m->connect_error ? 1 : 0);
' 2>/dev/null; do
	echo "Waiting for MariaDB..."
	sleep 2
done
echo "MariaDB is ready."

# 5. Instalar WordPress (só uma vez)
if ! wp core is-installed --path="${HTML}" --allow-root 2>/dev/null; then
	echo "Installing WordPress..."
	wp core install \
		--path="${HTML}" \
		--url="https://${DOMAIN_NAME}" \
		--title="${WORDPRESS_TITLE}" \
		--admin_user="${WORDPRESS_ADMIN_USER}" \
		--admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
		--admin_email="${WORDPRESS_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root
fi

# 6. Segundo utilizador (requisito Inception)
if ! wp user get "${WORDPRESS_USER2_LOGIN}" --path="${HTML}" --allow-root 2>/dev/null; then
	echo "Creating second user..."
	wp user create \
		"${WORDPRESS_USER2_LOGIN}" \
		"${WORDPRESS_USER2_EMAIL}" \
		--role=author \
		--user_pass="${WORDPRESS_USER2_PASSWORD}" \
		--path="${HTML}" \
		--allow-root
fi

chown -R www-data:www-data "${HTML}"

# 7. PHP-FPM em foreground (liga ao listen 0.0.0.0:9000 do teu pool)
exec php-fpm8.2 -F