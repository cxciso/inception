*This project has been created as part of the 42 curriculum by ciso.*

# Inception

## Description

Inception is a system administration project: it sets up a small web infrastructure made of
three services, each running in its own Docker container, inside a virtual machine.

- **NGINX**: the only entry point, on port 443, with TLSv1.2/TLSv1.3 only.
- **WordPress + php-fpm**: the website (PHP is executed by php-fpm, without any web server inside).
- **MariaDB**: the database used by WordPress.

The containers talk to each other through a private Docker network, and their data is kept in
two named volumes stored in `/home/ciso/data` on the host, so nothing is lost when the
containers are removed or the machine reboots.

```
browser --443 (TLS 1.2/1.3)--> nginx --9000 (FastCGI)--> wordpress --3306--> mariadb
                                 |                           |                  |
                                 +----- wordpress_data ------+            mariadb_data
                                    /home/ciso/data/wordpress      /home/ciso/data/mariadb

            (nginx, wordpress and mariadb are on the private network "inception")
```

### Use of Docker and sources included

Every image is built from our own Dockerfile, starting from `debian:bookworm`
(the penultimate stable Debian). No ready-made image (nginx, wordpress, mariadb...) is pulled.

```
.
├── Makefile                      # builds and runs everything through docker compose
├── secrets/                      # passwords (Docker secrets), ignored by git
└── srcs/
    ├── .env                      # non-sensitive configuration, ignored by git
    ├── .env.example              # template of .env
    ├── docker-compose.yml        # services, network, volumes, secrets
    └── requirements/
        ├── mariadb/   Dockerfile, conf/my.conf, tools/setup.sh
        ├── wordpress/ Dockerfile, conf/www.conf, tools/setup.sh
        └── nginx/     Dockerfile, conf/nginx.conf.template, tools/setup.sh
```

Each container starts a `setup.sh` script that prepares the service on first start
(database and users, WordPress installation, TLS certificate) and then uses `exec` so that the
real service (`mysqld`, `php-fpm`, `nginx`) becomes PID 1 and runs in the foreground.
No `tail -f`, `sleep infinity` or infinite loop is used.

### Main design choices

- **Debian bookworm** as base image: well documented, same packages everywhere.
- **Initialization scripts are idempotent**: they only create things that do not exist yet,
  so a restart never reinstalls anything and the data persists.
- **WP-CLI** installs and configures WordPress from the command line (no installation page).
- **Passwords are Docker secrets**, everything else is in `.env`.
- **The TLS certificate is generated when the container starts**, so no private key is stored in an image.
- **`restart: always`** restarts a container if its main process crashes.
- **Healthcheck on MariaDB**: WordPress only starts once the database accepts connections.

### Virtual Machines vs Docker

A virtual machine emulates a complete computer with its own kernel: it is heavy (GBs),
slow to boot, but strongly isolated. A Docker container is a normal process of the host,
isolated by the kernel (namespaces for what it can see, cgroups for what it can use). It shares
the host kernel, so it starts in a second and weighs a few MBs. Docker is ideal to package one
service with its dependencies; a VM is better when a full, different OS is needed.
In this project both are used: the VM is the host, the services run in containers inside it.

### Secrets vs Environment Variables

Environment variables (here from `.env`) are easy to use but visible to anyone who can run
`docker inspect`, and to every process in the container. They hold non-sensitive configuration
(domain name, database name, user names). Docker secrets are files mounted read-only in
`/run/secrets/` and given only to the containers that need them; they never appear in
`docker inspect` or in the image. They hold the passwords. Both `.env` and `secrets/` are
ignored by git.

### Docker Network vs Host Network

With `network: host`, a container shares the host network directly: no isolation, every port
it opens is open on the host. With a user-defined bridge network (`inception`), containers
get their own private network, can reach each other by service name thanks to Docker's
internal DNS (`mariadb:3306`, `wordpress:9000`), and nothing is reachable from outside except
the ports explicitly published (only `443` for nginx).

### Docker Volumes vs Bind Mounts

A bind mount maps any host path directly into a container and is not managed by Docker.
A named volume is created and managed by Docker (`docker volume ls`, `inspect`, `rm`) and can
be referred to by name by several containers. Here we use two **named volumes**
(`mariadb_data`, `wordpress_data`); with the `local` driver options we tell Docker to store
their data in `/home/ciso/data`, as required by the subject.

## Instructions

Prerequisites: a Linux VM with Docker Engine, the Docker Compose plugin, `make`, and
`127.0.0.1 ciso.42.fr` in `/etc/hosts`.

```bash
make            # creates data folders, .env and missing secrets, builds and starts everything
make ps         # status of the containers
make logs       # follow the logs
make down       # stop and remove the containers (data is kept)
make fclean     # remove everything, including the data (asks for sudo)
make re         # fclean + make
```

Then open **https://ciso.42.fr** (accept the self-signed certificate warning).
Admin panel: **https://ciso.42.fr/wp-admin**. See `USER_DOC.md` and `DEV_DOC.md` for details.

## Resources

- Docker documentation: https://docs.docker.com/ (Dockerfile reference, Compose file reference, secrets, volumes, networking)
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
- NGINX documentation: https://nginx.org/en/docs/ (ssl module, fastcgi module)
- MariaDB knowledge base: https://mariadb.com/kb/en/
- php-fpm configuration: https://www.php.net/manual/en/install.fpm.configuration.php
- WP-CLI commands: https://developer.wordpress.org/cli/commands/
- About PID 1 in containers: https://docs.docker.com/engine/containers/multi-service_container/

### Use of AI

AI (Claude) was used as a tutor and assistant for:
- explaining Docker concepts (images, containers, PID 1, networks, volumes, secrets);
- drafting the Dockerfiles, the initialization scripts and the `docker-compose.yml`, which
  were then read, tested and explained line by line;
- helping debug the VM setup (Docker group permissions, volume folders);
- drafting this README, `USER_DOC.md` and `DEV_DOC.md`.

Every file was reviewed and tested on the VM, and I can explain each line.
