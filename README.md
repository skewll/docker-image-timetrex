# Docker Container for TimeTrex Workforce Management System

This is a working Docker image for running the TimeTrex open source
time tracking and payroll system.  It contains apache, php,
a postgres database, and TimeTrex Community Edition.

More details about TimeTrex can be found at https://www.timetrex.com/community-edition

This container has no affiliation with TimeTrex. But thank you to the TimeTrex Community.



TODOs
- [x] ~~Many previous tasks.~~
- [x] ~~Make docker image cross-platform compatible to use on rpi4 arm64~~
- [x] ~~Figure out why retarting container always triggers "New version".~~
- [x] ~~Figure out why I can only access UI from http://localhost:8080/timetrex/interface/html5/index.php.~~ Dont change baseurl
- [ ] Make custom environments variables possible.
- [ ] Make changes to code to make it more dynamic with future versions, etc. Example: Will * in the paths instead of 14 for postgresql work?



## What to expect:

* On first run it will initialize the postgres database as well as the timetrex.ini.php config file.

* Once container is running, finish install at:  http://localhost:8080/timetrex/interface/install/install.php

* Once install is complete, access timetrex at: http://localhost:8080/timetrex/interface/html5/index.php

* You will be able to change some options via your mounted timetrex.ini.php after install.

## Getting started:


I recommend a portainer stack and of course mapping volumes for persisting data:
```
---
version: "2.1"
services:
  timetrex:
    image: skewll/timetrex
    container_name: timetrex
    volumes:
      - /path/to/timetrex/storage:/storage 
      - /path/to/timetrex/logs:/logs 
      - /path/to/timetrex/database:/database 
      - /path/to/timetrex/timetrex.ini.php:/var/www/html/timetrex/timetrex.ini.php
    ports:
      - 8080:80
    restart: unless-stopped
```


Quick run option:
```
docker run -d \
           --name timetrex \
           -p 8080:80 \
           skewll/timetrex
```


For persisting data and to have easy access to your timetrex.ini.php config file, map your volumes:
```
mkdir /Appdata/timetrex/storage
mkdir /Appdata/timetrex/logs
mkdir /Appdata/timetrex/database
touch /Appdata/timetrex/timetrex.ini.php
docker run -d \
           --name timetrex \
           -p 8080:80 \
           -v /path/to/timetrex/storage:/storage \
           -v /path/to/timetrex/logs:/logs \
           -v /path/to/timetrex/database:/database \
           -v /path/to/timetrex/timetrex.ini.php:/var/www/html/timetrex/timetrex.ini.php \
           skewll/timetrex
```


## EXTRAS: Post-install timetrex.ini.php file config tips:

* Dont change the base_url from "/timetrex/interface". It seems to just cause issues.

* Set up smtp. Test by sending a password reset request.

* If serving public, set your hostname. I set mine to my sub.domain.com

* You can run this behind nginx reverse proxy. To access TimeTrex UI from sub.domain.com add the following Customem Nginx Configuration under the "Edit Proxy Host" > "Advanced" tab

```
location = / {  
    return 301 https://sub.domain.com/timetrex;
}
```

* I am not sure if this is required, but I added the following under [other] as well:
```
; Added settings to run behind nginx reverse proxy
proxy_ip_address_header_name = 'HTTP_X_FORWARDED_FOR'
proxy_protocol_header_name = 'HTTP_X_FORWARDED_PROTO'
```

* After making changes to timetrex.ini.php file, restart container.