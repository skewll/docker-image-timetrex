#FROM alpine:3.19.0
#FROM ubuntu:22.04
FROM debian:bullseye-slim
#ENV DEBIAN_FRONTEND noninteractive

USER root

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# The Envs above, are they needed? Are they doing anything at all? I see this in the build log with ubuntu and debian-bulleye:
#
# perl: warning: Setting locale failed.
# perl: warning: Please check that your locale settings:
# 	LANGUAGE = "en_US:en",
# 	LC_ALL = "en_US.UTF-8",
# 	LANG = "en_US.UTF-8"
#     are supported and installed on your system.
# perl: warning: Falling back to the standard locale ("C").
# debconf: delaying package configuration, since apt-utils is not installed /#

# Do some stuff.
RUN apt-get update -y -qq
RUN apt-get dist-upgrade -y
RUN apt-get install -y locales software-properties-common
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# install tools
RUN apt-get install -y supervisor vim unzip wget

# install TimeTrex prequirements (Timetrex)
RUN add-apt-repository universe

#    Ubuntu 22.04 [Jammy] / Debian 12 [Bookworm]: (Timetrex) - php8.1.json
RUN apt-get install -y unzip apache2 libapache2-mod-php php php8.1-cgi php8.1-cli php8.1-pgsql php8.1-pspell php8.1-gd php8.1-gettext php8.1-imap php8.1-intl php8.1-soap php8.1-zip php8.1-curl php8.1-ldap php8.1-xml php8.1-xsl php8.1-mbstring php8.1-bcmath postgresql

# Restart Apache after all packages are installed: (Timetrex)
RUN service apache2 restart

# clean up
RUN apt-get autoclean && apt-get autoremove
RUN rm -rf /var/lib/apt/lists/*

# Download the TimeTrex .ZIP file to your computer.(Timetrex)
RUN cd /tmp 
RUN wget http://www.timetrex.com/download/TimeTrex_Community_Edition-manual-installer.zip

# Unzip the TimeTrex .ZIP file to the root web directory: (Timetrex)
RUN unzip TimeTrex_Community_Edition-manual-installer.zip -d /var/www/html/
RUN rm -f /tmp/TimeTrex_Community_Edition-manual-installer.zip

# Rename the unzipped directory: (Timetrex)
RUN mv /var/www/html/TimeTrex*/ /var/www/html/timetrex

# Rename the TimeTrex.ini.php file: (Timetrex)
# RUN mv /var/www/html/timetrex/timetrex.ini.php-example_linux /var/www/html/timetrex/timetrex.ini.php # this is no longer needed. The default timetrec.ini IS the linux version

#Do some other magical shit.
RUN chgrp www-data -R /var/www/html/timetrex/
RUN chmod 775 /var/www/html/timetrex
RUN mkdir /database
RUN chown -R postgres: /database
RUN sed -i "s#data_directory =.*#data_directory = '/database'#" /etc/postgresql/14/main/postgresql.conf
RUN chsh -s /bin/bash www-data


COPY ["supervisord.conf", "httpd.conf", "maint.conf", "postgres.conf", "/etc/supervisor/conf.d/"]
COPY ["*.sh", "/"]
COPY ["mpm_prefork.conf", "/etc/apache2/mods-available/mpm_prefork.conf"]
COPY ["timetrex.ini.php.dist", "/"]
EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
