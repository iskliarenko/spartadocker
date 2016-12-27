#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/magento/" ]; then

	echo -e "\n ---------------------- installing default MySQL databases ------------------------ \n"
	/bin/mysql_install_db --explicit_defaults_for_timestamp --user mysql >/dev/null 2>&1 
	chown -R mysql.mysql /var/lib/mysql 
	
	MYSQL_DATABASE='magento'
	MYSQL_USER='magento'
	MYSQL_PASSWORD='123123q'
	
	# start mysqld
	/bin/mysqld_safe &

	sleep 5
	echo -e "\n --------- Creating database ${MYSQL_DATABASE}, user ${MYSQL_USER}, password ${MYSQL_PASSWORD} ------- \n"
	echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" |/usr/bin/mysql 
	echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION;" |/usr/bin/mysql
	echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION;" |/usr/bin/mysql

else
	# start all the services
	IP=`ifconfig eth0 |grep netmask |awk {' print $2 '}`
	echo -e "Container IP address: ${IP}\n	  To access the container use 'ssh root@${IP}' with password: 'root'\n	All services are running, press Ctrl-C to stop container..."
	/usr/bin/supervisord -c /etc/supervisord.conf >/dev/null 2>&1
	exit 0;
fi
