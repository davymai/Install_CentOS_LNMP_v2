#! /bin/sh
# chkconfig: 2345 55 25
# Description: Startup script for php-fpm webserver on Debian. Place in /etc/init.d and
# run 'update-rc.d -f php-fpm defaults', or use the appropriate command on your
# distro. For CentOS/Redhat run: 'chkconfig --add php-fpm'

### BEGIN INIT INFO
# Provides:          php-fpm
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts php-fpm
# Description:       starts the PHP FastCGI Process Manager daemon
### END INIT INFO

# Author:   PandaMan
# website:  https://xmyunwei.com
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH
function INFO() {
    echo -e "\e[$1;49;1m: $3 \033[39;49;0m"
    sleep "$2"
}

#注意prefix路径根据实际情况填写
PREFIX=/server/lnmp/php/74

PHP_BIN=$PREFIX/sbin/php-fpm
PHP_CONF=$PREFIX/etc/php-fpm.conf
PHP_PID=$PREFIX/var/run/php-fpm.pid

PHP_OPTS="--fpm-config $PHP_CONF --pid $PHP_PID"

wait_for_pid() {
    try=0
    while test $try -lt 35; do
        case "$1" in
            'created')
                if [ -f "$2" ]; then
                    try=''
                    break
                fi
                ;;
            'removed')
                if [ ! -f "$2" ]; then
                    try=''
                    break
                fi
                ;;
        esac
        echo -n .
        try=$(expr $try + 1)
        sleep 1
    done
}

case "$1" in
    start)
        echo -n "Starting php-fpm "
        $PHP_BIN --daemonize $PHP_OPTS
        if [ "$?" != 0 ]; then
            INFO 31 2 " failed!"
            exit 1
        fi
        wait_for_pid created $PHP_PID
        if [ -n "$try" ]; then
            INFO 31 2 " failed!"
            exit 1
        else
            INFO 32 2 " done"
        fi
        ;;

    stop)
        echo -n "Gracefully shutting down php-fpm "

        if [ ! -r $PHP_PID ]; then
            INFO 31 2 "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -QUIT $(cat $PHP_PID)
        wait_for_pid removed $PHP_PID
        if [ -n "$try" ]; then
            INFO 31 2 " failed. Use force-quit"
            exit 1
        else
            INFO 32 2 " done"
        fi
        ;;

    status)
        if [ ! -r $PHP_PID ]; then
            INFO 31 1.5 "php-fpm is stopped."
            exit 0
        fi

        PID=$(cat $PHP_PID)
        if ps -p $PID | grep -q $PID; then
            INFO 35 1.5 "php-fpm (pid $PID) is running..."
        else
            INFO 31 1.5 "php-fpm dead but pid file exists."
        fi
        ;;

    force-quit)
        echo -n "Terminating php-fpm "
        if [ ! -r $PHP_PID ]; then
            INFO 31 2 "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -TERM $(cat $PHP_PID)
        wait_for_pid removed $PHP_PID
        if [ -n "$try" ]; then
            INFO 31 2 " failed."
            exit 1
        else
            INFO 32 2 " done"
        fi
        ;;

    restart)
        $0 stop
        $0 start
        ;;

    reload)
        echo -n "Reload service php-fpm "
        if [ ! -r $PHP_PID ]; then
            INFO 31 2 "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -USR2 $(cat $PHP_PID)
        INFO 32 2 " done"
        ;;
    *)
        INFO 34 0.5 "Usage: $0 {start|stop|force-quit|restart|reload|status}"
        exit 1
        ;;
esac
