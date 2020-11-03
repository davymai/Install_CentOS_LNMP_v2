#! /bin/sh
# chkconfig: 2345 55 25
# Description: Startup script for nginx webserver on Debian. Place in /etc/init.d and
# run 'update-rc.d -f nginx defaults', or use the appropriate command on your
# distro. For CentOS/Redhat run: 'chkconfig --add nginx'

### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO

# Author:   PandaMan
# website:  https://xmyunwei.com
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH
function INFO() {
    echo -e "\e[$1;49;1m$3 \033[39;49;0m"
    sleep "$2"
}

### 请注意Tengine目录位置！
PREFIX=/server/lnmp/tengine

NGINX_BIN=$PREFIX/sbin/nginx
NGINX_CONF=$PREFIX/conf/nginx.conf
NGINX_PID=$PREFIX/var/run/nginx.pid

case "$1" in
    start)
        echo -n "Starting nginx... "
        if [ -f $NGINX_PID ]; then
            mPID=$(cat $NGINX_PID)
            isStart=$(ps ax | awk '{ print $1 }' | grep -e "^${mPID}$")
            if [ "$isStart" != '' ]; then
                INFO 35 1 "nginx (pid $(pidof nginx)) already running."
                exit 1
            fi
        fi
        $NGINX_BIN -c $NGINX_CONF
        if [ "$?" != 0 ]; then
            INFO 31 2 " failed!"
            exit 1
        else
            INFO 32 2 " done"
        fi
        INFO 33 2 "nginx startup success......"
        ;;

    stop)
        echo -n "Stoping nginx... "
        if [ ! -r $NGINX_PID ]; then
            INFO 31 2 "warning, no pid file found - nginx is not running ?"
            exit 1
        fi
        $NGINX_BIN -s stop
        if [ "$?" != 0 ]; then
            INFO 31 2 " failed!"
            exit 1
        else
            INFO 32 2 " done"
        fi
        INFO 31 2 "nginx has stopped......"
        ;;

    status)
        if [ ! -r $NGINX_PID ]; then
            INFO 31 1.5 "nginx is stopped."
            exit 0
        fi
        PID=$(cat $NGINX_PID)
        if ps -p $PID | grep -q $PID; then
            INFO 35 1.5 "nginx (pid $PID) is running..."
        else
            INFO 31 1.5 "nginx dead but pid file exists."
        fi
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        INFO 34 2 "nginx has restarted......"
        ;;

    reload)
        echo -n "Reload service nginx... "
        if [ ! -r $NGINX_PID ]; then
            INFO 31 2 "warning, no pid file found - nginx is not running ?"
            exit 1
        fi
        $NGINX_BIN -s reload
        INFO 32 2 " done"
        INFO 34 2 "nginx has reloaded......"
        exit
        ;;

    configtest)
        echo -n "Test nginx configure files... "
        $NGINX_BIN -t
        ;;

    *)
        INFO 34 0.5 "Usage: $0 {start|stop|restart|reload|status|configtest}"
        exit 1
        ;;
esac
