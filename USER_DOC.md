# USER_DOC.md — User Documentation

This guide explains, in simple terms, how to use the **Inception** stack as an end user or administrator.

> **Note:** Initial setup (Docker installation, `.env`, secrets, and data directories) is covered in [DEV_DOC.md](DEV_DOC.md). This document assumes the project is already configured.

---

## What the stack provides

The project runs three services that work together:

| Service     | What it does                                                                 |
|-------------|------------------------------------------------------------------------------|
| **NGINX**   | Serves the website over **HTTPS** (secure connection on port 443).           |
| **WordPress** | Powers the website and its administration panel.                           |
| **MariaDB** | Stores all WordPress data (posts, users, settings). Not accessed directly.   |

From your perspective, you interact with:

- The **public website** — the WordPress front page.
- The **WordPress admin panel** — where you manage content, users, and settings.

The database runs in the background and does not need to be opened manually under normal use.

---

## Starting and stopping the project

All commands below are run **from the repository root**.

### Start the stack

```bash
make up
```

This builds the images (if needed) and starts all services in the background.

If the stack was previously stopped but containers still exist:

```bash
make start
```

### Stop the stack

To stop services without removing them:

```bash
make stop
```

To stop and remove the containers:

```bash
make down
```

### Restart the stack

```bash
make restart
```

---

## Accessing the website

### Public site

Open your browser and go to:

```
https://<DOMAIN_NAME>/
```

Replace `<DOMAIN_NAME>` with the domain configured in `srcs/.env` (e.g. `<login>.42.fr`).

> The domain must resolve to `127.0.0.1` on the machine where the stack is running (see [DEV_DOC.md](DEV_DOC.md) for the `/etc/hosts` entry).

Because the certificate is **self-signed**, your browser may show a security warning on first visit. This is expected — proceed to accept the exception and continue.

### Administration panel

The WordPress dashboard is available at:

```
https://<DOMAIN_NAME>/wp-admin
```

Log in with the administrator credentials (see below).

---

## Credentials

### Where credentials are stored

| Information              | Location                          |
|--------------------------|-----------------------------------|
| Usernames, emails, domain| `srcs/.env`                       |
| Passwords                | `secrets/` folder (text files)    |

Password files contain a single line with the password only.

### WordPress administrator

| Field      | Source                                      |
|------------|---------------------------------------------|
| Username   | `WORDPRESS_ADMIN_USER` in `srcs/.env`       |
| Password   | `secrets/credentials.txt`                     |
| Email      | `WORDPRESS_ADMIN_EMAIL` in `srcs/.env`      |

### Second WordPress user

The project creates a second user with the **author** role:

| Field      | Source                                      |
|------------|---------------------------------------------|
| Username   | `WORDPRESS_USER2_LOGIN` in `srcs/.env`      |
| Password   | `secrets/wp_user2_password.txt`             |
| Email      | `WORDPRESS_USER2_EMAIL` in `srcs/.env`      |

### Changing passwords

**WordPress passwords** can be changed in two ways:

1. **Via the admin panel** — log in at `/wp-admin`, go to *Users → Profile*, and set a new password.
2. **Via the secret files** — edit the corresponding file in `secrets/`, then restart the stack.  
   > Changing a secret file alone does **not** update an already-installed WordPress password. Use the admin panel for day-to-day changes, or reinstall the stack for a full reset.

**Database passwords** (`secrets/db_password.txt`, `secrets/db_root_password.txt`) are used internally by the services. Only change them if you know how to update the database accordingly (see [DEV_DOC.md](DEV_DOC.md)).

---

## Checking that services are running

### Quick status check

```bash
make ps
```

All three services (`mariadb`, `wordpress`, `nginx`) should show as **running** or **Up**.

### Automated health tests

```bash
make test
```

This runs three checks:

| Test              | What it verifies                                      |
|-------------------|-------------------------------------------------------|
| `test-mariadb`    | Database is reachable                                 |
| `test-wordpress`  | PHP-FPM is running and can connect to the database    |
| `test-nginx`      | NGINX configuration is valid and HTTPS responds       |

### Viewing logs

If something is not working, inspect the logs:

```bash
make logs
```

Press `Ctrl+C` to stop following the logs.

---

## Common issues

| Symptom                          | What to try                                                    |
|----------------------------------|----------------------------------------------------------------|
| Browser cannot reach the site    | Confirm the stack is running (`make ps`) and `/etc/hosts` is set |
| Certificate warning              | Expected with a self-signed cert — accept and continue         |
| Login fails                      | Check username in `.env` and password in `secrets/`           |
| Service keeps restarting         | Run `make logs` to find the error message                     |

For setup and troubleshooting details, refer to [DEV_DOC.md](DEV_DOC.md).
