#!/bin/sh

GITCLUSTERPATH="$1"

if [ "x" = "x$GITCLUSTERPATH" ]; then
    GITCLUSTERPATH=${HOME}/gitcluster/working
fi

PERMISSIONSFILE=$GITCLUSTERPATH/PERMISSIONS

MYHOST=$( hostname -s )
MYDOMAIN=$( hostname -f | sed "s;^$MYHOST\.;;" )

ROLESDIR=$GITCLUSTERPATH/_roles/$MYHOST

backup_myconfig(){
    CONFIGPATH=$1
    CONFIGS="$2"
    if [ ! -d $GITCLUSTERPATH/$CONFIGPATH ]; then
        mkdir $GITCLUSTERPATH/$CONFIGPATH
        for i in $CONFIGS; do
            if [ -d $GITCLUSTERPATH/$i ]; then
                find $GITCLUSTERPATH/$i -mindepth 1 \
                | sed "s;^$GITCLUSTERPATH/$i;;" \
                | sort \
                | while read path; do
                    if [ -d $path ] && [ ! -d $GITCLUSTERPATH/${CONFIGPATH}$path ]; then
                        #echo mkdir -p $GITCLUSTERPATH/${CONFIGPATH}$path
                             mkdir -p $GITCLUSTERPATH/${CONFIGPATH}$path
                    elif [ -f $path ]; then
                        if [ ! -e $GITCLUSTERPATH/${CONFIGPATH}$path ] || ! diff $path $GITCLUSTERPATH/${CONFIGPATH}$path ; then
                            #echo install -C $path $GITCLUSTERPATH/${CONFIGPATH}$path
                                 install -C $path $GITCLUSTERPATH/${CONFIGPATH}$path
                        fi
                    fi
                done
            fi
        done
    fi
}

apply_myconfig(){
    i=$1
    if [ -d $GITCLUSTERPATH/$i ]; then
        find $GITCLUSTERPATH/$i -mindepth 1 \
        | sort \
        | while read configpath; do
            INSTALLPATH=$( echo $configpath | sed "s;^$GITCLUSTERPATH/$i;;" )
            if [ -d $configpath ] && [ ! -d $INSTALLPATH ]; then
                #echo mkdir -p $INSTALLPATH
                     mkdir -p $INSTALLPATH
            elif [ -f $configpath ]; then
                if [ ! -e $INSTALLPATH ] || ! diff $configpath $INSTALLPATH ; then
                    #echo install -C $configpath $INSTALLPATH
                         install -C $configpath $INSTALLPATH
                fi
            fi
        done
    fi
}

# crontabbed create for user
id -u urep >/dev/null 2>&1 && su -l urep -c crontabbed

# save pf tables in case needed for backup
which pf-table >/dev/null 2>&1 && pf-table save all >/dev/null 2>&1

# backup all
backup_myconfig .bkp.$MYHOST "_base-host _base-domain _base-all"

# backup host only if hostfolder don't exist
backup_myconfig $MYHOST "_base-host"

# backup domain only if domainfolder don't exist
backup_myconfig $MYDOMAIN "_base-domain"

if [ -d $ROLESDIR ]; then
    MYROLES=$( ls $ROLESDIR )
fi

# apply
for template in _base-all $MYROLES $MYDOMAIN $MYHOST ; do
    apply_myconfig $template
done

if [ -e $PERMISSIONSFILE ]; then
    cat $PERMISSIONSFILE \
    | while read path user group octal ; do
        case "$path" in "#"*|"") continue; esac
        if [ -e $path ]; then
            chown ${user}:${group} $path
            chmod $octal $path
        fi
    done
fi

# load crontabbed in case changed
which crontabbed >/dev/null 2>&1 && crontabbed

# load pf tables in case changed
which pf-table >/dev/null 2>&1 && pf-table load all >/dev/null 2>&1

# crontabbed install for urep
id -u urep >/dev/null 2>&1 && su -l urep -c crontabbed

# create logs for crontabbed
for i in \
        /var/log/zfs-sync-xz-pull-all.log \
        /var/log/zsnaprune-all.log \
        ; do
    touch $i
    chown urep:urep $i
    chmod 644 $i
done

# crete logs for root
for i in \
        /var/log/mt-daapd.log \
        ; do
    touch $i
    chown root:wheel $i
    chmod 644 $i
done
