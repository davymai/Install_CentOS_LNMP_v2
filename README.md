# Install_CentOS_LNMP_v2
一键初始化CentOS & 安装LNMP环境

## 目录
LNMP目录: /server/lnmp

nginx:   /server/lnmp/nginx

MariaDB: /server/lnmp/mysql

PHP:     /server/lnmp/php/74

web:     /server/lnmp/nginx/html

log:     /server/wwwlog/

phpMyAdmin: /server/lnmp/phpmyadmin


phpMyAdmin访问地址：http://myserver.com:887

---

### centos7init.sh

CentOS初始化脚本

在这个脚本里我用axel替代了wget下载工具，平常我们下载一些国外资源的时候用wget非常缓慢，使用axel可以提升下载效率。

脚本同时支持手动创建用户及设置远程端口，把脚本中 user_create 下的#号去掉即可

使用方法：
>sh centos7init.sh

---

### lnmp.sh

1）系统环境介绍

CentOS Linux release 7.8.2003 (Core) 64位

Nginx: tengine-2.3.2.tar.gz (nginx/1.17.3)

PHP  : php-7.4.11.tar.gz

Mysql: mariadb-10.5.6.tar.gz

Redis: redis-6.0.8.tar.gz

Memcached: memcached-1.6.7.tar.gz


2）脚本的用法

>./lnmp.sh

: Please see the script of the usage:

: Usage:

>./lnmp.sh (nginx|mysql|php|redis|memcached) install

>systemctl (start|stop|restart|status) nginx|mysqld|php|redis|memcached

## oh-my-zsh theme

普通用户登录
![普通用户登录](https://xmyunwei.com/wp-content/uploads/2020/10/WX20201025-183925@2x-1024x551.png "普通用户登录")

root用户登录
![root用户登录](https://xmyunwei.com/wp-content/uploads/2020/10/WX20201025-185450@2x-1024x551.png "root用户登录")

