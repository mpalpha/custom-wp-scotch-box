#!/bin/bash
sudo mysqldump -c -uroot -proot  --single-transaction scotchbox > /var/www/db/custom.sql 2>/dev/null