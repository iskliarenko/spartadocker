# LAMP Docker Environment for Magento1/2
Two simple [docker](https://docs.docker.com/engine/installation/) environments for Magento1/2 based on CentOS 7 + LAMP stack (PHP 7.0 for M2 and PHP 5.5 for M1) with cron and [mailcatcher](https://mailcatcher.me/).
All services are controlled by [supervisord](http://supervisord.org/).

## Quick Start

### Download
Via GIT:
```
git clone git@github.com:iskliarenko/spartadocker.git
```
or you can download zip archive from:
```
https://github.com/iskliarenko/spartadocker/archive/master.zip
```

### Build and run
Commands should be executed from the project directory.

Build and run docker container for Magento2 by using next command:
```
docker-compose up
```
and for Magento1:
```
docker-compose -f docker-compose-m1.yml up
```

After build (5-15 minutes at first time) your environment will be ready and available here: 
 - Web - http://127.0.0.1:8000/
 - SSH - ssh apache@localhost -p2222 -i conf/magento/docker.pem
 - MySQL - localhost:33060
 - MailCatcher - http://localhost:8001/

The next step you can sign into container and install Magento or deploy the existing dumps.

### Access credentials
SSH: users
 - `root` with password `root`
 - `apache` with password `apache`
or
using imported key: conf/magento/docker.pem 

MySQL: user `root` with blank password
or
user `magento` with password `123123q`

Mailcatcher interface is accessible without authorization.

## Tips
To restart the services (httpd,mysqld,crond,mailcatcher) you can use supervisorctl, for example: `supervisorctl restart httpd`

To rebuild the container completely: `docker-compose build`
or for Magento1: `docker-compose -f docker-compose-m1.yml build`
