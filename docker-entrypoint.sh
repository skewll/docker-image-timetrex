#!/bin/bash
echo "starting..."

mkdir -p /storage
mkdir -p /logs
chgrp -R www-data /storage
chmod 775 -R /storage
chgrp www-data /logs
chmod 775 /logs
chown -R postgres: /database

if [[ ! -s /var/www/html/timetrex/timetrex.ini.php ]]; then
  cat /timetrex.ini.php.dist >/var/www/html/timetrex/timetrex.ini.php
fi
chgrp www-data /var/www/html/timetrex/timetrex.ini.php
chmod 664 /var/www/html/timetrex/timetrex.ini.php

#TODO ignore this is user has included postgresql image in docker-compose.yaml

{

  # wait until postgresql is ready to serve
  echo "Waiting for PostgreSQL to start up. This can take a few minutes..."
  until pg_isready --host localhost --port 5432; do
    sleep 0.3
  done

  if [ ! -f /database/PG_VERSION ]; then
    su - postgres -c "/usr/lib/postgresql/14/bin/initdb /database/"
    su - postgres -c "psql -c \"CREATE USER timetrex WITH CREATEDB CREATEROLE LOGIN PASSWORD 'timetrex';\"; psql -c \"CREATE DATABASE timetrex;\"" &
    echo "New install detected!!!!"
    echo "Connect to http://[host]:[port]/timetrex/interface/install/install.php to finish installation."
  else
    echo "Existing databse found."
    CUR_VER=$(ls /var/www/html/timetrex/classes/modules/install/sql/postgresql/ | tail -1 | sed 's/.sql//')
    DB_VER=$(su - postgres -c "psql timetrex -q -t -c \"select value from system_setting where name='schema_version_group_A'\"" | tr -d '[:blank:]')
    if [[ "$CUR_VER" != "$DB_VER" ]]; then
      # break this into two commands to work around bind limitations
      sed 's/installer_enabled =.*/installer_enabled = TRUE/' /var/www/html/timetrex/timetrex.ini.php >/tmp/timetrex.ini.php
      cat /tmp/timetrex.ini.php >/var/www/html/timetrex/timetrex.ini.php
      echo "Database version is not up to date. Schema $CUR_VER is older then Schema $DB_VER."
      echo "Timetrex has been put in installer mode."
      echo "Connect to http://[host]:[port]/timetrex/interface/install/install.php to finish upgrade."
    else
      echo "Postgres is up to date. Timetrex is ready at http://[host]:[port]/timetrex/interface/html5/index.php"
    fi
  fi
} &

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf 1>/dev/null
