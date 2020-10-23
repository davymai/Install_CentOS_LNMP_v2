#!/bin/bash
#chkconfig: 2345 80 90
# Simple Redis init.d script conceived to work on Linux systems
# as it does use of the /proc filesystem.

PATH=/usr/local/bin:/sbin:/usr/bin:/bin
REDISPORT=6379
EXEC=/server/lnmp/redis/bin/redis-server
REDIS_CLI=/server/lnmp/redis/bin/redis-cli

PIDFILE=/var/run/redis.pid
CONF="/server/lnmp/redis/etc/redis.conf"

case "$1" in
    start)
        if [ -f $PIDFILE ]; then
            echo "$PIDFILE exists, process is already running or crashed"
        else
            echo "Starting Redis server..."
            $EXEC $CONF
        fi
        if [ "$?"="0" ]; then
            echo "Redis is running..."
        fi
        ;;
    stop)
        if [ ! -f $PIDFILE ]; then
            echo "$PIDFILE does not exist, process is not running"
        else
            PID=$(cat $PIDFILE)
            echo "Stopping ..."
            $REDIS_CLI -p $REDISPORT SHUTDOWN
            while [ -x ${PIDFILE} ]; do
                echo "Waiting for Redis to shutdown ..."
                sleep 1
            done
            echo "Redis stopped"
        fi
        ;;
    restart | force-reload)
        ${0} stop
        ${0} start
        ;;
    *)
        echo "Usage: /etc/init.d/redis {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac
