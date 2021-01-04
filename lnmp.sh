#!/bin/bash
#    File: lnmp.sh
#
#    Usage:
#    chmod +x lnmp.sh
#    ./xm-lnmp.sh (nginx|mysql|php) (install|start|stop|restart|status)
#
#    Auther: PandaMan ( i[at]davymai.com )
#
#    Link: https://xmyunwei.com
#
#    Version: 2.0
#################################################
#    Date: 2020-10-19
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear

#INFO函数定义输出字体颜色，echo -e 表示保持字符串的特殊含义，$1表示字体颜色编号，$2表示等待程序执行时间，$3表示echo输出内容。
function INFO() {
    echo -e "\e[$1;49;1m: $3 \033[39;49;0m"
    sleep "$2"
    echo ""
}
THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
#非root用户不能执行该脚本
if [ "$UID" != 0 ]; then
    echo " "
    INFO 35 "0" "Must be root ro run this script."
    exit 1
fi
#USAGE函数定义脚本用法，可反复调用，basename其实就是脚本名，\n表示换行。
function USAGE() {
    INFO 35 "0.1" "Please see the script of the usage:"
    basename=$(basename "$0")
    INFO \
        36 "0" \
        "$(echo -e "Usage: \n\n./$basename ( nginx|mysql|php|memcached|redis ) install \nsystemctl (start|stop|restart|status) nginx|mysqld|php|memcached|redis \n")"
}
# start Time
startTime=$(date +%s)
#YUM_INSTALL函数安装依赖包，可反复调用，$@表示所有参数都分别被双引号引住"$1","$2"，而$*表示所有这些参数都被双引号引住"$1$2"
function YUM_INSTALL() {
    for a in $@; do
        INFO 32 1 "Install depend on the [ $a ]"
        yum -y install $a || exit 1
        if [ $a = "openldap-devel" ]; then
            ln -s /usr/lib64/libldap* /usr/lib/
        fi
        if [ $a = "devtoolset-9-gcc" ]; then
            echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile
            source /etc/profile
        fi
        yum clean all && rm -rf /var/cache/yum/*
    done
}
#INSTALL函数定义安装程序，可一反复调用，安装nginx程序的时候要先安装3个依赖包，在安装mysql的时候要用cmake编译。$1表示要安装的程序，$2表示yum安装对应的依赖包，$3表示程序解压后的目录，$4表示程序源码包。
function INSTALL() {
    YUM_INSTALL "$2" && cd $SOURCE_PATH
    [ -d $3 ] && rm -r $3
    INFO 31 4 "Unpack the $4 installation package......"
    tar zxvf $4
    cd $3
    pwd
    export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig/:$PKG_CONFIG_PATH
    INFO 32 4 "Configure the $1......"
    if [ $1 = jemalloc ]; then
        ./configure $5 || exit 1
    elif [ $1 = openssl ]; then
        ./config $5 || exit 1
    elif [ $1 = zlib ]; then
        ./configure $5 || exit 1
    elif [ $1 = pcre ]; then
        ./configure $5 || exit 1
    elif [ $1 = tengine ]; then
        # Modify Tengine version
        sed -i 's@TENGINE "/" TENGINE_VERSION@"Tengine/xmyunwei"@' src/core/nginx.h
        sed -i '/^"<hr><center>tengine/s@"<hr><center>tengine</center>" CRLF@"<hr><center>xm-server</center>" CRLF@g' src/http/ngx_http_special_response.c
        sed -i '/^"<hr><center>nginx/s@"<hr><center>nginx</center>" CRLF@"<hr><center>xm-server</center>" CRLF@g' src/http/ngx_http_special_response.c
        ./configure $5 || exit 1
    elif [ $1 = libsodium ]; then
        ./configure $5 || exit 1
    elif [ $1 = nettle ]; then
        ./configure $5 || exit 1
    elif [ $1 = mysql ]; then
        cmake $5 || exit 1
    elif [ $1 = libzip ]; then
        mkdir build && cd build
        cmake3 $5 .. || exit 1
    elif [ $1 = libevent ]; then
        ./configure $5 || exit 1
    elif [ $1 = argon2 ]; then
        sed -i 's@PREFIX ?= /usr@PREFIX ?= /usr/local/agron2@' Makefile
        sed -i '/PREFIX ?=.*/a\LIBRARY_REL = lib64' Makefile
    elif [ $1 = php ]; then
        ./configure $5 || exit 1
    elif [ $1 = amqp ]; then
        phpize
        ./configure
    elif [ $1 = imagick ]; then
        phpize
        ./configure
    elif [ $1 = mcrypt ]; then
        phpize
        ./configure
    elif [ $1 = memcache ]; then
        phpize
        ./configure
    elif [ $1 = mongodb ]; then
        phpize
        ./configure
    elif [ $1 = php_redis ]; then
        phpize
        ./configure
    elif [ $1 = ssh2 ]; then
        phpize
        ./configure
    elif [ $1 = swoole ]; then
        phpize
        ./configure
    elif [ $1 = yaf ]; then
        phpize
        ./configure
    elif [ $1 = yaml ]; then
        phpize
        ./configure
    elif [ $1 = yar ]; then
        phpize
        ./configure
    elif [ $1 = redis ]; then
        mkdir -p $INSTALL_PATH/redis/etc/
        cp redis.conf $INSTALL_PATH/redis/etc/
        make $5 install
    else
        ./configure $5 || exit 1
    fi
    INFO 36 3 "Compile $1......"
    make -j ${THREAD} || exit 1 && INFO 34 4 "Install $1......"
    make install && INFO 33 4 "$1 installation is successful......"
    if [ $1 = tengine ]; then
        if [ -e "${INSTALL_PATH}/tengine/conf/nginx.conf" ]; then
            popd > /dev/null
            rm -rf pcre-8.44 openssl-1.1.1i tengine-2.3.2 jemalloc-5.2.1 zlib-1.2.11
        else
            rm -rf ${INSTALL_PATH}/tengine
            INFO 31 1 "Tengine install failed, Please Contact the author!"
            kill -9 $$
        fi
    fi
    if [ $1 = jemalloc ]; then
        echo "/usr/local/jemalloc/lib" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = openssl ]; then
        if [ -n "$(grep ^'export PKG_CONFIG_PATH=' /etc/profile)" -a -z "$(grep /usr/local/libzip /etc/profile)" ]; then
            sed -i 's|export PKG_CONFIG_PATH=\(.*\)|export PKG_CONFIG_PATH=/usr/local/openssl/lib/pkgconfig/:\1|' /etc/profile
        fi
        . /etc/profile
        INFO 33 4 "Add $1 PKG_CONFIG_PATH to /etc/profile......"
        echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = libzip ]; then
        if [ -n "$(grep ^'export PKG_CONFIG_PATH=' /etc/profile)" -a -z "$(grep /usr/local/libzip /etc/profile)" ]; then
            sed -i 's|export PKG_CONFIG_PATH=\(.*\)|export PKG_CONFIG_PATH=/usr/local/libzip/lib64/pkgconfig/:\1|' /etc/profile
        fi
        . /etc/profile
        INFO 33 4 "Add $1 PKG_CONFIG_PATH to /etc/profile......"
        echo "/usr/local/libzip/lib64" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = pcre ]; then
        echo "${ENV_PATH}/pcre/lib" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"

    fi
    if [ $1 = libsodium ]; then
        ln -sf ${ENV_PATH}/libsodium/include/libsodium/* /usr/include/
        [ -d /usr/lib/pkgconfig ] && /bin/cp ${ENV_PATH}/libsodium/lib/pkgconfig/libsodium.pc /usr/lib/pkgconfig/
        echo "/usr/local/libsodium/lib" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"

    fi
    if [ $1 = nettle ]; then
        ln -s /usr/local/nettle/lib64/libnettle.so.8.0 /usr/lib64/
        echo "/usr/local/nettle/lib64" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = libevent ]; then
        ln -s /usr/local/libevent/lib/libevent-2.1.so.7.0.1 /usr/lib64/
        echo "/usr/local/libevent/lib" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = argon2 ]; then
        ln -sf ${ENV_PATH}/argon2/include/argon2/* /usr/include/
        [ -d /usr/lib/pkgconfig ] && /bin/cp /usr/local/agron2/lib64/pkgconfig/libargon2.pc /usr/lib/pkgconfig/
        echo "/usr/local/agron2/lib64" >> /etc/ld.so.conf
        /usr/sbin/ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = php ]; then
        ln -s $INSTALL_PATH/php/74/bin/php /usr/bin/
        INFO 33 4 "Add $1 soft link to /usr/bin/......"
    fi
}

#CONFIG_HTTPD函数用来配置nginx。
function CONFIG_HTTP() {
    INFO 32 3 "Configure the nginx......"
    if id -u www > /dev/null 2>&1; then
        echo "www user exists"
    else
        useradd -M -s /sbin/nologin www
    fi
    [ -z "$(grep ^'export PATH=' /etc/profile)" ] && echo "export PATH=${INSTALL_PATH}/tengine/sbin:\$PATH" >> /etc/profile
    [ -n "$(grep ^'export PATH=' /etc/profile)" -a -z "$(grep ${INSTALL_PATH}/tengine /etc/profile)" ] && sed -i "s@^export PATH=\(.*\)@export PATH=${INSTALL_PATH}/tengine/sbin:\1@" /etc/profile
    . /etc/profile
    mkdir -p /server/wwwlogs
    mkdir -p $INSTALL_PATH/stop
    mkdir -p $INSTALL_PATH/tengine/tmp/client_body_temp
    mkdir -p $INSTALL_PATH/tengine/conf/vhost
    mkdir -p $INSTALL_PATH/tengine/conf/rewrite
    chown -R www:www $INSTALL_PATH/tengine/html
    chown -R www:www /server/wwwlogs
    cp -rf $CONF_PATH/tengine/stop/*.html $INSTALL_PATH/stop/
    cp -rf $CONF_PATH/tengine/rewrite/*.conf $INSTALL_PATH/tengine/conf/rewrite/
    cp -rf $CONF_PATH/tengine/conf/*.conf $INSTALL_PATH/tengine/conf/
    cp -rf $CONF_PATH/tengine/vhost/*.conf $INSTALL_PATH/tengine/conf/vhost/
    cp -rf $CONF_PATH/tengine/init/nginx_service.sh /etc/init.d/nginx
    chmod +x /etc/init.d/nginx
    ${INSTALL_PATH}/tengine/sbin/nginx -v
    INFO 35 2 "Nginx configuration is complete......"
    endTime=$(date +%s)
    ((installTime = (endTime - startTime) / 60))
    echo "Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes"
    chkconfig --add nginx
    systemctl start nginx
    if [ $? -eq 0 ]; then
        INFO 33 "2.5" "Nginx startup success......"
    else
        INFO 31 "2.5" "Nginx startup failed!"
    fi
}
#CONFIG_PHP函数用来配置php。
function CONFIG_PHP() {
    INFO 32 3 "Configure the php......"
    if id -u www > /dev/null 2>&1; then
        echo "www user exists"
    else
        useradd -M -s /sbin/nologin www
    fi
    echo -e "<?php\nphpinfo();\n?>" > $INSTALL_PATH/tengine/html/phpinfo.php
    cp $CONF_PATH/php/php.ini $INSTALL_PATH/php/74/etc/php.ini
    cp -f $CONF_PATH/php/php-fpm-74.conf $INSTALL_PATH/php/74/etc/php-fpm.conf
    cp -rf $CONF_PATH/php/php_service.sh /etc/init.d/php-fpm
    sed -i '$ a#extension = amqp.so\nextension = imagick.so\nextension = mcrypt.so\nextension = memcache.so\nextension = mongodb.so\nextension = redis.so\nextension = ssh2.so\nextension = swoole.so\nextension = yaf.so\nextension = yaml.so\nextension = yar.so' $INSTALL_PATH/php/74/etc/php.ini
    chmod +x /etc/init.d/php-fpm
    chkconfig --add php-fpm
    ln -s $INSTALL_PATH/php/74/bin/php /usr/bin/php
    yum clean all && rm -rf /var/cache/yum/*
    /usr/bin/php -v
    pushd ${SOURCE_PATH} > /dev/null
    rm -rf nettle-3.6 libzip-1.7.3 libevent-2.1.12 php-7.4.11 amqp-1.10.2 imagick-3.4.4 \
        mcrypt-1.0.3 memcache-4.0.5.2 mongodb-1.8.1 php_redis-5.3.1 ssh2-1.2 \
        swoole-4.5.4 yaf-3.2.5 yaml-2.1.0 yar-2.1.2 libsodium-1.0.18-stable
    popd > /dev/null
    INFO 35 2 "Php configuration is complete......"
    endTime=$(date +%s)
    ((installTime = (endTime - startTime) / 60))
    echo "Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes"
    systemctl start php-fpm
    if [ $? -eq 0 ]; then
        INFO 33 2.5 "PHP startup success......"
    else
        INFO 31 2.5 "PHP startup failed!"
    fi
}
#CONFIG_MYSQL函数用来定义mysql的配置。
function CONFIG_MYSQL() {
    INFO 32 3 "Configure the mysql......"
    useradd -M -s /sbin/nologin mysql
    ln -s $INSTALL_PATH/mysql/bin/mysql /usr/bin/mysql
    ln -s $INSTALL_PATH/mysql/bin/mysqld /usr/bin/mysqld
    ln -s $INSTALL_PATH/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
    sleep 1
    mkdir -p $INSTALL_PATH/data
    mkdir -p $INSTALL_PATH/phpmyadmin
    sleep 1
    sed -i 's/chown 0 "$pamtooldir/#&/' /$INSTALL_PATH/mysql/scripts/mariadb-install-db
    sed -i 's/chmod 04755 "$pamtooldir/#&/' $INSTALL_PATH/mysql/scripts/mariadb-install-db
    sed -i 's/chown $user "$pamtooldir/#&/' $INSTALL_PATH/mysql/scripts/mariadb-install-db
    sed -i 's/chmod 0700 "$pamtooldir/#&/' $INSTALL_PATH/mysql/scripts/mariadb-install-db
    sleep 1
    cp -r $CONF_PATH/mariadb/my.cnf /etc/my.cnf
    chown -R mysql:mysql $INSTALL_PATH/data
    chown -R mysql:mysql $INSTALL_PATH/mysql
    echo ""
    sleep 1
    ./scripts/mysql_install_db \
        --user=mysql \
        --basedir=$INSTALL_PATH/mysql \
        --datadir=$INSTALL_PATH/data \
        --defaults-file=/etc/my.cnf
    cp $INSTALL_PATH/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    mysqld -V
    sleep 2
    tar zxvf $SOURCE_PATH/phpMyAdmin-5.0.4.tar.gz -C $INSTALL_PATH/phpmyadmin/
    cd $INSTALL_PATH/phpmyadmin/
    pwd
    mv phpMyAdmin-5.0.4 phpmyadmin_bbd2dd3db68ba46a
    yum clean all && rm -rf /var/cache/yum/*
    INFO 35 2 "Mysql configuration is complete......"
    endTime=$(date +%s)
    ((installTime = (endTime - startTime) / 60))
    echo "Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes"
    chkconfig --add mysqld
    systemctl start mysqld
    if [ $? -eq 0 ]; then
        INFO 33 "2.5" "MariaDB startup success......"
    else
        INFO 31 "2.5" "MariaDB startup failed!"
    fi
}
#CONFIG_REDIS函数用来定义redis的配置。
function CONFIG_MEMCACHED() {
    useradd -M -s /sbin/nologin memcached
    cp -r $CONF_PATH/memcached/service.sh /etc/init.d/memcached
    chmod +x /etc/init.d/memcached
    touch /etc/rc.d/init.d/functions
    INFO 35 2 "Memcached configuration is complete......"
    endTime=$(date +%s)
    ((installTime = (endTime - startTime) / 60))
    echo "Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes"
    chown -R memcached:memcached /server/lnmp/memcached
    chkconfig --add memcached
    systemctl start memcached
    INFO 33 "2.5" "Memcached startup success......"
}
#CONFIG_REDIS函数用来定义redis的配置。
function CONFIG_REDIS() {
    ln -s $INSTALL_PATH/redis/bin/redis-benchmark /usr/bin/
    ln -s $INSTALL_PATH/redis/bin/redis-cli /usr/bin/
    ln -s $INSTALL_PATH/redis/bin/redis-server /usr/bin/
    sed -i 's/daemonize no/daemonize yes/g' $INSTALL_PATH/redis/etc/redis.conf
    sed -i 's/timeout 0/timeout 300/g' $INSTALL_PATH/redis/etc/redis.conf
    sed -i 's/loglevel notice/loglevel verbose/g' $INSTALL_PATH/redis/etc/redis.conf
    sed -i 's/logfile ""/logfile stdout/g' $INSTALL_PATH/redis/etc/redis.conf
    sed -i '/# bind 127.0.0.1 ::1/a\bind 127.0.0.1' $INSTALL_PATH/redis/etc/redis.conf
    sed -i '/# requirepass foobared/a\requirepass 123456' $INSTALL_PATH/redis/etc/redis.conf
    cp -rf $CONF_PATH/redis/redis_service.sh /etc/init.d/redis
    chmod +x /etc/init.d/redis
    INFO 35 2 "Redis configuration is complete......"
    endTime=$(date +%s)
    ((installTime = (endTime - startTime) / 60))
    echo "Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes"
    chkconfig --add redis
    systemctl start redis
    INFO 33 "2.5" "Redis startup success......"
}
#INSTALL_BRANCH函数定义程序安装，${TAR_NAME[@]}是shell脚本中数组写法，即取全部元素，即TAR_NAME里面的所有包，SERVER_NAME表示包的名称，COMPILE_DIR表示包名+版本后，即解压后的目录名。
function INSTALL_BRANCH() {
    for i in ${TAR_NAME[@]}; do
        SERVER_NAME=$(echo $i | awk -F "-[0-9]" '{print $1}' || awk -F "-[0-9]-[A-Za-z]" '{print $1}')
        COMPILE_DIR=$(echo $i | awk -F ".tar.gz|.tgz" '{print $1}')
        if [ $1 = $SERVER_NAME -a $1 = openssl ]; then
            INSTALL openssl " " "$COMPILE_DIR" "$i" "-Wl,-rpath=${openssl_install_dir}/lib -fPIC --prefix=$ENV_PATH/openssl --openssldir=$ENV_PATH/openssl"
        elif [ $1 = $SERVER_NAME -a $1 = jemalloc ]; then
            INSTALL jemalloc "$REDIS_YUM" "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/jemalloc"
        elif [ $1 = $SERVER_NAME -a $1 = zlib ]; then
            INSTALL zlib " " "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/zlib"
        elif [ $1 = $SERVER_NAME -a $1 = pcre ]; then
            INSTALL pcre " " "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/pcre"
        elif [ $1 = $SERVER_NAME -a $1 = tengine ]; then
            INSTALL nginx "$HTTP_YUM" "$COMPILE_DIR" "$i" "$HTTP_PARAMETERS"
            CONFIG_HTTP
        elif [ $1 = $SERVER_NAME -a $1 = libsodium ]; then
            INSTALL libsodium "" "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/libsodium --disable-dependency-tracking --enable-minimal"
        elif [ $1 = $SERVER_NAME -a $1 = libssh2 ]; then
            INSTALL libssh2 " " "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/libssh2"
        elif [ $1 = $SERVER_NAME -a $1 = nettle ]; then
            INSTALL nettle "" "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/nettle"
        elif [ $1 = $SERVER_NAME -a $1 = libzip ]; then
            INSTALL libzip " " "$COMPILE_DIR" "$i" "-DCMAKE_INSTALL_PREFIX=$ENV_PATH/libzip"
        elif [ $1 = $SERVER_NAME -a $1 = libevent ]; then
            INSTALL libevent " " "$COMPILE_DIR" "$i" "--prefix=$ENV_PATH/libevent"
        elif [ $1 = $SERVER_NAME -a $1 = argon2 ]; then
            INSTALL argon2 "$PHP7_YUM" "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = php ]; then
            INSTALL php7 "" "$COMPILE_DIR" "$i" "$PHP7_PARAMETERS"
        elif [ $1 = $SERVER_NAME -a $1 = amqp ]; then
            INSTALL amqp " " "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = imagick ]; then
            INSTALL imagick " " "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = mcrypt ]; then
            INSTALL mcrypt " " "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = memcache ]; then
            INSTALL memcache " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = mongodb ]; then
            INSTALL mongodb " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = php_redis ]; then
            INSTALL php_redis " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = ssh2 ]; then
            INSTALL ssh2 " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = swoole ]; then
            INSTALL swoole " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = yaf ]; then
            INSTALL yaf " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = yaml ]; then
            INSTALL yaml " " "$COMPILE_DIR" "$i" " "
        elif [ $1 = $SERVER_NAME -a $1 = yar ]; then
            INSTALL yar " " "$COMPILE_DIR" "$i" " "
            CONFIG_PHP "$COMPILE_DIR"
        elif [ $1 = $SERVER_NAME -a $1 = mariadb ]; then
            INSTALL mysql "$MYSQL_YUM" "$COMPILE_DIR" "$i" "$MYSQL_PARAMETERS"
            CONFIG_MYSQL
        elif [ $1 = $SERVER_NAME -a $1 = memcached ]; then
            INSTALL memcached " " "$COMPILE_DIR" "$i" "$MEMCACHED_PARAMETERS"
            CONFIG_MEMCACHED "$COMPILE_DIR"
        elif [ $1 = $SERVER_NAME -a $1 = redis ]; then
            INSTALL redis " " "$COMPILE_DIR" "$i" "$REDIS_PARAMETERS"
            CONFIG_REDIS "$COMPILE_DIR"
            break
        else
            continue
        fi
    done
}
#MOD_CASE函数用KASE定义选择安装程序。
function MOD_CASE() {
    if [[ $1 =~ nginx|mysql|php|memcached|redis ]] && [[ $2 =~ install|start|stop|restart ]]; then
        INFO 32 2 "Input the correct,according to the option to perform related operations......"
        if [ $2 = install ]; then
            INFO 32 1 "Delete redundant accounts."
            userdel -r adm
            userdel -r lp
            userdel -r games
            userdel -r ftp
            groupdel adm
            groupdel lp
            groupdel games
            groupdel video
            groupdel ftp
            case "$1 $2" in
                "nginx install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    pushd ${SOURCE_PATH} > /dev/null
                    tar xzf jemalloc-5.2.1.tar.gz
                    tar xzf pcre-8.44.tar.gz
                    tar xzf openssl-1.1.1i.tar.gz
                    tar xzf zlib-1.2.11.tar.gz
                    popd > /dev/null
                    if [ -e "${ENV_PATH}/openssl/lib/libssl.a" ]; then
                        INFO 31 1 "OpenSSL is already installed!"
                    else
                        INSTALL_BRANCH openssl
                    fi
                    #INSTALL_BRANCH jemalloc
                    #INSTALL_BRANCH zlib
                    #INSTALL_BRANCH pcre
                    INSTALL_BRANCH tengine
                    ;;
                "php install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    INSTALL_BRANCH argon2
                    if [ ! -f $ENV_PATH/openssl/lib/libssl.so ] && [ ! -f $ENV_PATH/openssl/lib/libcrypto.so ]; then
                        INSTALL_BRANCH openssl
                        . /etc/profile
                    else
                        INFO 35 1 "OpenSSL is already installed."
                    fi
                    INSTALL_BRANCH libsodium
                    INSTALL_BRANCH libssh2
                    INSTALL_BRANCH nettle
                    INSTALL_BRANCH libzip
                    INSTALL_BRANCH libevent
                    INSTALL_BRANCH php
                    ln -sf $INSTALL_PATH/php/74/bin/phpize /usr/bin/phpize
                    ln -sf $INSTALL_PATH/php/74/bin/php-config /usr/bin/php-config
                    INSTALL_BRANCH amqp
                    INSTALL_BRANCH imagick
                    INSTALL_BRANCH mcrypt
                    INSTALL_BRANCH memcache
                    INSTALL_BRANCH mongodb
                    INSTALL_BRANCH php_redis
                    INSTALL_BRANCH ssh2
                    INSTALL_BRANCH swoole
                    INSTALL_BRANCH yaf
                    INSTALL_BRANCH yaml
                    INSTALL_BRANCH yar
                    ;;
                "mysql install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    INSTALL_BRANCH mariadb
                    ;;
                "memcached install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    INSTALL_BRANCH memcached
                    ;;
                "redis install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    if [ ! -f $ENV_PATH/jemalloc/lib/libjemalloc.so ] && [ ! -f $ENV_PATH/jemalloc/lib/libjemalloc.so ]; then
                        INSTALL_BRANCH jemalloc
                    else
                        INFO 35 1 "jemalloc is already installed."
                    fi
                    INSTALL_BRANCH redis
                    ;;
            esac
        else
            SERVICE $1 $2
        fi
    else
        INFO 31 1 "Input error, please try again!"
        INPUT
        USAGE
    fi
}
#LNMP程序安装的目录
INSTALL_PATH="/server/lnmp"
#LNMP配置文件的目录
CONF_PATH="/data/lnmp/conf"
#资源包安装目录
ENV_PATH="/usr/local"
#源码包存放目录
SOURCE_PATH="$(
    cd $(dirname $0)
    pwd
)/install_tar"
#源码包列表
TAR_NAME=(tengine-2.3.2.tar.gz jemalloc-5.2.1.tar.gz libssh2-1.9.0.tar.gz openssl-1.1.1i.tar.gz pcre-8.44.tar.gz zlib-1.2.11.tar.gz libzip-1.7.3.tar.gz mariadb-10.5.6.tar.gz php-7.4.11.tar.gz amqp-1.10.2.tgz imagick-3.4.4.tgz mcrypt-1.0.3.tgz memcache-4.0.5.2.tgz mongodb-1.8.1.tgz nettle-3.6.tar.gz php_redis-5.3.1.tgz ssh2-1.2.tgz swoole-4.5.4.tgz yaf-3.2.5.tgz yaml-2.1.0.tgz yar-2.1.2.tgz redis-6.0.8.tar.gz libevent-2.1.12.tar.gz memcached-1.6.7.tar.gz phpMyAdmin-5.0.4.tar.gz libsodium-1.0.18-stable.tar.gz argon2-20190702.tar.gz)
#Nginx,Mysql,PHP,memcached,Redis yum安装依赖包
HTTP_YUM="gcc gcc-c++ bzip2-devel"
MYSQL_YUM="bison-devel libcurl-devel libarchive-devel boost-devel gcc gcc-c++ cmake ncurses-devel gnutls-devel libxml2-devel libaio-devel"
PHP7_YUM="autoconf cmake3 gcc-c++ m4 krb5-devel mbedtls-devel libxml2-devel bzip2-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel gmp-devel libmcrypt-devel readline-devel libxslt-devel glibc-devel glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel libmemcached-devel librabbitmq librabbitmq-devel ImageMagick-devel libsqlite3x-devel oniguruma-devel openldap-devel libyaml-devel"
MEMCACHED_YUM=""
REDIS_YUM=" centos-release-scl devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils"
#Tengine编译参数
HTTP_PARAMETERS="\
--prefix=/server/lnmp/tengine --conf-path=/server/lnmp/tengine/conf/nginx.conf \
--error-log-path=/server/lnmp/tengine/var/log/nginx_error.log \
--http-log-path=/server/lnmp/tengine/var/log/nginx_access.log \
--pid-path=/server/lnmp/tengine/var/run/nginx.pid \
--lock-path=/server/lnmp/tengine/var/lock/nginx.lock \
--user=www --group=www --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module \
--with-http_realip_module --with-http_flv_module --with-http_mp4_module --with-http_sub_module \
--with-http_dav_module --with-http_random_index_module --with-http_secure_link_module \
--with-http_stub_status_module --with-http_addition_module \
--with-jemalloc=../jemalloc-5.2.1 \
--with-openssl=../openssl-1.1.1i \
--with-zlib=../zlib-1.2.11 \
--with-pcre=../pcre-8.44 \
--http-client-body-temp-path=$INSTALL_PATH/tengine/tmp/client_body_temp \
--http-proxy-temp-path=$INSTALL_PATH/tengine/tmp/proxy_temp \
--http-fastcgi-temp-path=$INSTALL_PATH/tengine/tmp/fcgi_temp \
--http-uwsgi-temp-path=$INSTALL_PATH/tengine/tmp/uwsgi_temp \
--http-scgi-temp-path=$INSTALL_PATH/tengine/tmp/scgi_temp
"
#PHP编译参数
PHP7_PARAMETERS="\
--prefix=${INSTALL_PATH}/php/74 --with-config-file-path=/server/lnmp/php/74/etc \
--with-config-file-scan-dir=${INSTALL_PATH}/php/74/etc/php.d \
--with-fpm-user=www --with-fpm-group=www --enable-fpm --enable-opcache --disable-fileinfo \
--enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
--with-iconv --with-freetype --with-jpeg --with-zlib \
--enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
--enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex \
--enable-mbstring --with-password-argon2 --with-sodium --enable-gd --with-openssl=/usr/local/openssl \
--with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp --enable-intl --with-xsl \
--with-gettext --with-zip --enable-soap --enable-pdo --enable-shared --enable-calendar \
--enable-sysvshm --with-bz2 --with-kerberos --with-libdir --with-pdo-sqlite --with-pear --disable-debug
"

#mysql编译参数
MYSQL_PARAMETERS="\
-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH/mysql \
-DYSQL_TCP_PORT=3306 \
-DSYSCONFDIR=/etc \
-DMYSQL_DATADIR=$INSTALL_PATH/data \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DWITH_LOBWRAP=0 \
-DWIYH_READLINE=1 \
-DWIYH_SSL=system \
-DVITH_ZLIB=system \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STPRAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DEXTRA_CHARSETS=all \
-DWITHOUT_TOKUDB=1 \
-DWITH_DEBUG=0 \
"
#memcached编译参数
MEMCACHED_PARAMETERS="\
--prefix=$INSTALL_PATH/memcached \
--with-libevent=/usr/local/libevent/lib \
"
#redis编译参数
REDIS_PARAMETERS="\
PREFIX=$INSTALL_PATH/redis \
"

#脚本调用帮助程序
if [ $# = 2 ]; then
    INFO 33 "1.5" "please wait......"
    echo ""
    MOD_CASE "$1" "$2"
else
    USAGE
    exit 1
fi