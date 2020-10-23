#!/bin/bash
# memcached  - This shell script takes care of starting and stopping memcached.
#
# chkconfig: 2345 90 10
# description: Memcache provides fast memory based storage.
# processname: memcached

# Author:   PandaMan
# website:  https://xmyunwei.com

# 以下配置根据实际情况调整

memcached_user="memcached"
memcached_path="/server/lnmp/memcached/bin/memcached"
memcached_pid="/var/run/memcached.pid"
#分配多少内存（默认：64MB）根据服务器情况调整
memcached_memory="256"
#最大同时连接数，默认是1024
memcached_conn="1024"
#指定监听的地址
memcached_listen="0.0.0.0"
###参数配置结束

# Source function library.
. /etc/rc.d/init.d/functions

[ -x $memcached_path ] || exit 0

RETVAL=0
prog="memcached"

# Start daemons.
start() {
    if [ -e $memcached_pid -a ! -z $memcached_pid ];then
        echo $prog" already running...."
        exit 1
    fi
    echo -n $"Starting $prog "
    # Single instance for all caches
    $memcached_path -m $memcached_memory -c $memcached_conn -l $memcached_listen -p 11211 -u $memcached_user -d -P $memcached_pid
    RETVAL=$?
    [ $RETVAL -eq 0 ] && {
        touch /var/lock/subsys/$prog
        success $"$prog"
    }
    echo
    return $RETVAL
}

# Stop daemons.
stop() {
    echo -n $"Stopping $prog "
    killproc -d 10 $memcached_path
    echo
    [ $RETVAL = 0 ] && rm -f $memcached_pid /var/lock/subsys/$prog


    RETVAL=$?
    return $RETVAL
}


# See how we were called.
case "$1" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        status)
            status $prog
            RETVAL=$?
            ;;
        restart)
            stop
            start
            ;;
        *)
            echo $"Usage: $0 {start|stop|status|restart}"
            exit 1
esac
exit $RETVAL