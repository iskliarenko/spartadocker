FROM centos:latest
MAINTAINER Yuriy Sklyarenko <iskliarenko@magento.com>

# Additional repos
RUN yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm \
		   http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
		   http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN echo -e "\nip_resolve=4\nerrorlevel=0\nrpmverbosity=critical" >> /etc/yum.conf
RUN yum update --enablerepo=remi-php70 -y && yum install -d 0 --nogpgcheck --enablerepo=remi-php70 -y vim rsync less which openssh-server cronie \
		   bash-completion bash-completion-extras mod_ssl mc nano dos2unix unzip lsof pv telnet zsh patch python2-pip net-tools git tmux htop \
		   httpd httpd-tools \
		   php php-cli php-mcrypt php-mbstring php-soap php-pecl-xdebug php-xml php-bcmath \
		   php-pecl-memcached php-pecl-redis php-pdo php-gd php-mysqlnd php-intl php-pecl-zip \
		   ruby ruby-devel sqlite-devel make gcc gcc-c++ \
		   Percona-Server-server-56 Percona-Server-client-56 \
		   && yum clean all 
# PHP 
ADD ./scripts/php-ext-switch.sh /usr/local/bin/
RUN ln -s /usr/local/bin/php-ext-switch.sh /usr/local/bin/xdebug-sw.sh
RUN /usr/local/bin/xdebug-sw.sh 0
RUN echo -e "xdebug.remote_enable = 1 \nxdebug.remote_autostart = 1\nxdebug.remote_host=10.254.254.254\nxdebug.max_nesting_level = 100000" >> /etc/php.d/15-xdebug.ini
RUN sed -i -e "s/;date.timezone\s*=/date.timezone = 'UTC'/g" /etc/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/g" /etc/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*2M/post_max_size = 64M/g" /etc/php.ini
RUN sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 768M/g" /etc/php.ini
RUN sed -i -e "s/sendmail_path\s=\s\/usr\/sbin\/sendmail\s-t\s-i/sendmail_path=\/usr\/bin\/env catchmail -f sparta@docker.local/g" /etc/php.ini

# Mailcatcher
RUN gem install mailcatcher --no-ri --no-rdoc

# tideways PHP profiler
RUN echo -e "[tideways]\nname = Tideways\nbaseurl = https://s3-eu-west-1.amazonaws.com/qafoo-profiler/rpm" > /etc/yum.repos.d/tideways.repo
RUN rpm --import https://s3-eu-west-1.amazonaws.com/qafoo-profiler/packages/EEB5E8F4.gpg \
    && yum makecache --disablerepo=* --enablerepo=tideways \
    && yum install -y tideways-php tideways-cli
RUN echo -e "tideways.auto_prepend_library=0\ntideways.framework=magento2\n" >> /etc/php.d/40-tideways.ini
RUN ln -s /usr/local/bin/php-ext-switch.sh /usr/local/bin/tideways-sw.sh
RUN /usr/local/bin/tideways-sw.sh 0

# Apache
RUN sed -i -e "s/AllowOverride\s*None/AllowOverride All/g" /etc/httpd/conf/httpd.conf
RUN sed -i -e "s/#ServerName\s*www.example.com:80/ServerName local.dev/g" /etc/httpd/conf/httpd.conf
RUN echo "Header always set Strict-Transport-Security 'max-age=0'" >> /etc/httpd/conf/httpd.conf
RUN echo "umask 002" >> /etc/profile

# MySQL
COPY ./conf/daemons/mysql-sparta.cnf /etc/my.cnf.d/mysql-sparta.cnf 

# SSH
RUN echo 'root:root' | chpasswd && /usr/bin/ssh-keygen -A 
RUN echo 'apache:apache' | chpasswd && chsh apache -s /bin/bash && usermod -d /var/www/html apache 
RUN mkdir -p /root/.ssh
ADD ./conf/magento/docker.pem.pub /root/.ssh/authorized_keys
ADD ./conf/magento/docker.pem /root/.ssh/docker.pem
RUN chmod 400 /root/.ssh/*
ADD ./conf/daemons/.terminal /root/.terminal
RUN echo -e "\nsource ~/.terminal\n" >> /root/.bashrc

# Magento tools
RUN mkdir -p /root/.config/composer
COPY ./conf/magento/auth.json /root/.composer/auth.json
COPY ./conf/magento/.m2install.conf /root/.m2install.conf
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && chmod +x /usr/bin/composer; curl -o /usr/bin/m2install.sh https://raw.githubusercontent.com/yvoronoy/m2install/master/m2install.sh \
    && chmod +x /usr/bin/m2install.sh; curl -o /usr/bin/n98-magerun2 https://files.magerun.net/n98-magerun2.phar \
    && chmod +x /usr/bin/n98-magerun2

# Supervisor config
RUN mkdir /var/log/supervisor/ && /usr/bin/easy_install supervisor && /usr/bin/easy_install supervisor-stdout && rm /tmp/* -rf
ADD ./conf/daemons/supervisord.conf /etc/supervisord.conf

# Initialization Startup Script
ADD ./scripts/start.sh /start.sh
RUN chmod 755 /start.sh && /bin/bash start.sh

EXPOSE 3306
EXPOSE 80
EXPOSE 81
EXPOSE 22

ENTRYPOINT [ "/start.sh" ]
