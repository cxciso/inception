# User documentation

## What this stack provides

| Service | Role | Reachable from outside? |
|---|---|---|
| **nginx** | Web server, HTTPS entry point (TLS 1.2/1.3) | Yes, port **443** only |
| **wordpress** | The website (WordPress + php-fpm) | No, only through nginx |
| **mariadb** | The database of the website | No, only from wordpress |

## Start and stop the project

From the root of the repository:

```bash
make          # build (if needed) and start everything
make stop     # stop the containers without removing them
make start    # start them again
make down     # stop and remove the containers (website and database are kept)
```

The first start takes a few minutes (images are built and WordPress is downloaded).

## Access the website and the admin panel

1. Make sure `/etc/hosts` contains: `127.0.0.1 ciso.42.fr`
2. Website: **https://ciso.42.fr**
3. Administration panel: **https://ciso.42.fr/wp-admin**

The certificate is self-signed, so the browser shows a warning:
click *Advanced* then *Accept the risk and continue*. This is expected.

`http://ciso.42.fr` (port 80) does not work on purpose: only HTTPS is allowed.

## Credentials

| Account | User name | Password |
|---|---|---|
| WordPress administrator | value of `WP_ADMIN_USER` in `srcs/.env` | `secrets/wp_admin_password.txt` |
| WordPress user (author) | value of `WP_USER` in `srcs/.env` | `secrets/wp_user_password.txt` |
| Database user | value of `MYSQL_USER` in `srcs/.env` | `secrets/db_password.txt` |
| Database root | `root` | `secrets/db_root_password.txt` |

Read a password with, for example: `cat secrets/wp_admin_password.txt`

If a secret file is missing, `make` generates a random password for it.
To change a password before the first start, edit the file in `secrets/`.
These files are never committed to git.

## Check that the services are running

```bash
make ps                     # the 3 containers must be "Up", mariadb "(healthy)"
make logs                   # follow the logs of the 3 services (Ctrl+C to quit)
docker logs wordpress       # logs of one service
```

Quick checks:

```bash
curl -k https://ciso.42.fr          # returns the HTML of the website
docker exec -it mariadb mariadb -u wpuser -p wordpress -e "SHOW TABLES;"
```
