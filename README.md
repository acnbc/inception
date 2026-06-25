*This project has been created as part of the 42 curriculum by anogueir.*

# Inception

## Description

**Inception** is a Docker-based infrastructure project from the 42 curriculum. Its goal is to deploy a small, self-contained web stack — MariaDB, WordPress, and NGINX — using custom Docker images built from **Debian Bookworm**.

The website is served over **HTTPS** on port 443. WordPress is automatically installed on first launch via WP-CLI, and all persistent data (database and site files) survives container restarts.

### Stack overview

| Service     | Image                    | Role                              |
|-------------|--------------------------|-----------------------------------|
| `mariadb`   | `inception-mariadb:1.0`  | MariaDB database                  |
| `wordpress` | `inception-wordpress:1.0`| WordPress + PHP-FPM + WP-CLI      |
| `nginx`     | `inception-nginx:1.0`    | Reverse proxy with TLS (HTTPS)    |

---

## Instructions

### Prerequisites

- Debian (or compatible Linux distribution)
- Docker Engine and Docker Compose plugin
- Make

See [DEV_DOC.md](DEV_DOC.md) for full setup instructions, including the `install-docker-repo.sh` script.

### Quick start

1. Copy and fill in the environment file:

   ```bash
   cp srcs/.env.example srcs/.env
   ```

2. Create the four password files in `secrets/` (see [DEV_DOC.md](DEV_DOC.md)).

3. Create data directories and update volume paths in `srcs/docker-compose.yml`.

4. Add a local DNS entry:

   ```bash
   echo "127.0.0.1 <DOMAIN_NAME>" | sudo tee -a /etc/hosts
   ```

5. Build and launch:

   ```bash
   make
   ```

6. Open `https://<DOMAIN_NAME>/` in your browser.

### Common commands

| Command        | Description                              |
|----------------|------------------------------------------|
| `make up`      | Build and start all services             |
| `make down`    | Stop and remove containers               |
| `make ps`      | Show container status                    |
| `make logs`    | Follow service logs                      |
| `make test`    | Run health checks on all services        |
| `make fclean`  | Full cleanup (containers, images, volumes) |

For day-to-day usage, see [USER_DOC.md](USER_DOC.md).  
For developer setup and troubleshooting, see [DEV_DOC.md](DEV_DOC.md).

---

## Project description

### Docker and project sources

Each service lives under `srcs/requirements/` with its own **Dockerfile**, configuration files, and entrypoint script:

```
srcs/
├── docker-compose.yml
├── .env / .env.example
└── requirements/
    ├── mariadb/    → MariaDB server + db_init.sh
    ├── wordpress/  → PHP-FPM, WordPress, WP-CLI + wordpress-init.sh
    └── nginx/      → NGINX with TLS + nginx-init.sh
```

All images are built from `debian:bookworm-slim` with **fixed version tags** (`1.0`) — the `:latest` tag is never used. Services are orchestrated with Docker Compose and managed through the root `Makefile`.

Sensitive values (passwords) are stored in `secrets/` and injected at runtime via **Docker Secrets** (`/run/secrets/`). Non-sensitive configuration (domain name, usernames, database name) is passed through `srcs/.env`.

### Main design choices

- **One process per container** — each service runs a single main process in the foreground (`mariadbd`, `php-fpm`, `nginx`).
- **Idempotent initialization** — MariaDB and WordPress setup scripts run only on first launch; subsequent restarts skip installation.
- **TLS termination at NGINX** — a self-signed certificate is generated at startup; only port 443 is exposed to the host.
- **Shared volume between WordPress and NGINX** — both containers mount the same `wordpress_data` volume so NGINX can serve static files while PHP-FPM handles dynamic requests.
- **Internal bridge network** — services communicate by name (`mariadb`, `wordpress`) without exposing the database or PHP-FPM ports to the host.

### Virtual Machines vs Docker

| | Virtual Machines | Docker |
|---|---|---|
| **Isolation** | Full OS per VM (kernel, init, services) | Process-level isolation sharing the host kernel |
| **Resource usage** | Heavy — each VM needs its own RAM, disk, and boot time | Lightweight — containers start in seconds and share resources |
| **Portability** | Requires a hypervisor and OS images | Images are portable and reproducible across hosts |
| **Use case here** | Would mean running 3 separate OS instances for 3 services | One host runs 3 lean containers, each with only what it needs |

Docker was chosen because the Inception stack needs three cooperating services, not three full operating systems. Containers provide sufficient isolation with far less overhead.

### Secrets vs Environment Variables

| | Environment Variables | Docker Secrets |
|---|---|---|
| **Visibility** | Visible in `docker inspect`, process lists, and logs | Mounted as files in `/run/secrets/`, not exposed as env vars |
| **Suitable for** | Non-sensitive config (domain, usernames, DB name) | Passwords and credentials |
| **Use case here** | `DOMAIN_NAME`, `MYSQL_DATABASE`, `WORDPRESS_ADMIN_USER` in `.env` | `db_password`, `credentials`, `db_root_password` in `secrets/` |

Passwords never appear in the `.env` file or in `docker inspect` output. The WordPress `wp-config.php` reads the database password directly from `/run/secrets/db_password` at runtime.

### Docker Network vs Host Network

| | Host Network | Bridge Network (chosen) |
|---|---|---|
| **Isolation** | Container shares the host's network stack directly | Container gets its own network namespace |
| **Port exposure** | All container ports are on the host by default | Only explicitly mapped ports reach the host |
| **Service discovery** | Must use `localhost` or host IPs | Services resolve each other by name (`mariadb`, `wordpress`) |
| **Use case here** | Would expose MariaDB (3306) and PHP-FPM (9000) on the host | Only NGINX port 443 is published; DB and PHP-FPM stay internal |

The `inception` bridge network keeps inter-service traffic isolated while allowing controlled external access through NGINX only.

### Docker Volumes vs Bind Mounts

| | Named Docker Volumes | Bind Mounts (chosen) |
|---|---|---|
| **Storage location** | Managed by Docker in `/var/lib/docker/volumes/` | Maps a host directory into the container |
| **Portability** | Docker handles path management | Requires an absolute host path in `docker-compose.yml` |
| **Visibility** | Data hidden inside Docker's storage | Data directly accessible on the host filesystem |
| **Use case here** | Would work but data location is opaque | Data stored at `/home/<login>/data/mariadb` and `/home/<login>/data/wordpress` as required by the subject |

Bind mounts are configured with `driver: local`, `type: none`, and `o: bind` so data persists in predictable host directories outside Docker's internal storage.

---

## Resources

### Documentation

- [Docker — Official documentation](https://docs.docker.com/)
- [Docker Compose — Official documentation](https://docs.docker.com/compose/)
- [MariaDB — Knowledge Base](https://mariadb.com/kb/en/documentation/)
- [WordPress — Developer documentation](https://developer.wordpress.org/)
- [WP-CLI — Command reference](https://developer.wordpress.org/cli/commands/)
- [NGINX — Beginner's guide](https://nginx.org/en/docs/beginners_guide.html)
- [PHP-FPM — Configuration](https://www.php.net/manual/en/install.fpm.php)

### AI usage

AI assistance (Cursor / Claude) was used during this project for the following tasks:

| Task | What was done |
|------|---------------|
| **Documentation** | Drafting and structuring `DEV_DOC.md`, `USER_DOC.md`, and `README.md` based on the project source code and subject requirements, except for the `README.md` description section, which was written based on the cadet annotations from courses, tutorials and readings |
| **Installation scripts** | Review and documentation of `install-docker-repo.sh` (Debian Docker CE setup), container entrypoints (`db_init.sh` — MariaDB first-run init and `mariadbd`; `wordpress-init.sh` — volume seeding, WP-CLI install, second user, PHP-FPM; `nginx-init.sh` — self-signed TLS cert and config render), and the root `Makefile` (Compose lifecycle, secrets/env validation, `:latest` guard, and `test-*` health checks) |
| **Code review** | Reviewing configuration choices (secrets, volumes, networking) and suggesting improvements to documentation clarity |

All Dockerfiles, entrypoint scripts, configuration files, and the Makefile were written and reviewed by the author. AI was not used to generate the core infrastructure code.
