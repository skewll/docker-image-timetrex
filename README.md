# TimeTrex Workforce Management System Docker Container

* (Updated Dec-24-2023) This is a complete working Docker image that runs the TimeTrex open source
time tracking and payroll system.  It includes all you need to get going: apache, php,
a postgres database, and TimeTrex Community Edition.

* More details about TimeTrex can be found at https://www.timetrex.com/community-edition

* This is my first attempt at coding a dockerfile and bash scripting. Please star if it helped you!


## What to expect the first time:

* On first run it will initialize the postgres database as well as the timetrex.ini.php config file.

* Once container is running, finish install at:  http://localhost:8080/timetrex/interface/install/install.php

* Grab a coffee and come back in an hour, or watch the "Processing" icon spin on the installer.

* Once install is complete, access timetrex at: http://localhost:8080/timetrex/interface/html5/index.php

* You will also be able to change some options via your mounted timetrex.ini.php after install.

* Set up your TimeTrex admin user, employees, company etc. Done.


## How to install:

I recommend a portainer stack and mapping volumes for persisting data:
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

* You can run this behind nginx reverse proxy. To access TimeTrex UI from sub.domain.com add the following Custom Nginx Configuration under the "Edit Proxy Host" > "Advanced" tab

```
location = / {  
    return 301 https://sub.domain.com/timetrex;
}
```
<!-- 
* I no not belive this is required any more, but I added the following under [other] as well to troubleshoot a previous issue I had:
```
; Added settings to run behind nginx reverse proxy
proxy_ip_address_header_name = 'HTTP_X_FORWARDED_FOR'
proxy_protocol_header_name = 'HTTP_X_FORWARDED_PROTO'
``` -->

* After making changes to timetrex.ini.php file, I found it not neccassary to restart container for changes to take effect.

## TODOs
- [x] ~~Many previous tasks.~~
- [x] ~~Make docker image cross-platform compatible to use on rpi4 arm64~~
- [x] ~~Figure out why retarting container always triggers "New version".~~
- [x] ~~Figure out why I can only access UI from http://localhost:8080/timetrex/interface/html5/index.php.~~ Dont change baseurl
- [ ] Make custom environments variables possible.
- [ ] Make changes to code to make it more dynamic with future versions, etc. Example: Will * in the paths instead of 14 for postgresql work?