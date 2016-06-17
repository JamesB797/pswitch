##
# Get a value from pswitch's config
#
# $1 The value's key
#
pget () {
    <$psconf awk -F = "/$1/"' { print $2 }'
}

##
# Set a value in pswitch's config
#
# $1 The key to set
# $2 The value to set it to
#
pset () {
    <$psconf grep "$1" > /dev/null
    result=$?
    [ $result -eq 1 ] && echo "$1=$2" >> $psconf
    [ $result -eq 0 ] && <$psconf sed "s/^\\($1=\\).*$/\\1$2/" > $psconf.tmp && mv $psconf.tmp $psconf
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
            pswitch
            vagrant halt
            pset current "$2"
            pswitch
            vagrant up
            ;;

        vm)
            pswitch
            vagrant ssh
            ;;

        dir)
            cd $projectdir'pswitch'
            ;;

        *)
            cd $projectdir"$(pget current)"
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
[ ! -f $psconf ] && touch $psconf && pset projectdir ~/Documents/

##
# The directory where projects are kept
#
projectdir="$(pget projectdir)"
