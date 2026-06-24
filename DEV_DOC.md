# DEV_DOC.md — Developer Documentation

This document describes how to set up, build, run, and maintain the **Inception** project from scratch.

## Overview

The project implements a web stack with three Docker services:

| Service     | Image                    | Role                                      |
|-------------|--------------------------|-------------------------------------------|
| `mariadb`   | `inception-mariadb:1.0`  | MariaDB database                          |
| `wordpress` | `inception-wordpress:1.0`| WordPress with PHP-FPM and WP-CLI         |
| `nginx`     | `inception-nginx:1.0`    | Web server with HTTPS (port 443)          |

Services communicate over an internal bridge network (`inception`). Only NGINX exposes port `443` to the host.

---

## Prerequisites

### Operating system

- **Debian** (or a distribution compatible with the Docker installation script).
- `sudo` access to install packages and configure Docker.

### Software

| Tool            | Purpose                                              |
|-----------------|------------------------------------------------------|
| Docker Engine   | Building and running containers                      |
| Docker Compose  | Service orchestration (`docker compose`)             |
| Make            | Shortcuts for build, deploy, and tests               |
| `curl`          | HTTPS connectivity tests (`test-nginx` target)       |

### Docker installation

The repository root includes `install-docker-repo.sh`, which:

1. Adds the official Docker repository for Debian.
2. Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`.
3. Adds the current user to the `docker` group.

```bash
chmod +x install-docker-repo.sh
./install-docker-repo.sh
```

After installation, **restart your session** (or run `newgrp docker`) for the `docker` group permissions to take effect.

### Local DNS entry

The domain set in `DOMAIN_NAME` (e.g. `anogueir.42.fr`) must resolve to `127.0.0.1` on the host:

```bash
echo "127.0.0.1 <DOMAIN_NAME>" | sudo tee -a /etc/hosts
```

Replace `<DOMAIN_NAME>` with the value configured in the `.env` file.

---

## Environment setup

### 1. Environment file (`srcs/.env`)

Copy the template and fill in the variables:

```bash
cp srcs/.env.example srcs/.env
```

| Variable               | Description                                            |
|------------------------|--------------------------------------------------------|
| `DATADIR`              | Internal MariaDB path (`/var/lib/mysql`)               |
| `MYSQL_DATABASE`       | Database name                                          |
| `MYSQL_USER`           | Database user                                          |
| `DOMAIN_NAME`          | Site domain (must match `/etc/hosts`)                  |
| `WORDPRESS_TITLE`      | WordPress site title                                   |
| `WORDPRESS_ADMIN_USER` | WordPress administrator login                          |
| `WORDPRESS_ADMIN_EMAIL`| Administrator email                                    |
| `WORDPRESS_USER2_LOGIN`| Second user login (project requirement)                |
| `WORDPRESS_USER2_EMAIL`| Second user email                                      |
| `WORDPRESS_DB_HOST`    | Database host (`mariadb` — service name)               |
| `WORDPRESS_DB_NAME`    | Database name (same as `MYSQL_DATABASE`)               |

> The `srcs/.env` file is listed in `.gitignore` and **must not be committed**.

### 2. Secrets (`secrets/`)

Create four text files in the `secrets/` folder at the repository root. Each file must contain **only the password**, with no extra spaces or trailing newlines:

| File                            | Purpose                                                |
|---------------------------------|--------------------------------------------------------|
| `secrets/credentials.txt`       | WordPress administrator password                       |
| `secrets/db_password.txt`       | MariaDB user password (`MYSQL_USER`)                   |
| `secrets/db_root_password.txt`  | MariaDB root password                                  |
| `secrets/wp_user2_password.txt` | Second WordPress user password                         |

Example:

```bash
mkdir -p secrets
echo "my_admin_password"    > secrets/credentials.txt
echo "my_db_password"       > secrets/db_password.txt
echo "my_root_password"     > secrets/db_root_password.txt
echo "my_user2_password"    > secrets/wp_user2_password.txt
chmod 600 secrets/*.txt
```

Secrets are mounted at `/run/secrets/` inside containers via Docker Compose Secrets — they are **not** passed as environment variables.

> All files in `secrets/` are listed in `.gitignore` and **must not be committed**.

### 3. Persistent data directories

`docker-compose.yml` uses **bind mounts** to persist data on the host. Before the first launch:

1. Edit `srcs/docker-compose.yml` and adjust the volume `device` paths for your user:

```yaml
volumes:
  mariadb_data:
    driver_opts:
      device: /home/<login>/data/mariadb

  wordpress_data:
    driver_opts:
      device: /home/<login>/data/wordpress
```

2. Create the directories on the host:

```bash
mkdir -p /home/<login>/data/mariadb
mkdir -p /home/<login>/data/wordpress
```

Replace `<login>` with your 42 login.

### 4. Automatic checks

The `make check` target (run before `up` and `build`) validates:

- `srcs/docker-compose.yml` exists
- `srcs/.env` exists
- All four files in `secrets/` exist
- No `:latest` tag in Dockerfiles or the compose file

---

## Build and launch

All commands below must be run **from the repository root**.

### Build and start the stack

```bash
make        # equivalent to: make up
make up     # checks prerequisites, builds images, and starts containers
```

`make up` runs internally:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env -p inception up -d --build
```

### Build images only

```bash
make build
```

### Rebuild with forced container recreation

```bash
make rebuild
```

---

## Container management

| Command        | Description                                              |
|----------------|----------------------------------------------------------|
| `make start`   | Start stopped containers (no rebuild)                    |
| `make stop`    | Stop containers without removing them                    |
| `make down`    | Stop and remove containers and network                   |
| `make restart` | `make down` followed by `make up`                        |
| `make ps`      | List container status                                    |
| `make logs`    | Follow logs from all services (`-f`)                     |

### Direct Docker Compose commands

If you prefer Compose without the Makefile:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env -p inception ps
docker compose -f srcs/docker-compose.yml --env-file srcs/.env -p inception logs -f nginx
docker compose -f srcs/docker-compose.yml --env-file srcs/.env -p inception exec wordpress bash
```

### Cleanup

| Command       | Description                                                                 |
|---------------|-----------------------------------------------------------------------------|
| `make clean`  | Remove orphan containers (`down --remove-orphans`)                          |
| `make fclean` | Remove containers, volumes, project images, and run `docker system prune -af` |
| `make re`     | `make fclean` followed by `make all` (full reset)                           |

> **Warning:** `make fclean` removes Docker volumes associated with the project. Because volumes are bind mounts, data on the host (`/home/<login>/data/`) **remains** on disk, but the association is removed. For a full data reset, manually delete the directories under `data/`.

---

## Tests

The Makefile includes verification targets:

```bash
make test            # runs all tests below
make test-mariadb    # database connection and SHOW DATABASES
make test-wordpress  # PHP-FPM running and PHP → MariaDB connection
make test-nginx      # NGINX config validation + HTTPS request to the domain
```

The NGINX test uses `curl` with `--resolve` to force domain resolution to `127.0.0.1`.

---

## Data persistence

### Where data is stored

| Data              | Host path                        | Container path      | Service(s)           |
|-------------------|----------------------------------|---------------------|----------------------|
| MariaDB database  | `/home/<login>/data/mariadb`     | `/var/lib/mysql`    | `mariadb`            |
| WordPress files   | `/home/<login>/data/wordpress`   | `/var/www/html`     | `wordpress`, `nginx` |

### How persistence works

- The `mariadb_data` and `wordpress_data` volumes in `docker-compose.yml` are configured with `driver: local` and `type: none` + `o: bind` — **bind mounts** that map host directories into containers.
- MariaDB initializes the database only on first run (marker file `.inception-init-done` in `/var/lib/mysql`).
- WordPress copies files to the volume on first run and installs the core via WP-CLI if not already installed.
- The `wordpress_data` volume is shared between `wordpress` (write) and `nginx` (read/static serving).

### Secrets and runtime configuration

| Type            | Mechanism                          | Example                                      |
|-----------------|------------------------------------|----------------------------------------------|
| Secrets         | Docker Secrets → `/run/secrets/`   | `db_password`, `credentials`                 |
| Configuration   | Environment variables (`.env`)     | `DOMAIN_NAME`, `MYSQL_DATABASE`              |

---

## Relevant repository structure

```
inception/
├── Makefile                          # Build, deploy, and test commands
├── install-docker-repo.sh            # Docker installation (Debian)
├── secrets/                          # Passwords (not versioned)
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_user2_password.txt
└── srcs/
    ├── .env                          # Environment variables (not versioned)
    ├── .env.example                  # Configuration template
    ├── docker-compose.yml            # Services, volumes, and network definition
    └── requirements/
        ├── mariadb/                  # Dockerfile, config, and init script
        ├── nginx/                    # Dockerfile, NGINX template, and init
        └── wordpress/                # Dockerfile, PHP-FPM, wp-config, and init
```

---

## Service startup flow

```
mariadb   →  initialize DB (first run) → mariadbd
    ↓
wordpress → copy files → wait for MariaDB → install WP → php-fpm
    ↓
nginx     → generate SSL cert → render config → nginx (HTTPS:443)
```

1. **MariaDB** (`db_init.sh`): installs the database, creates users and database, then starts `mariadbd`.
2. **WordPress** (`wordpress-init.sh`): copies WordPress to the volume, sets up `wp-config.php`, waits for the database, installs the site and creates the second user, then starts PHP-FPM on port `9000`.
3. **NGINX** (`nginx-init.sh`): generates a self-signed certificate for `DOMAIN_NAME`, renders the config template, and starts NGINX in the foreground on port `443`.

---

## Troubleshooting

| Issue                                 | Check / solution                                                |
|---------------------------------------|-----------------------------------------------------------------|
| `Missing srcs/.env`                   | Copy `srcs/.env.example` to `srcs/.env` and fill it in          |
| `Missing secrets/...`                 | Create the four secret files in the `secrets/` folder           |
| Container restarting in a loop        | `make logs` — check permissions on the `data/` directories     |
| Site unreachable in the browser       | Confirm `/etc/hosts` entry and that port 443 is available       |
| Certificate error in the browser      | Expected — the certificate is self-signed; accept the exception |
| `:latest tag found` during check      | Always use fixed tags (e.g. `1.0`) in Dockerfiles and compose   |
