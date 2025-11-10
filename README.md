# Demo oro environment

## How to use this environment

* Clone oro demo repo:
    ```shell
    git clone git@github.com:Elastic-Suite/oro-demo.git connectors/oro
    cd connectors/oro
    ```

* Edit .env file and update the value of :

| Var                 | Description                           | Example value                                                                        |
|---------------------|---------------------------------------|--------------------------------------------------------------------------------------|
| `UID`               | Your user id                          | 1000                                                                                 |
| `GID`               | Your group id                         | 1000                                                                                 |
| `ORO_APP_DOMAIN`    | The oro domain you want to use        | oro.connector.localhost                                                              |
| `GALLY_SERVER_NAME` | The server name you defined for gally | gally.connector.local                                                                |
| `GALLY_DSN`         | The gally DSN                         | gally://admin\@example.com:apassword@gally.connector.local:443?path=api&check_ssl=0  |

* Install composer dependencies
    ```shell
    docker compose run --rm install composer config github-oauth.github.com [Your Token]
    docker compose run --rm install composer install
    ```

* Add gally plugin
    ```shell
    git clone git@github.com:Elastic-Suite/gally-oro-connector.git src/packages/GallyPlugin
    docker compose run --rm install composer config repositories.gally-connector '{ "type": "path", "url": "./packages/GallyPlugin", "options": { "versions": { "gally/oro-plugin": "2.0.0"}} }'
    docker compose run --rm install composer require gally/oro-plugin:2.0.0
    ```

* Start your traefik if it is not already running
* Install Oro

    ```shell
    docker compose up install
    docker compose run --rm install npm install
    docker compose up -d
    ```
  > After this step you should have a running oro instance
  > * Backend: https://oro.connector.localhost/admin
  > * Frontend: https://oro.connector.localhost/

* Use static analysis tools
  ```shell
  bin/php-cs-fixer fix --diff packages/GallyPlugin/
  bin/phpstan --memory-limit=1G analyse -c packages/GallyPlugin/phpstan.neon
  bin/phpunit --config phpunit.xml.dist packages/GallyPlugin/ --stop-on-fail
  ```
* Create/edit js files
  ```shell
  docker compose exec php-fpm-app bin/console oro:assets:install --relative-symlink # Only required once on js creation
  docker compose exec php-fpm-app bin/console oro:assets:build --watch
  ``` 

## Prod mode

In prod mode you can generate certificates in a ./certs dir with 
```shell
openssl req -x509 -nodes -newkey rsa:2048 -keyout certs/key.pem -out certs/cert.pem -sha256 -days 365     -subj "/C=GB/ST=London/L=London/O=Alros/OU=IT Department/CN=localhost"
```

## How this env was build

```shell
git clone https://github.com/oroinc/docker-demo.git oro-demo
git checkout 6.0
rm -rf .git
git init
git remote add origiin git@github.com:Elastic-Suite/oro-demo.git

# Create a auth.json file with oro gituhb token (cf vault)
composer create-project oro/commerce-crm-enterprise-application src 6.0.2 --repository=https://packagist.oroinc.com
# Add user id / group id in .env
```

