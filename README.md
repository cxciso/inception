*This project has been created as part of the 42 curriculum by ciso.*

# Inception

## Description

Inception is a system administration project about Docker. The goal is to build a small web
infrastructure where each service runs in its own container, all orchestrated with Docker
Compose and started from a single Makefile, inside a virtual machine.

The stack includes:

- **NGINX**: the only entry point, on port 443, with TLSv1.2/TLSv1.3 only
- **WordPress**: the website, run by php-fpm (no web server in this container)
- **MariaDB**: the database used by WordPress

Every image is built from my own Dockerfile based on `debian:bookworm` (penultimate stable
Debian). No ready-made image is pulled from Docker Hub, except the Debian base image.

The data is kept in two named volumes stored in `/home/ciso/data`, and the containers talk to
each other on a private Docker network (no `network: host`, no `links`).

## Instructions

### Prerequisites

- A Linux VM (Debian 12)
- Docker Engine and the Docker Compose plugin
- `make`
- `127.0.0.1 ciso.42.fr` in `/etc/hosts`

### Setup

```bash
git clone git@github.com:cxciso/inception.git
cd inception
make
```

`make` creates the data folders, copies `srcs/.env.example` to `srcs/.env`, generates the
missing passwords in `secrets/`, then builds and starts everything (see `DEV_DOC.md`).

Then open **https://ciso.42.fr** (accept the self-signed certificate warning).
Admin panel: **https://ciso.42.fr/wp-admin**.

### Makefile targets

| Target | Description |
| --- | --- |
| `make` | Prepare folders, `.env` and secrets, build the images and start the containers |
| `make down` | Stop and remove the containers (data is kept) |
| `make stop` / `make start` | Stop / start the existing containers |
| `make ps` | Show the containers of the project |
| `make logs` | Follow the logs of all containers |
| `make clean` | `down` + remove the images and Docker volumes |
| `make fclean` | `clean` + delete the data in `/home/ciso/data` and the build cache |
| `make re` | `fclean` + `make` |

## Project description

### Docker usage and included sources

Each service has its own folder in `srcs/requirements/` with a `Dockerfile`, a config file
(`conf/`) and a start script (`tools/setup.sh`). `srcs/docker-compose.yml` defines the
services, the network, the volumes and the secrets.

| Service | Role | Port |
| --- | --- | --- |
| nginx | HTTPS entry point, serves static files, sends PHP to php-fpm | 443 (published) |
| wordpress | php-fpm runs WordPress, installed with WP-CLI | 9000 (internal) |
| mariadb | Database server | 3306 (internal) |

### Design choices

- **No `latest` tag**: all images use `debian:bookworm`, so builds are reproducible.
- **Passwords in Docker secrets**, other settings in `.env`; both are ignored by git.
- **PID 1**: each start script ends with `exec`, so the real service is PID 1, runs in the foreground and receives the signals. No `tail -f` or infinite loop.
- **Restart policy**: `restart: always` restarts a container if it crashes.
- **First start only**: the scripts only create what is missing, so a restart never reinstalls anything.
- **Healthcheck on MariaDB**: WordPress starts only when the database accepts connections.

### Virtual Machines vs Docker

| Aspect | Virtual Machine | Docker Container |
| --- | --- | --- |
| Isolation | Full virtual computer with its own kernel | Process isolated by the kernel (namespaces, cgroups) |
| Resources | Heavy, a full OS each time | Light, shares the host kernel |
| Boot time | Minutes | Seconds |
| Use case | Different OS, strong isolation | One service per container |

Here the VM is the host, and each service runs in a container inside it.

### Secrets vs Environment Variables

| Aspect | Environment variables (`.env`) | Docker secrets |
| --- | --- | --- |
| Where | Variables in the container | Files in `/run/secrets/` |
| Visible with `docker inspect` | Yes | No |
| Given to | Every container using the `.env` | Only the containers that need them |
| Used for | Domain, database name, user names | Passwords |

### Docker Network vs Host Network

| Aspect | Custom bridge network | Host network |
| --- | --- | --- |
| Isolation | Containers on a private network | Container uses the host network directly |
| Ports | Only published ports are reachable | Every opened port is open on the host |
| DNS | Containers find each other by name | Must use localhost or IPs |

This project uses the bridge network `inception`: nginx reaches `wordpress:9000`, WordPress
reaches `mariadb:3306`, and only port 443 is published.

### Docker Volumes vs Bind Mounts

| Aspect | Named volumes | Bind mounts |
| --- | --- | --- |
| Managed by | Docker (`docker volume ls`, `inspect`, `rm`) | Not managed, just a host path |
| Used in a service by | Its name | A host path |
| Location | Chosen by the volume driver | The given host path |

This project uses two **named volumes** (`mariadb_data`, `wordpress_data`). With the `local`
driver options, their data is stored in `/home/ciso/data/mariadb` and
`/home/ciso/data/wordpress`, as the subject requires.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)
- [Secrets in Compose](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX: configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)

### AI usage

AI (Claude by Anthropic) was used during this project for the following tasks:

- **Debugging Dockerfile issues**: I was learning a new syntax and config files, and I ran into issues I sometimes could not find answers to online.
- **NGINX configuration**: same thing, I sometimes asked for explanations when I didn't really understand the documentation.
- **README and documentation**: made it prettier ✨💖
- **Comparisons and explanations**: clarifying Docker concepts (volumes, networks) for the documentation.

AI also provided a base for the configuration files (Dockerfiles, scripts), which I then tested
and validated manually on my VM.
