#!/bin/bash
set -e

MYSQL_DATABASE='magento'
MYSQL_USER='magento'
MYSQL_PASSWORD='123123q'
MYSQLBIN='/usr/bin/mysql'
IP=`ifconfig eth0 |grep netmask |awk {' print $2 '}`

if [ ! -d "/var/lib/mysql/magento/" ]; then
	echo -e "\n ---------------------- installing default MySQL databases ------------------------ \n"
	#/bin/mysql_install_db --user mysql >/dev/null 2>&1 
	#/bin/mysql_install_db --explicit_defaults_for_timestamp --user mysql >/dev/null 2>&1 
	chown -R mysql.mysql /var/lib/mysql 

	# start mysqld
	/bin/mysqld_safe &
	sleep 5

	echo -e "\n --------- Creating database ${MYSQL_DATABASE}, user ${MYSQL_USER}, password ${MYSQL_PASSWORD} ------- \n"
	echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8 COLLATE utf8_general_ci;" | ${MYSQLBIN}
	echo "GRANT ALL ON \`${MYSQL_DATABASE}\`.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' WITH GRANT OPTION;" | ${MYSQLBIN}
	echo "GRANT ALL ON \`${MYSQL_DATABASE}\`.* to '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}' WITH GRANT OPTION;" | ${MYSQLBIN}
	echo "GRANT ALL ON \`${MYSQL_DATABASE}_%\`.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' WITH GRANT OPTION;" | ${MYSQLBIN}
	echo "GRANT ALL ON \`${MYSQL_DATABASE}_%\`.* to '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}' WITH GRANT OPTION;" | ${MYSQLBIN}
	echo "GRANT ALL ON *.* to 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;" | ${MYSQLBIN}
else
	echo -e "Container IP address: ${IP}\n To access the container use 'ssh apache@${IP}' with password: 'apache'\n or 'ssh apache@localhost -p 2222' with password: 'apache'\n User 'apache' can use sudo \n Mailcatcher web-interface: http://${IP}:81/ or http://localhost:8001/\n All services are running, press Ctrl-C to stop container..."

	# start all the services
	/usr/bin/supervisord -c /etc/supervisord.conf >/dev/null 2>&1
	exit 0;
fi
