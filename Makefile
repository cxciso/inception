LOGIN    = ciso
DATA_DIR = /home/$(LOGIN)/data
SECRETS  = db_password db_root_password wp_admin_password wp_user_password
COMPOSE  = docker compose -f srcs/docker-compose.yml

all: up

setup:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@if [ ! -f srcs/.env ]; then \
		cp srcs/.env.example srcs/.env; \
		echo "srcs/.env created from srcs/.env.example"; \
	fi
	@mkdir -p secrets
	@for s in $(SECRETS); do \
		if [ ! -f secrets/$$s.txt ]; then \
			tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20 > secrets/$$s.txt; \
			echo "secrets/$$s.txt generated"; \
		fi; \
	done
	@grep -q "$(LOGIN).42.fr" /etc/hosts || \
		echo "WARNING: add '127.0.0.1 $(LOGIN).42.fr' to /etc/hosts (sudo)"

up: setup
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --rmi all --volumes

fclean: clean
	sudo rm -rf $(DATA_DIR)
	docker builder prune -af

re: fclean all

.PHONY: all setup up down start stop ps logs clean fclean re
