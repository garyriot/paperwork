#!/bin/bash

# Ensure migration is performed and database is not empty.
service mysql restart
if [[ ! -e migrated ]]; then
    php artisan migrate

	composer install

    touch migrated
fi

/run.sh
