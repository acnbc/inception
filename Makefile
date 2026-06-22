NAME := inception

COMPOSE_FILE ?= srcs/docker-compose.yml
ENV_FILE ?= srcs/.env
CREDENTIALS_FILE=secrets/credentials.txt
DB_PASSWORD_FILE=secrets/db_password.txt
DB_ROOT_PASSWORD_FILE=secrets/db_root_password.txt
COMPOSE ?= docker compose
COMPOSE_RUN := $(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME)

.PHONY: all up down start stop restart build rebuild clean fclean re ps logs check \
	test test-mariadb test-wordpress test-nginx

all: up

up: check
	$(COMPOSE_RUN) up -d --build

down: check-compose
	$(COMPOSE_RUN) down

start: check-compose
	$(COMPOSE_RUN) start

stop: check-compose
	$(COMPOSE_RUN) stop

restart: down up

build: check
	$(COMPOSE_RUN) build

rebuild: check
	$(COMPOSE_RUN) up -d --build --force-recreate

clean: check-compose
	$(COMPOSE_RUN) down --remove-orphans

fclean: check-compose
	$(COMPOSE_RUN) down --volumes --remove-orphans --rmi all
	docker system prune -af

re: fclean all

ps: check-compose
	$(COMPOSE_RUN) ps

logs: check-compose
	$(COMPOSE_RUN) logs -f

test: check-compose
	@$(MAKE) test-mariadb
	@$(MAKE) test-wordpress
	@$(MAKE) test-nginx

test-mariadb: check-compose
	@echo "==> Testing MariaDB connection..."
	@$(COMPOSE_RUN) exec -T mariadb \
		bash -c 'mariadb -h127.0.0.1 -u"$$MYSQL_USER" -p"$$(cat /run/secrets/db_password)" -e "SHOW DATABASES;"'
	@echo "MariaDB: OK"

test-wordpress: check-compose
	@echo "==> Testing WordPress (PHP-FPM + MariaDB)..."
	@$(COMPOSE_RUN) exec -T wordpress \
		bash -c 'pgrep -f php-fpm >/dev/null'
	@$(COMPOSE_RUN) exec -T wordpress \
		bash -c 'php -r '"'"'$$m=new mysqli(getenv("WORDPRESS_DB_HOST"),getenv("MYSQL_USER"),trim(file_get_contents("/run/secrets/db_password")),getenv("MYSQL_DATABASE")); if ($$m->connect_error) { fwrite(STDERR, $$m->connect_error . PHP_EOL); exit(1); } echo "DB connection OK\n";'"'"''
	@echo "WordPress: OK"

test-nginx: check-compose
	@echo "==> Testing NGINX..."
	@$(COMPOSE_RUN) exec -T nginx nginx -t
	@curl -fkfsS --resolve anogueir.42.fr:443:127.0.0.1 https://anogueir.42.fr/ -o /dev/null
	@echo "NGINX: OK"

check: check-compose check-env check-secrets

check-compose:
	@test -f $(COMPOSE_FILE) || (echo "Missing $(COMPOSE_FILE). Create the mandatory Inception compose file first." && exit 1)

check-env:
	@test -f $(ENV_FILE) || (echo "Missing $(ENV_FILE). Create it from your mandatory environment variables/secrets." && exit 1)

check-secrets:
	@test -f $(CREDENTIALS_FILE) || (echo "Missing $(CREDENTIALS_FILE)." && exit 1)
	@test -f $(DB_PASSWORD_FILE) || (echo "Missing $(DB_PASSWORD_FILE)." && exit 1)
	@test -f $(DB_ROOT_PASSWORD_FILE) || (echo "Missing $(DB_ROOT_PASSWORD_FILE)." && exit 1)