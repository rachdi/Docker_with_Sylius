.PHONY: all
all: dev

.PHONY: dev
dev: sylius
	docker-compose up -d
	test -d sylius/vendor || (docker-compose exec app composer install -n)
	#sed -i -e 's/database_host.*/database_host: db/i' sylius/app/config/parameters.yml
	$(MAKE) permissions
	$(MAKE) .installed
	$(MAKE) permissions

sylius:
	(composer create-project sylius/sylius-standard sylius) || (git clone https://github.com/Sylius/Sylius.git sylius)

.PHONY: build
build:
	docker-compose build

.PHONY: ps
ps:
	docker-compose ps

.PHONY: up
up:
	docker-compose up -d

.PHONY: start
start:
	docker-compose start

.PHONY: stop
stop:
	docker-compose stop

.PHONY: permissions
permissions:
	mkdir -p sylius/var/cache/dev sylius/var/cache/prod sylius/var/logs
	chmod -R 0777 sylius/var/cache/dev sylius/var/cache/prod sylius/var/logs
	docker-compose exec app chown -R www-data:www-data var/cache var/logs

.PHONY: composer
composer:
	docker-compose exec app composer install -n

.PHONY: cache_clear
cache_clear:
	rm -rf sylius/var/cache/dev/* sylius/var/cache/prod/*

.PHONY: db_init
db_init:
	docker-compose exec app bin/console doctrine:schema:create

.PHONY: db
db:
	docker-compose exec app bin/console doctrine:schema:update --dump-sql -f

.installed:
	docker-compose exec app bin/console --env=prod sylius:install
	docker-compose exec app bin/console --env=dev sylius:install
	$(MAKE) yarn
	@touch .installed

.PHONY: yarn
yarn: up
	docker-compose exec app bash -c "yarn install && yarn run gulp"
