# Run Oro Application Demo in Docker

## How to use this env

```shell
git clone git@github.com:Elastic-Suite/oro-demo.git
cd oro-demo
docker compose run --rm php-fpm-app bash -c "source ~/.bashrc; composer install"
mkdir src/public/media
sudo chown ubuntu:ubuntu -R src
docker compose up install
docker compose up -d
```

Add gally plugin
```shell
cd oro-demo
git clone git@github.com:Elastic-Suite/gally-oro-connector.git src/packages/GallyPlugin
docker compose exec php-fpm-app composer repositories.gally-connector '{ "type": "path", "url": "./packages/GallyPlugin", "options": { "versions": { "gally/oro-plugin": "2.0.0"}} }'
docker compose exec php-fpm-app composer require gally/oro-plugin:2.0.0
```

Add oro enterprise packages
```shell
cd oro-demo
docker compose exec php-fpm-app composer require oro/commerce-enterprise:5.1.0 oro/platform-enterprise:5.1.0
```

Use static analysis tools
```shell
bin/php-cs-fixer fix --diff packages/GallyPlugin/
bin/phpstan --memory-limit=1G analyse -c packages/GallyPlugin/phpstan.neon
bin/phpunit --config phpunit.xml.dist packages/GallyPlugin/ --stop-on-fail
```
Create/edit js files
```shell
docker compose exec php-fpm-app bin/console oro:assets:install --relative-symlink # Only required once on js creation
docker compose exec php-fpm-app bin/console oro:assets:build --watch
```

## How this env was build

```shell
git clone https://github.com/oroinc/docker-demo.git oro-demo
git checkout a790d44727fb25411687199dca89f4864e793fdf # last commit before oro 6.0
rm -rf .git
git init
git remote add origiin git@github.com:Elastic-Suite/oro-demo.git

docker compose up install
docker compose up -d
docker compose cp php-fpm-app:/var/www/oro/ ./
mv oro src

# Add user id / group id in .env
```

