#!/bin/bash

sleep 10
php artisan migrate:refresh
php artisan serve --host=0.0.0.0
