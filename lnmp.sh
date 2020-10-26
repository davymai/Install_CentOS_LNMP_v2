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
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

#INFO函数定义输出字体颜色，echo -e 表示保持字符串的特殊含义，$1表示字体颜色编号，$2表示等待程序执行时间，$3表示echo输出内容。
function INFO() {
    echo -e "\e[$1;49;1m: $3 \033[39;49;0m"
    sleep "$2"
    echo ""
}
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
        "$(echo -e "Usage: \n\n./$basename ( nginx|mysql|php|memcached|redis ) install \nsystemctl (start|stop|restart|status) nginx|mysql|php|memcached|redis \n")"
}
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
    INFO 32 4 "Configure the $1......"
    if [ $1 = nginx ]; then
        tar zxvf $SOURCE_PATH/pcre-8.44.tar.gz
        tar zxvf $SOURCE_PATH/openssl-1.1.1h.tar.gz
        tar zxvf $SOURCE_PATH/zlib-1.2.11.tar.gz
        tar zxvf $SOURCE_PATH/jemalloc-5.2.1.tar.gz
        ./configure $5 || exit 1
    elif [ $1 = mysql ]; then
        cmake $5 || exit 1
    elif [ $1 = libzip ]; then
        mkdir build && cd build
        cmake3 .. || exit 1
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
    elif [ $1 = jpegsrc.v6b.tar.gz ]; then
        cp /usr/share/libtool/config.guess ./
        cp /usr/share/libtool/config.sub ./
        ./configure $5 || exit 1
        mkdir -p /usr/local/env/jpeg/bin
        mkdir -p /usr/local/env/jpeg/lib
        mkdir -p /usr/local/env/jpeg/include
        mkdir -p /usr/local/env/jpeg/man/man1
    else
        ./configure $5 || exit 1
    fi
    INFO 36 3 "Compile $1......"
    make -j6 || exit 1 && INFO 34 4 "Install $1......"
    make install && INFO 33 4 "$1 installation is successful......"
    if [ $1 = nginx ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
        echo "/usr/local/lib64" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
        echo "PKG_CONFIG_PATH=/usr/lib64/pkgconfig/:/usr/local/lib64/pkgconfig/:/usr/local/lib/pkgconfig/:/usr/share/pkgconfig" >> /etc/profile
        echo "export PKG_CONFIG_PATH" >> /etc/profile
        source /etc/profile
        ldconfig && INFO 33 4 "Add $1 PKG_CONFIG_PATH to /etc/profile......"
    fi
    if [ $1 = libzip ]; then
        source /etc/profile
        ldconfig && INFO 33 4 "Add $1 PKG_CONFIG_PATH to /etc/profile......"
    fi
    if [ $1 = php ]; then
        ln -s $INSTALL_PATH/php/74/bin/php /usr/bin/
        INFO 33 4 "Add $1 soft link to /usr/bin/......"
        echo "/usr/local/lib" >> /etc/ld.so.conf
        echo "/usr/local/lib64" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = libmcrypt ]; then
        echo "/usr/local/env/libmcrypt/lib" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = mhash ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
        echo "/usr/local/lib64" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = gettext ]; then
        echo "/usr/local/env/gettext/lib" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = gd ]; then
        sed -i '27 a void (*data);' /usr/local/env/gd/include/gd_io.h
        echo "/usr/local/env/gd/lib" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = freetype ]; then
        echo "/usr/local/env/freetype/lib" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add $1 library file to ld.so.conf......"
    fi
    if [ $1 = jpegsrc.v6b.tar.gz ]; then
        echo "/usr/local/env/jpeg/lib" >> /etc/ld.so.conf
        ldconfig && INFO 33 4 "Add jpeg library file to ld.so.conf......"
    fi
}

#CONFIG_HTTPD函数用来配置nginx。
function CONFIG_HTTP() {
    INFO 32 3 "Configure the nginx......"
    useradd -M -s /sbin/nologin www
    echo -e "<?php\nphpinfo();\n?>" > $INSTALL_PATH/nginx/html/phpinfo.php
    chown -R www:www $INSTALL_PATH/nginx/html
    mkdir -p $INSTALL_PATH/nginx/tmp/client_body_temp
    mkdir -p $INSTALL_PATH/nginx/conf/vhost
    mkdir -p $INSTALL_PATH/nginx/conf/rewrite
    cp -rf $CONF_PATH/nginx/rewrite/*.conf $INSTALL_PATH/nginx/conf/rewrite/
    cp -rf $CONF_PATH/nginx//conf/*.conf $INSTALL_PATH/nginx/conf/
    cp -rf $CONF_PATH/nginx/vhost/*.conf $INSTALL_PATH/nginx/conf/vhost/
    cp -rf $CONF_PATH/nginx/init/nginx_service.sh /etc/init.d/nginx
    chmod +x /etc/init.d/nginx
    ln -s $INSTALL_PATH/nginx/sbin/nginx /usr/bin/nginx
    /usr/bin/nginx -v
    INFO 35 2 "Nginx configuration is complete......"
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
    cp $CONF_PATH/php/php.ini $INSTALL_PATH/php/74/etc/php.ini
    cp -f $CONF_PATH/php/php-fpm-74.conf $INSTALL_PATH/php/74/etc/php-fpm.conf
    cp -rf $CONF_PATH/php/php_service.sh /etc/init.d/php-fpm
    sed -i '$ a#extension = amqp.so\nextension = imagick.so\nextension = mcrypt.so\nextension = memcache.so\nextension = mongodb.so\nextension = redis.so\nextension = ssh2.so\nextension = swoole.so\nextension = yaf.so\nextension = yaml.so\nextension = yar.so' $INSTALL_PATH/php/74/etc/php.ini
    chmod +x /etc/init.d/php-fpm
    chkconfig --add php-fpm
    ln -s $INSTALL_PATH/php/74/bin/php /usr/bin/php
    /usr/bin/php -v
    INFO 35 2 "Php configuration is complete......"
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
    ln -s $INSTALL_PATH/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
    sleep 1
    mkdir -p $INSTALL_PATH/data
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
    sleep 2
    ./scripts/mysql_install_db \
        --user=mysql \
        --basedir=$INSTALL_PATH/mysql \
        --datadir=$INSTALL_PATH/data \
        --defaults-file=/etc
    cp $INSTALL_PATH/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    sleep 1
    mysql -V
    INFO 35 2 "Mysql configuration is complete......"
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
    INFO 35 2 "Memcached configuration is complete......"
    chown -R memcached:memcached /server/lnmp/memcached
    ln -s /usr/local/lib/libevent-2.1.so.7 /usr/lib64/libevent-2.1.so.7
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
    sed -i '/# bind 127.0.0.1 ::1/a\\bind 127.0.0.1' $INSTALL_PATH/redis/etc/redis.conf
    sed -i '/# requirepass foobared/a\requirepass 123456' $INSTALL_PATH/redis/etc/redis.conf
    cp -rf $CONF_PATH/redis/redis_service.sh /etc/init.d/redis
    chmod +x /etc/init.d/redis
    INFO 35 2 "Redis configuration is complete......"
    chkconfig --add redis
    systemctl start redis
    INFO 33 "2.5" "Redis startup success......"
}
#INSTALL_BRANCH函数定义程序安装，${TAR_NAME[@]}是shell脚本中数组写法，即取全部元素，即TAR_NAME里面的所有包，SERVER_NAME表示包的名称，COMPILE_DIR表示包名+版本后，即解压后的目录名。
function INSTALL_BRANCH() {
    for i in ${TAR_NAME[@]}; do
        SERVER_NAME=$(echo $i | awk -F "-[0-9]" '{print $1}')
        COMPILE_DIR=$(echo $i | awk -F ".tar.gz|.tgz" '{print $1}')
        if [ $1 = $SERVER_NAME -a $1 = tengine ]; then
            INSTALL nginx "$HTTP_YUM" "$COMPILE_DIR" "$i" "$HTTP_PARAMETERS"
            CONFIG_HTTP
        elif [ $1 = $SERVER_NAME -a $1 = mariadb ]; then
            INSTALL mysql "$MYSQL_YUM" "$COMPILE_DIR" "$i" "$MYSQL_PARAMETERS"
            CONFIG_MYSQL
        elif [ $1 = $SERVER_NAME -a $1 = nettle ]; then
            INSTALL nettle "$PHP7_YUM" "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = libzip ]; then
            INSTALL libzip " " "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = php ]; then
            INSTALL php7 " " "$COMPILE_DIR" "$i" "$PHP7_PARAMETERS"
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
        elif [ $1 = $SERVER_NAME -a $1 = libevent ]; then
            INSTALL libevent " " "$COMPILE_DIR" "$i" ""
        elif [ $1 = $SERVER_NAME -a $1 = memcached ]; then
            INSTALL memcached " " "$COMPILE_DIR" "$i" "$MEMCACHED_PARAMETERS"
            CONFIG_MEMCACHED "$COMPILE_DIR"
        elif [ $1 = $SERVER_NAME -a $1 = redis ]; then
            INSTALL redis "$REDIS_YUM" "$COMPILE_DIR" "$i" "$REDIS_PARAMETERS"
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
        INFO 32 "1.5" "Input the correct,according to the option to perform related operations......"
        echo ""
        if [ $2 = install ]; then
            case "$1 $2" in
                "nginx install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    userdel -r adm
                    userdel -r lp
                    userdel -r games
                    userdel -r ftp
                    groupdel adm
                    groupdel lp
                    groupdel games
                    groupdel video
                    groupdel ftp
                    INSTALL_BRANCH tengine
                    ;;
                "mysql install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    userdel -r adm
                    userdel -r lp
                    userdel -r games
                    userdel -r ftp
                    groupdel adm
                    groupdel lp
                    groupdel games
                    groupdel video
                    groupdel ftp
                    INSTALL_BRANCH mariadb
                    ;;
                "php install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    export LD_LIBRARY_PATH=/lib/:/usr/lib/:/usr/local/lib:/server/lnmp/mysql/lib
                    userdel -r adm
                    userdel -r lp
                    userdel -r games
                    userdel -r ftp
                    groupdel adm
                    groupdel lp
                    groupdel games
                    groupdel video
                    groupdel ftp
                    INSTALL_BRANCH nettle
                    INSTALL_BRANCH libzip
                    INSTALL_BRANCH php
                    rm -rf /usr/bin/phpize
                    ln -s $INSTALL_PATH/php/74/bin/phpize /usr/bin/phpize
                    rm -rf /usr/bin/php-config
                    ln -s $INSTALL_PATH/php/74/bin/php-config /usr/bin/php-config
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
                "memcached install")
                    INFO 35 "2.5" "Start to $2 the $1......"
                    INSTALL_BRANCH libevent
                    INSTALL_BRANCH memcached
                    ;;
                "redis install")
                    INFO 35 "2.5" "Start to $2 the $1......"
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
ENV_PATH="/usr/local/env"
#源码包存放目录
SOURCE_PATH="$(
    cd $(dirname $0)
    pwd
)/install_tar"
#源码包列表
TAR_NAME=(tengine-2.3.2.tar.gz jemalloc-5.2.1.tar.gz openssl-1.1.1h.tar.gz pcre-8.44.tar.gz zlib-1.2.11.tar.gz libzip-1.7.3.tar.gz mariadb-10.5.6.tar.gz php-7.4.11.tar.gz amqp-1.10.2.tgz imagick-3.4.4.tgz mcrypt-1.0.3.tgz memcache-4.0.5.2.tgz mongodb-1.8.1.tgz nettle-3.6.tar.gz php_redis-5.3.1.tgz ssh2-1.2.tgz swoole-4.5.4.tgz yaf-3.2.5.tgz yaml-2.1.0.tgz yar-2.1.2.tgz redis-6.0.8.tar.gz libevent-2.1.12.tar.gz memcached-1.6.7.tar.gz)
#Nginx,Mysql,PHP,memcached,Redis yum安装依赖包
HTTP_YUM="gcc gcc-c++ bzip2"
MYSQL_YUM="bison-devel zlib-devel libcurl-devel libarchive-devel boost-devel gcc gcc-c++ cmake ncurses-devel gnutls-devel libxml2-devel openssl-devel libaio-devel"
PHP7_YUM="autoconf cmake3 m4 mbedtls-devel libxml2-devel bzip2-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel gmp-devel libmcrypt-devel readline-devel libxslt-devel zlib-devel glibc-devel glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel libmemcached-devel librabbitmq librabbitmq-devel ImageMagick-devel libyaml libyaml-devel libssh2-devel libsqlite3x-devel oniguruma-devel openldap-devel"
MEMCACHED_YUM=""
REDIS_YUM="kernel-devel centos-release-scl devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils"
#Nginx编译参数
HTTP_PARAMETERS="\
--prefix=/server/lnmp/nginx \
--conf-path=/server/lnmp/nginx/conf/nginx.conf \
--error-log-path=/server/lnmp/nginx/var/log/nginx_error.log \
--http-log-path=/server/lnmp/nginx/var/log/nginx_access.log \
--pid-path=/server/lnmp/nginx/var/run/nginx.pid \
--lock-path=/server/lnmp/nginx/var/lock/nginx.lock \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_addition_module \
--with-jemalloc=$SOURCE_PATH/tengine-2.3.2/jemalloc-5.2.1 \
--with-openssl=$SOURCE_PATH/tengine-2.3.2/openssl-1.1.1h \
--with-zlib=$SOURCE_PATH/tengine-2.3.2/zlib-1.2.11 \
--with-pcre=$SOURCE_PATH/tengine-2.3.2/pcre-8.44 \
--http-client-body-temp-path=$INSTALL_PATH/nginx/tmp/client_body_temp \
--http-proxy-temp-path=$INSTALL_PATH/nginx/tmp/proxy_temp \
--http-fastcgi-temp-path=$INSTALL_PATH/nginx/tmp/fcgi_temp \
--http-uwsgi-temp-path=$INSTALL_PATH/nginx/tmp/uwsgi_temp \
--http-scgi-temp-path=$INSTALL_PATH/nginx/tmp/scgi_temp
"
#PHP编译参数
PHP7_PARAMETERS="\
--prefix=/server/lnmp/php/74 \
--with-config-file-path=/server/lnmp/php/74/etc \
--with-fpm-user=www \
--with-fpm-group=www \
--enable-bcmath \
--enable-calendar \
--enable-exif \
--enable-fpm \
--enable-gd \
--enable-inline-optimization \
--enable-mbregex \
--enable-mbstring \
--enable-opcache \
--enable-pcntl \
--enable-pdo \
--enable-shared \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-xml \
--with-bz2 \
--with-curl \
--with-gettext \
--with-iconv \
--with-kerberos \
--with-libdir=lib64 \
--with-mhash \
--with-mysqli=mysqlnd \
--with-openssl \
--with-pdo-mysql=mysqlnd \
--with-pdo-sqlite \
--with-pear \
--with-xmlrpc \
--with-xsl \
--with-zip \
--with-zlib \
--with-zlib-dir=lib64 \
--disable-debug
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
--with-libevent=/usr/local/lib/ \
"
#redis编译参数
REDIS_PARAMETERS="\
PREFIX=$INSTALL_PATH/redis \
"
#--disable-rpath
#脚本调用帮助程序
if [ $# = 2 ]; then
    INFO 33 "1.5" "please wait......"
    echo ""
    MOD_CASE "$1" "$2"
else
    USAGE
    exit 1
fi
