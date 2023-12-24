#!/bin/bash

mkdir -p /storage
mkdir -p /logs 
chgrp -R www-data /storage
chmod 775 -R /storage
chgrp www-data /logs
chmod 775 /logs
chown -R postgres: /database

if [[ ! -s /var/www/html/timetrex/timetrex.ini.php ]]
then
  cat /timetrex.ini.php.dist > /var/www/html/timetrex/timetrex.ini.php
fi
chgrp www-data /var/www/html/timetrex/timetrex.ini.php
chmod 664 /var/www/html/timetrex/timetrex.ini.php


#TODO ignore this is user has included postgresql image in docker-compose.yaml

{

# wait until postgresql is ready to serve
until pg_isready --host localhost --port 5432; do \
    echo "waiting for PostgreSQL..."
		sleep 0.1; \
done

if [ ! -f /database/PG_VERSION ]
then
  su - postgres -c "/usr/lib/postgresql/14/bin/initdb /database/" 
  su - postgres -c "psql -c \"CREATE USER timetrex WITH CREATEDB CREATEROLE LOGIN PASSWORD 'timetrex';\"; psql -c \"CREATE DATABASE timetrex;\"" &
  echo "New install detected!!!!"
  echo "Connect to http://[host]:[port]/timetrex/interface/install/install.php to finish installtion."
else
  CUR_VER=`ls /var/www/html/timetrex/classes/modules/install/sql/postgresql/ | tail -1 | sed 's/.sql//'`
  DB_VER=`su - postgres -c "psql timetrex -q -t -c \"select value from system_setting where name='schema_version_group_A'\"" | tr -d '[:blank:]'`
  if [[ "$CUR_VER" != "$DB_VER" ]]
  then
    # break this into two commands to work around bind limitations
    sed 's/installer_enabled =.*/installer_enabled = TRUE/' /var/www/html/timetrex/timetrex.ini.php > /tmp/timetrex.ini.php
    cat /tmp/timetrex.ini.php > /var/www/html/timetrex/timetrex.ini.php
    echo "New version detected!!!! Version $CUR_VER is older then version $DB_VER."
    echo "Connect to http://[host]:[port]/timetrex/interface/install/install.php to finish upgrade."
  fi
fi
} &
  
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf 1>/dev/null
