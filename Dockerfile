FROM centos:7
MAINTAINER Yuriy Sklyarenko <skliaren@adobe.com>

# Apache & PHP 7.3 & Redis
RUN yum install -y --nogpgcheck http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
       && echo -e "\nip_resolve=4\nerrorlevel=0\nrpmverbosity=critical" >> /etc/yum.conf \
       && yum update --enablerepo=remi-php73 -y --nogpgcheck && yum install -d 0 --nogpgcheck --enablerepo=remi-php73 --enablerepo=remi -y vim rsync less which openssh-server cronie sudo \
            bash-completion bash-completion-extras mod_ssl mc nano dos2unix unzip lsof pv telnet zsh patch python2-pip net-tools git tmux htop wget \
            httpd httpd-tools \
            redis \
            php php-cli php-pecl-mcrypt php-mbstring php-soap php-pecl-xdebug php-xml php-bcmath phpmyadmin \
            php-pecl-memcached php-pecl-redis5 php-sodium php-pdo php-gd php-mysqlnd php-intl php-pecl-zip php-mongodb php-devel \
            ruby ruby-devel sqlite-devel make gcc gcc-c++ \

# PHP configuration
        && echo -e "xdebug.remote_enable = 1 \nxdebug.remote_autostart = 1\nxdebug.remote_host=10.254.254.254\nxdebug.max_nesting_level = 100000" >> /etc/php.d/15-xdebug.ini \
        && sed -i -e "s/;date.timezone\s*=/date.timezone = 'UTC'/g" /etc/php.ini \
        && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/g" /etc/php.ini \
        && sed -i -e "s/post_max_size\s*=\s*2M/post_max_size = 64M/g" /etc/php.ini \
        && sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 2G/g" /etc/php.ini \
        && sed -i -e "s/sendmail_path\s=\s\/usr\/sbin\/sendmail\s-t\s-i/sendmail_path=\/usr\/bin\/env catchmail -f sparta@docker.local/g" /etc/php.ini \
        && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && chmod +x /usr/bin/composer \

# Mailcatcher
        && gem install mailcatcher --no-ri --no-rdoc \

# PhpMyAdmin & Tideways PHP XHGUI profiler
        && mkdir -p /usr/share/magetools \
        && git clone https://github.com/tideways/php-xhprof-extension.git && cd php-xhprof-extension \
        && phpize && ./configure && make && make install \
        && echo -e "extension=tideways_xhprof.so\n" > /etc/php.d/40-tideways.ini \
        && mkdir /usr/share/xhgui && git clone https://github.com/perftools/xhgui.git /usr/share/xhgui \
        && /usr/bin/composer install -d /usr/share/xhgui \
        && find /usr/share/xhgui /var/log/httpd /root/.composer -exec chown apache.apache {} \; \
        && rm /etc/httpd/conf.d/phpMyAdmin.conf \

# Install MongoDB 4.2
        && echo -e "[mongodb42]\nname = MongoDB Repository\nbaseurl = https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.2/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/mongodb-org.repo \
        && yum install -y --nogpgcheck mongodb-org && yum clean all \
        && sed -i -e "s/fork\s*=\s*true/fork = false/g" /etc/mongod.conf \
        && sed -i -e "s/bind_ip\s*=\s*127.0.0.1/#bind_ip = 127.0.0.1/g" /etc/mongod.conf \

# Apache configuration
        && sed -i -e "s/AllowOverride\s*None/AllowOverride All/g" /etc/httpd/conf/httpd.conf \
        && sed -i -e "s/var\/www\/html/var\/www\/html\/pub/g" /etc/httpd/conf/httpd.conf \
        && sed -i -e "s/#OPTIONS=/OPTIONS=-DFOREGROUND/g" /etc/sysconfig/httpd \
        && sed -i -e "s/#ServerName\s*www.example.com:80/ServerName local.magento/g" /etc/httpd/conf/httpd.conf \
        && sed -i -e "s/FALSE/TRUE/g" /etc/phpMyAdmin/config.inc.php \
        && echo "Header always set Strict-Transport-Security 'max-age=0'" >> /etc/httpd/conf/httpd.conf \
        && echo "umask 002" >> /etc/profile \

# MariaDB 10.4
        &&  wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
        && chmod +x mariadb_repo_setup \
        && sudo ./mariadb_repo_setup --mariadb-server-version="mariadb-10.4"\
        && yum install -y MariaDB-server MariaDB-client \

# ElasticSearch 7.X
        && echo -e "[elasticsearch]\nname=Elasticsearch repository for 7.x packages\nbaseurl=https://artifacts.elastic.co/packages/7.x/yum\ngpgcheck=0\nenabled=1\nautorefresh=1\ntype=rpm-md" >> /etc/yum.repos.d/elasticsearch.repo \
        && yum install -y elasticsearch


# MySQL & apache aliases
ADD ./conf/daemons/mysql-sparta.cnf /etc/mysql/my.cnf
ADD ./conf/daemons/aliases.conf /etc/httpd/conf.d/aliases.conf

# SSH & supervisor configuration
ADD ./conf/daemons/.terminal /home/apache/.terminal
ADD ./conf/magento/docker.pem.pub /etc/ssh/authorized_keys
ADD ./conf/magento/docker.pem /etc/ssh/docker.pem

# Magento tools
ADD ./conf/magento/auth.json.example /home/apache/.composer/auth.json
ADD ./conf/magento/.m2install.conf /home/apache/.m2install.conf
ADD ./scripts/m2modtgl.sh /usr/local/bin/m2modtgl.sh
ADD ./scripts/php-ext-switch.sh /usr/local/bin/
# Supervisor config
ADD ./conf/daemons/supervisord.conf /etc/supervisord.conf
# Initialization startup script
ADD ./scripts/start.sh /start.sh

RUN echo 'root:root' | chpasswd \
        && /usr/bin/ssh-keygen -A \
        && mkdir -p /var/www/html/pub \
        && echo 'apache:apache' | chpasswd && chsh apache -s /bin/bash && usermod -d /home/apache apache \
        && chown -R apache.apache /var/www \
        && sed -i -e "s/AuthorizedKeysFile\s*\.ssh\/authorized_keys/AuthorizedKeysFile \/etc\/ssh\/authorized_keys/g" /etc/ssh/sshd_config \
        && chmod 400 /etc/ssh/authorized_keys && chown apache.apache /etc/ssh/authorized_keys \
        && cp /root/.bashrc /home/apache && ln -s /home/apache/.bashrc /home/apache/.bash_profile \
        && echo -e "\nsource ~/.terminal\n" >> /home/apache/.bashrc \
        && echo 'apache ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers \
        && mkdir /var/log/supervisor/ && /usr/bin/easy_install supervisor && /usr/bin/easy_install supervisor-stdout && rm /tmp/* -rf \
        && ln -s /usr/local/bin/php-ext-switch.sh /usr/local/bin/xdebug-sw.sh && /usr/local/bin/xdebug-sw.sh 0 \
        && find /home/apache/ -exec chown apache.apache {} \; \
        && ln -s /usr/local/bin/m2modtgl.sh /usr/local/bin/m2modon \
        && ln -s /usr/local/bin/m2modtgl.sh /usr/local/bin/m2modoff \
        && curl -o /usr/bin/m2install.sh https://raw.githubusercontent.com/magento-sparta/m2install/master/m2install.sh && chmod +x /usr/bin/m2install.sh \
        && curl -o /usr/bin/convert-for-composer.php https://raw.githubusercontent.com/magento-sparta/m2-convert-patch-for-composer-install/master/convert-for-composer.php \
        && chmod +x /usr/bin/convert-for-composer.php \
        && curl -o /usr/bin/n98-magerun2 https://files.magerun.net/n98-magerun2-dev.phar && chmod +x /usr/bin/n98-magerun2 \
        && ln -s /usr/share/ee-support-tools/cloud-tools/dump.sh /usr/bin/cloud-dump && ln -s /usr/share/ee-support-tools/cloud-tools/remote-shell.sh /usr/bin/cloud-ssh \
# Tools from Performance team https://gist.github.com/kandy
        && mkdir -p /usr/share/magetools/sql \
        && curl -o /usr/share/magetools/inline_profiler_autoprepend.php https://gist.githubusercontent.com/kandy/7ae16d74e2bdc35ffd7b524f089259c2/raw/1f7392faade651a1e4b28f317f6b3706a61622ea/autoprepend.php \
        && curl -o /usr/share/magetools/sql/bootstrap.php https://gist.githubusercontent.com/kandy/4e07735185dfdfe30cb58eba5cc87ece/raw/68f052c5b1093bf3e59f02df9235b5c59d828267/bootstrap.php \
        && curl -o /usr/share/magetools/sql/env.php https://gist.githubusercontent.com/kandy/4e07735185dfdfe30cb58eba5cc87ece/raw/68f052c5b1093bf3e59f02df9235b5c59d828267/env.php \

        && chmod 755 /start.sh && /bin/bash /start.sh && rm -r /var/www/html/pub

EXPOSE 22 80 81 443 3306 6379 9200 27017

ENTRYPOINT [ "/start.sh" ]
