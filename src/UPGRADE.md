The upgrade instructions are available at [Oro documentation website](https://doc.oroinc.com/master/backend/setup/upgrade-to-new-version/).

This file includes only the most important items that should be addressed before attempting to upgrade or during the upgrade of a vanilla Oro application.

Please also refer to [CHANGELOG.md](CHANGELOG.md) for a list of significant changes in the code that may affect the upgrade of some customizations.

### 5.1.3

Fixed issue in Merge by Priority strategy optimization when pre-calculated CPL was used. 
It is recommended to rebuild CPL's if Merge by Priority strategy is used:

- Run sql query `DELETE FROM oro_price_list_combined; DELETE FROM oro_price_product_combined;`
- Run command `php bin/console oro:price-lists:schedule-recalculate --all`

### 5.1.0 RC

Added `.env-app` files support and removed most of the parameters from the config/parameters.yml in favor of environment variables with DSNs. For more details, see [the migration guide](https://doc.oroinc.com/master/backend/setup/dev-environment/env-vars/).

* The supported PHP version is 8.2
* The supported PostgreSQL version is 15
* The supported NodeJS version is 18
* The supported Redis version is 7
* The supported RabbitMQ version is 3.11
* The supported PHP MongoDB extension version is 1.15
* The supported MongoDB version is 6.0

Fixed scheduled price lists issue. It is recommended to rebuild CPL's:

- Run sql query `DELETE FROM oro_price_list_combined; DELETE FROM oro_price_product_combined;`
- Run command `php bin/console oro:price-lists:schedule-recalculate --all`

## 5.0.0

The `oro.email.update_visibilities_for_organization` MQ process can take a long time when updating from the old versions
if the system has many email addresses (in User, Customer user, Lead, Contact, RFP request, Mailbox entities).
During performance tests with 1M of email addresses, this process  took  approximately 10 minutes.

It is recommended to add these MQ topics to the `oro.index` queue:

- `oro.email.recalculate_email_visibility`
- `oro.email.update_visibilities`
- `oro.email.update_visibilities_for_organization`
- `oro.email.update_email_visibilities_for_organization`
- `oro.email.update_email_visibilities_for_organization_chunk`

## 5.0.0-rc

* The default database driver is `pdo_pgsql`.
* The supported PostgreSQL version is 13.0
* The supported NodeJS version is 16.0
* The supported RabbitMQ version is 3.9
* The supported PHP MongoDB extension version is 1.11.1
* The supported MongoDB version is 5.0

## 5.0.0-alpha.2

The minimum required PHP version is 8.0.0.

## 4.2.1

- The link at the calendar events search items was changed,
  please reindex calendar event items with command
  `php bin/console oro:search:reindex --class="Oro\Bundle\CalendarBundle\Entity\CalendarEvent"`
- Please note that some records in the ImportExportResult table may contain an incorrect value of the organization field. There is not enough data during migration to update these values to the correct ones.

## 4.2.0

* The minimum required PHP version is 7.4.14.
* The minimum supported PostgreSQL version is 12.0
* The search [algorithm](https://doc.oroinc.com/4.1/backend/bundles/platform/ElasticSearchBundle/configuration/#relevance-optimization) is now enabled by default. To use the search functionality after the upgrade, remove the search index and start full reindexation.

### Routing

The regular expressions in `fos_js_routing.routes_to_expose` and `oro_frontend.routes_to_expose` configuration parameters (see `config/config.yml`) have changed.

### Directory structure and filesystem changes

The `var/attachment` and `var/import_export` directories are no longer used for storing files and have been removed from the default directory structure.

All files from these directories must be moved to the new locations:
- from `var/attachment/protected_mediacache` to `var/data/protected_mediacache`;
- from `var/attachment` to `var/data/attachments`;
- from `var/import_export` to `var/data/importexport`;
- from `var/import_export/files` to `var/data/import_files`;
- from `var/import_export/product_images` to `var/data/import_files`.

The `public/uploads` directory has been removed.

The console command `oro:gaufrette:migrate-filestorages` will help to migrate the files to new structure.

## 4.1.0

- The minimum required PHP version is 7.3.13.
- The feature toggle for WEB API was implemented. After upgrade, the API feature will be disabled.
  To enable it please follow the documentation [Enabling an API Feature](https://doc.oroinc.com/api/enabling-api-feature/).
- Upgrade PHP before running `composer install` or `composer update`, otherwise composer may download wrong versions of the application packages.

## 3.1.0

The minimum required PHP version is 7.1.26.

Upgrade PHP before running `composer install` or `composer update`, otherwise composer may download wrong versions of the application packages.

## 1.6.0

* Changed minimum required php version to 7.1
* Relation between Category and Product has been changed in database. Join table has been removed. Please, make sure that you have fresh database backup before updating application.

## 1.5.0

Full product reindexation has to be performed after upgrade!

## 1.4.0

Format of sluggable urls cache was changed, added support of localized slugs. Cache regeneration is required after update.

## 1.2.0

* Applied changes in Elasticsearch mappings and settings, cutting down index storage size by over 90% and boosting search reindexation.

  **CAUTION**: You need to drop index before performing upgrade using CLI command, for example:

    ```bash
        curl -u elastic -XDELETE 'http://localhost:9200/oro_website_search/'
    ```

  then after upgrade rebuild your website search index manually with command:

    ```bash
        bin/console oro:website-search:reindex --scheduled
    ```

## 1.1.0

* Minimum required `php` version has changed from **5.7** to **7.0**.
* [Fxpio/composer-asset-plugin](https://github.com/fxpio/composer-asset-plugin) dependency was updated to version **1.3**.
* Composer was updated to version **1.4**; use the following commands:

  ```
      composer self-update
      composer global require "fxp/composer-asset-plugin"
  ```

* To upgrade OroCommerce from **1.0** to **1.1** use the following command:

  ```bash
  php bin/console oro:platform:update --env=prod --force
  ```
