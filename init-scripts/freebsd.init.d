#!/bin/sh
#
# PROVIDE: mylar
# REQUIRE: NETWORKING SERVERS DAEMON ldconfig resolv

. /etc/rc.subr

name="mylar"
rcvar=${name}_enable

load_rc_config ${name}

: ${mylar_enable:="YES"}
: ${mylar_user:="media"}
program_dir=/usr/local/${name}
pidfile=$program_dir/data/$name.pid

start_cmd="start"
status_cmd="status"
start_precmd="prestart"
stop_cmd="stop"
stop_postcmd="poststop"
status_cmd="status"
extra_commands="status"

prestart() {
        if [ -f $pidfile ]; then
                if [ `pgrep -F $pidfile` ]; then
                        pid=`pgrep -F $pidfile`
                        echo "$name is already running as $pid"
                        exit 1
                else
                        rm $pidfile
                        echo "removing stale pidfile"
                fi
        fi
}

start() {
        su -m ${mylar_user} -c "setenv PATH $program_dir/bin:$PATH;
                setenv LD_LIBRARY_PATH
$program_dir/lib:$LD_LIBRARY_PATH;
                usr/local/bin/python $program_dir/Mylar.py --config $program_dir/data/config.ini --datadir $program_dir/data/ --pidfile $pidfile -d --nolaunch"
}

stop() {
        if [ ! -f $program_dir/data/config.ini ];then
                fetch -o /dev/null http://127.0.0.1:8181/shutdown/
        else
                username=`grep http_username $program_dir/data/config.ini | awk '{ print $3}'`
                username="${username%\"}"
                username="${username#\"}"
                password=`grep http_password $program_dir/data/config.ini | awk '{ print $3}'`
                password="${password%\"}"
                password="${password#\"}"
                port=`grep http_port $program_dir/data/config.ini | tr -dc '[0-9]'`
                base=`grep -m 1 http_root $program_dir/data/config.ini | awk '{ print $3}'`
                if [ -z $password ];then
                        fetch -o /dev/null http://127.0.0.1: $port/$base/shutdown/
                else
                        fetch -o /dev/null http:// $username:$password@127.0.0.1:$port$base/shutdown/
                fi
        fi
}
 
poststop() {
        count=0
        while [ -f $pidfile ] && [ $count -lt 10 ]; do
                sleep 1
                let count=count+1
        done
        if [ -f $pidfile ]; then
                if [ `pgrep -F $pidfile` ]; then
                        pid=`pgrep -F $pidfile`
                        kill $pid
                else
                        rm $pidfile
                        echo "removing stale pidfile"
                fi
        fi
}
status() {
        if [ -f $pidfile ]; then
                if [ `pgrep -F $pidfile` ]; then
                        pid=`pgrep -F $pidfile`
                        echo "$name is running as $pid"
                else
                        echo "$name is not running"
                fi
        else
                echo "$name is not running"
        fi
}
        
load_rc_config ${name}
run_rc_command "$1"
