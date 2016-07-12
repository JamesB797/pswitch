##
# Get a value from pswitch's config
#
# $1 The value's key
#
__pswitch_get () {
    <$psconf awk -F = "/$1/"' { print $2 }'
}

##
# Set a value in pswitch's config
#
# $1 The key to set
# $2 The value to set it to
#
__pswitch_set () {
    <$psconf grep "$1" > /dev/null
    result=$?
    [ $result -eq 1 ] && echo "$1=$2" >> $psconf
    [ $result -eq 0 ] && <$psconf sed "s/^\\($1=\\).*$/\\1$2/" > $psconf.tmp && mv $psconf.tmp $psconf
}

##
# Remove a value from pswitch's config
#
# $1 The key to remove
#
__pswitch_rem () {
    <$psconf grep -v "^$1=" > $psconf.temp
    mv $psconf.temp $psconf
}

__pswitch_validdir () {
    ls -l $projectdir | grep ^d | awk '{print $9}' | grep "$1" > /dev/null 2>&1
    return $?
}

##
# The main pswitch function
#
# $1 The command name
# $2-onward Additional information
#
# No command:
# cd to the current project's directory
#
# switch (s):
# Perform cleanup and switch to a different project
#
pswitch () {
    case $1 in
        s|switch)
            if __pswitch_validdir "$2" ; then
                pswitch
                vagrant halt
                __pswitch_set current "$2"
                pswitch
                vagrant up
            else
                echo "$2" is not a valid project
            fi
            ;;

        e|extra)
            if [ ! -z $2 ] ; then
                case $2 in
                    -r|--remove)
                        if [ ! -z "$(__pswitch_get extra)" ] ; then
                            pswitch extra
                            vagrant halt
                            __pswitch_rem extra
                        fi
                        ;;

                    *)
                        if __pswitch_validdir "$2" ; then
                            pswitch extra --remove
                            __pswitch_set extra "$2"
                            pswitch extra
                            vagrant up
                        else
                            echo "$2" is not a valid project
                        fi
                        ;;
                esac
            else
                cd $projectdir"$(__pswitch_get extra)"
            fi
            ;;

        vm)
            pswitch
            vagrant ssh
            ;;

        dir)
            cd $projectdir'pswitch'
            ;;

        *)
            cd $projectdir"$(__pswitch_get current)"
            ;;
    esac
}

##
# A completion function for pswitch
#
_pswitch_complete () {
    case $3 in
        s)
            COMPREPLY=$(ls -l $projectdir | grep ^d | awk '{print $9}' | grep "$2" | head -1)
            ;;
        *)
            COMPREPLY=s
            ;;
    esac
}

##
# The configuration file directory
#
confdir=$HOME/.config

##
# The configuration file
#
psconf=$confdir/pswitch

# Ensure the configuration directory and file
# are present and set a default for projectdir
[ ! -d $confdir ] && mkdir $confdir
[ ! -f $psconf ] && touch $psconf && __pswitch_set projectdir ~/Documents/

##
# The directory where projects are kept
#
projectdir="$(__pswitch_get projectdir)"
