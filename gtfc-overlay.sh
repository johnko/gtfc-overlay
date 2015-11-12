#!/bin/sh

GITCLUSTERPATH="$1"

if [ "x" = "x$GITCLUSTERPATH" ]; then
    GITCLUSTERPATH=${HOME}/gitcluster/working
fi

PERMISSIONSFILE=$GITCLUSTERPATH/PERMISSIONS
ROLESDIR=$GITCLUSTERPATH/_roles/$MYHOST

MYHOST=$( hostname -s )
MYDOMAIN=$( hostname -f | sed "s;^$MYHOST\.;;" )

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

# backup host
backup_myconfig $MYHOST "base-host base-domain base-all"

# backup domain
backup_myconfig $MYDOMAIN "base-domain"

if [ -d $ROLESDIR ]; then
    MYROLES=$( ls $ROLESDIR )
fi

# apply
for template in base-all $MYROLES $MYDOMAIN $MYHOST ; do
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
