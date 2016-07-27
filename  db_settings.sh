#!/bin/bash

# Ensure migration is performed and database is not empty.
if [[ ! -e migrated ]]; then
    php artisan migrate

	composer install

    touch migrated
fi

/run.sh
