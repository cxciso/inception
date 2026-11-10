# Developer documentation

## Set up the environment from scratch

### Prerequisites

- A Linux virtual machine (tested on Debian 12).
- Docker Engine and the Docker Compose plugin (`docker compose version`).
- Your user in the `docker` group: `sudo usermod -aG docker $USER`, then log out and in (or reboot).
- `make` and `git`.
- The domain name pointing to the machine:
  ```bash
  echo "127.0.0.1 ciso.42.fr" | sudo tee -a /etc/hosts
  ```

### Configuration files and secrets

Both are ignored by git and must exist locally:

- `srcs/.env`: non-sensitive configuration (domain, database name, user names, emails).
  Copied from `srcs/.env.example` by `make` if missing.
- `secrets/`: one file per password, used as Docker secrets:
  `db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`, `wp_user_password.txt`.
  Generated randomly by `make` if missing; you can also write them yourself:
  ```bash
  mkdir -p secrets && echo "myPassword" > secrets/db_password.txt
  ```

The admin user name (`WP_ADMIN_USER`) must not contain "admin" or "administrator".

## Build and launch

```bash
make            # = make up: setup + docker compose up -d --build
```

`make setup` creates `/home/ciso/data/mariadb` and `/home/ciso/data/wordpress`
(the volumes need these folders to exist), creates `.env` and missing secrets, and warns if
`/etc/hosts` is not configured. Then `docker compose -f srcs/docker-compose.yml up -d --build`
builds the three images from their Dockerfiles and starts the containers.

Start order: `mariadb` → (healthcheck OK) → `wordpress` → `nginx`.

## Makefile targets

| Target | Action |
|---|---|
| `make` / `make up` | setup, build and start |
| `make down` | stop and remove containers and network |
| `make stop` / `make start` | stop / restart existing containers |
| `make ps` | status of the containers |
| `make logs` | follow all logs |
| `make clean` | `down` + remove images and Docker volumes (files in `/home/ciso/data` stay) |
| `make fclean` | `clean` + delete `/home/ciso/data` (sudo) + clear the build cache |
| `make re` | `fclean` then `make` |

## Useful commands

```bash
docker compose -f srcs/docker-compose.yml ps          # containers of the project
docker compose -f srcs/docker-compose.yml build nginx # rebuild one image
docker exec -it wordpress bash                         # open a shell in a container
docker logs -f mariadb                                 # follow one service's logs
docker images                                          # mariadb, wordpress, nginx (tag "inception")
docker network ls / docker network inspect inception   # the private network
docker volume ls                                       # inception_mariadb_data, inception_wordpress_data
docker volume inspect inception_mariadb_data           # "device": "/home/ciso/data/mariadb"
docker exec -it wordpress wp user list --allow-root    # WordPress users
docker exec -it mariadb mariadb -u root -p             # MariaDB as root (password in secrets/)
```

## Where the data is stored and how it persists

| Volume | Mounted in | Stored on the host |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` (mariadb) | `/home/ciso/data/mariadb` |
| `wordpress_data` | `/var/www/html` (wordpress and nginx) | `/home/ciso/data/wordpress` |

They are named volumes (`local` driver) whose `driver_opts` point to `/home/ciso/data`.
Removing or rebuilding the containers does not touch these folders.

On start, each `setup.sh` checks what already exists:
- mariadb: if `/var/lib/mysql/mysql` exists, the system tables are already there; if
  `/var/lib/mysql/<database>` exists, the database and users are already created.
- wordpress: if `wp-config.php` exists, WordPress is already installed.

So after a restart, a `make down && make`, or a reboot of the VM, everything comes back as it was.
Only `make fclean` deletes the data.

## Project structure

```
srcs/requirements/<service>/
├── Dockerfile      # how the image is built (FROM debian:bookworm)
├── conf/           # configuration file copied into the image
└── tools/setup.sh  # entrypoint: first-start initialization, then exec of the service (PID 1)
```
