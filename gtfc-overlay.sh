#!/bin/sh

GITCLUSTERPATH="$1"

if [ "x" = "x$GITCLUSTERPATH" ]; then
    GITCLUSTERPATH=${HOME}/gitcluster/working
fi

PERMISSIONSFILE=$GITCLUSTERPATH/PERMISSIONS

MYHOST=$( hostname -s )
MYDOMAIN=$( hostname -f | sed "s;^$MYHOST\.;;" )

ROLESDIR=$GITCLUSTERPATH/roles/$MYHOST

TMPOLDDIR=/tmp/`whoami`/.old
TMPNEWDIR=/tmp/`whoami`/.new

backup_myconfig(){
    local CONFIGPATH=$1
    local CONFIGS="$2"
    if [ ! -d $CONFIGPATH ]; then
        mkdir $CONFIGPATH
        for i in $CONFIGS; do
            if [ -d $GITCLUSTERPATH/$i ]; then
                find $GITCLUSTERPATH/$i -mindepth 1 \
                | sed "s;^$GITCLUSTERPATH/$i;;" \
                | sort \
                | while read path; do
                    if [ -d $path ] && [ ! -e ${CONFIGPATH}$path ]; then
                        #echo mkdir -p ${CONFIGPATH}$path
                             mkdir -p ${CONFIGPATH}$path
                    elif [ -f $path ]; then
                        if [ ! -e ${CONFIGPATH}$path ] || ! diff $path ${CONFIGPATH}$path >/dev/null 2>&1 ; then
                            #echo install -C $path ${CONFIGPATH}$path
                                 install -C $path ${CONFIGPATH}$path
                        fi
                    fi
                done
            fi
        done
    fi
}

apply_myconfig(){
    local i=$1
    local MYINSTALLPREFIX=$2
    if [ -d $GITCLUSTERPATH/$i ]; then
        find $GITCLUSTERPATH/$i -mindepth 1 \
        | sort \
        | while read configpath; do
            INSTALLPATH=$( echo $configpath | sed "s;^$GITCLUSTERPATH/$i;$MYINSTALLPREFIX;" )
            if [ -d $configpath ] && [ ! -e $INSTALLPATH ]; then
                #echo mkdir -p $INSTALLPATH
                     mkdir -p $INSTALLPATH
            elif [ -f $configpath ]; then
                if [ ! -e $INSTALLPATH ] || ! diff $configpath $INSTALLPATH >/dev/null 2>&1 ; then
                    #echo install -C $configpath $INSTALLPATH
                         install -C $configpath $INSTALLPATH
                fi
            fi
        done
    fi
}

users_crontabbed(){
    if which crontabbed >/dev/null 2>&1 ; then
        # root crontab
        crontabbed
        # urep crontab
        id -u urep     >/dev/null 2>&1 && su -l urep     -c crontabbed
        # _sshtunl crontab
        chsh -s /bin/csh          _sshtunl >/dev/null 2>&1
        id -u _sshtunl >/dev/null 2>&1 && su -l _sshtunl -c crontabbed
        chsh -s /usr/sbin/nologin _sshtunl >/dev/null 2>&1
    fi
}

ch_own_mod(){
    chown ${2}:${3} $1
    chmod $4 $1
}

apply_config_loop(){
    local DESTDIR=$1
    for template in _base-all $MYROLES $MYDOMAIN $MYHOST ; do
        apply_myconfig $template $DESTDIR
    done
}

compare_old_new(){
    PATTERN=$1
    local FOUND=$( diff -r $TMPOLDDIR $TMPNEWDIR | grep $PATTERN | head -1 )
    if [ "x" = "x$FOUND" ]; then
        return 1
    fi
    # return 0 means found pattern
    return 0
}

# save pf tables in case needed for backup
which pf-table >/dev/null 2>&1 && pf-table save all >/dev/null 2>&1

# backup all
backup_myconfig $GITCLUSTERPATH/.bkp.$MYHOST "_base-host _base-domain _base-all"

# backup host only if hostfolder don't exist
backup_myconfig $GITCLUSTERPATH/$MYHOST "_base-host"

# backup domain only if domainfolder don't exist
backup_myconfig $GITCLUSTERPATH/$MYDOMAIN "_base-domain"

if [ -d $ROLESDIR ]; then
    MYROLES=$( ls $ROLESDIR )
fi

# backup of before for diff comparison
[ -e $TMPOLDDIR ] && rm -r $TMPOLDDIR
[ -e $TMPNEWDIR ] && rm -r $TMPNEWDIR
backup_myconfig $TMPOLDDIR "_base-all $MYROLES $MYDOMAIN $MYHOST"

# apply to tmp new for diff comparison
apply_config_loop $TMPNEWDIR

# apply to real root if different
if ! diff -r $TMPOLDDIR $TMPNEWDIR ; then
    apply_config_loop
fi

if [ -e $PERMISSIONSFILE ]; then
    cat $PERMISSIONSFILE \
    | while read path user group octal ; do
        case "$path" in "#"*|"") continue; esac
        if [ -e $path ]; then
            ch_own_mod $path $user $group $octal
        fi
    done
fi

# create logs
TOUCHFILES="
/var/log/zfs-sync-xz-pull-all.log urep urep  644
/var/log/zsnaprune-all.log        urep urep  644
/var/log/mt-daapd.log             root wheel 644
"
echo "$TOUCHFILES" \
| while read path user group octal ; do
    case "$path" in "#"*|"") continue; esac
    if [ ! -e $path ]; then
        touch $path
        if [ -e $path ]; then
            ch_own_mod $path $user $group $octal
        fi
    fi
done

# custom actions if new files are different
if which pf-table >/dev/null 2>&1; then
    compare_old_new '/etc/pf.*\.table' && pf-table load all >/dev/null 2>&1
fi

compare_old_new 'crontabbed' && users_crontabbed

## iocage fetch doesn't work if called during git push
## workaround is to start them in tmux
ls /usr/local/etc/deployjails.conf.d/* >/dev/null 2>&1 && tmux new-session -d _deploy_jails

## restarting or reloading services doesn't work if called during git push
## workaround is to start them in tmux
compare_old_new '/etc/ssh.*sshd_config' && tmux new-session -d /etc/rc.d/sshd reload
compare_old_new '/etc/rc.conf.d.*mdnsd' && tmux new-session -d /usr/local/etc/rc.d/mdnsd restart
compare_old_new '/etc/sysctl.conf' && tmux new-session -d /etc/rc.d/sysctl start
if compare_old_new '/etc/rc.conf.d.*mdnsresponderposix' || compare_old_new '/usr/local/etc.*mdnsresponder.conf' ; then
    tmux new-session -d /usr/local/etc/rc.d/mdnsresponderposix restart
fi

## exit with success
exit 0
