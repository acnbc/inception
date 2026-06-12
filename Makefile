NAME := inception

LOGIN ?= $(USER)
DATA_DIR ?= /home/$(LOGIN)/data
WORDPRESS_DATA_DIR ?= $(DATA_DIR)/wordpress
MARIADB_DATA_DIR ?= $(DATA_DIR)/mariadb

COMPOSE_FILE ?= srcs/docker-compose.yml
ENV_FILE ?= srcs/.env
COMPOSE ?= docker compose

.PHONY: all up down start stop restart build rebuild clean fclean re ps logs prepare check

all: up

up: prepare check
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) up -d --build

down: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) down

start: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) start

stop: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) stop

restart: down up

build: prepare check
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) build

rebuild: prepare check
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) up -d --build --force-recreate

clean: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) down --remove-orphans

fclean: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) down --volumes --remove-orphans --rmi all
	rm -rf $(WORDPRESS_DATA_DIR) $(MARIADB_DATA_DIR)
	docker system prune -af

re: fclean all

ps: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) ps

logs: check-compose
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(NAME) logs -f

prepare:
	mkdir -p $(WORDPRESS_DATA_DIR) $(MARIADB_DATA_DIR)

check: check-compose check-env

check-compose:
	@test -f $(COMPOSE_FILE) || (echo "Missing $(COMPOSE_FILE). Create the mandatory Inception compose file first." && exit 1)

check-env:
	@test -f $(ENV_FILE) || (echo "Missing $(ENV_FILE). Create it from your mandatory environment variables/secrets." && exit 1)