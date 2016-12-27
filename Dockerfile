FROM centos:latest
MAINTAINER Yuriy Sklyarenko <iskliarenko@magento.com>

# Additional repos
RUN yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm \
		   http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
		   http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN echo -e "\nip_resolve=4\nerrorlevel=0\nrpmverbosity=critical" >> /etc/yum.conf
RUN yum update --enablerepo=remi-php70 -y && yum install -d 0 --nogpgcheck --enablerepo=remi-php70 -y vim rsync less which openssh-server cronie \
		   bash-completion bash-completion-extras mod_ssl mc nano dos2unix unzip lsof pv telnet zsh patch python2-pip net-tools \
		   httpd httpd-tools \
		   php php-cli php-mcrypt php-mbstring php-soap php-pecl-xdebug php-xml php-bcmath \
		   php-pecl-memcached php-pecl-redis php-pdo php-gd php-mysqlnd php-intl php-pecl-zip \
		   Percona-Server-server-56 Percona-Server-client-56 
# PHP 
RUN echo -e "xdebug.remote_enable = 1 \nxdebug.remote_autostart = 1\nxdebug.max_nesting_level = 100000" >> /etc/php.d/15-xdebug.ini
RUN sed -i -e "s/;date.timezone\s*=/date.timezone = 'UTC'/g" /etc/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/g" /etc/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*2M/post_max_size = 64M/g" /etc/php.ini
RUN sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 768M/g" /etc/php.ini

# Apache
RUN sed -i -e "s/AllowOverride\s*none/AllowOverride All/g" /etc/httpd/conf/httpd.conf
RUN sed -i -e "s/#ServerName\s*www.example.com:80/ServerName local.dev/g" /etc/httpd/conf/httpd.conf
RUN echo "Header always set Strict-Transport-Security 'max-age=0'" >> /etc/httpd/conf/httpd.conf
RUN echo "umask 002" >> /etc/profile

# MySQL
COPY ./conf/daemons/mysql-sparta.cnf /etc/my.cnf.d/mysql-sparta.cnf 

# SSH
RUN echo 'root:root' | chpasswd && /usr/bin/ssh-keygen -A 
RUN echo 'apache:apache' | chpasswd && chsh apache -s /bin/bash && usermod -d /var/www/html apache 

# Magento tools
RUN mkdir -p /root/.config/composer
COPY ./conf/magento/auth.json /root/.config/composer/auth.json
COPY ./conf/magento/.m2install.conf /root/.m2install.conf
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && chmod +x /usr/bin/composer; curl -o /usr/bin/m2install.sh https://raw.githubusercontent.com/yvoronoy/m2install/master/m2install.sh \
    && chmod +x /usr/bin/m2install.sh; curl -o /usr/bin/n98-magerun2 https://files.magerun.net/n98-magerun2.phar \
    && chmod +x /usr/bin/n98-magerun2

# Supervisor config
RUN mkdir /var/log/supervisor/ && /usr/bin/easy_install supervisor && /usr/bin/easy_install supervisor-stdout
ADD ./conf/daemons/supervisord.conf /etc/supervisord.conf

# Initialization Startup Script
ADD ./scripts/start.sh /start.sh
RUN chmod 755 /start.sh && /bin/bash start.sh

EXPOSE 3306
EXPOSE 80
EXPOSE 22

ENTRYPOINT [ "/start.sh" ]
