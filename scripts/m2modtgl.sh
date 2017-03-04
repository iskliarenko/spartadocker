#!/bin/bash

usage() {
    exCode=$1
    echo "Usage: m2modon|m2modoff [-h][-v][-i] [pattern1][pattern2][pattern3]..." >&2
    [ $exCode -eq 128 ] && {
	echo -e "\t-v\tInvert the sense of matching, to select non-matching modules"
	echo -e "\t-i\tIgnore case distinctions in the pattern"
	echo -e "\t-h\tPrint this message"
	echo -e "\t-c\tClear generated static view files"
	echo -e "\t-f\tBypass dependencies check"
        [ "$USER" = "apoltoratskyi" ] && {
	    echo -e "\t-n\tReserved specially for Andrey Poltoratskyi.\n\t\tAndrey, use it to disable your personal special features :("
	}
	echo -e "[pattern]\tThe valid characters set is [_0-9a-zA-Z]"
    }
    [ -n "$2" ] && echo -e "$2" >&2
    exit $exCode
}

checkTools() {
    local errMsg="required tool not found: "
    local tool=$(which $1 || (echo "$errMsg $1" && exit 2))
    errMsg="required tool is not executable: "
    [ -x $tool ] || (echo "$errMsg $tool" && exit 3)
    echo -n $tool
}

checkPwd() {
    local errMsg="Please execute this script in Magento's DocumentRoot"
    $GREP -q 'MAGE_MODE' .htaccess 2>/dev/null || (echo $errMsg && exit 4)
}

modToggle() {
    local action=
    local opts=
    [ $_cFlag -eq 1 ] && opts="$opts -c" ]
    [ $_fFlag -eq 1 ] && opts="$opts -f" ]
    
    [ "$_mode" = "on" ] && action="enable" || action="disable"
    cat - | $XARGS $PHP bin/magento module:${action} $opts
}

getList() {
    local list="$($PHP bin/magento module:status | $GREP -v Magento_)"
    local ptrnMatchOpts=
    local errMsg="WARNING:\n"
	    errMsg="$errMsg\tNo modules match your selection.\n"
	    errMsg="$errMsg\tPlease specify some modules to disable or enable.\n"
	    errMsg="$errMsg\tRun this program without arguments to enable/disable all the 3rd-party modules.\n"
	    errMsg="$errMsg\tUse 'magento modules:status' to list all the installed modules."
    [ $_vFlag -eq 1 ] && ptrnMatchOpts="$ptrnMatchOpts -v"
    [ $_iFlag -eq 1 ] && ptrnMatchOpts="$ptrnMatchOpts -i"
    [ "$_mode" = "on" ] && {
	list=$(echo -n "$list" | $SED -e '1,/ disabled /d')
    } || {
	list=$(echo -n "$list" | $SED -e '/ disabled /,$d')
    }
    list=$(echo -n "$list" | $GREP -v ' modules:' | $GREP -v '^$' | $GREP $ptrnMatchOpts "${_pattern%?}")
    [ -z "$list" ] && usage 4 "$errMsg"
    echo -n "$list"
}

checkPattern() {
    local word=$1
    errMsg="\tIllegal characters in pattern\n\tThe valid characters set is [_0-9a-zA-Z]"
    echo "$word"|$GREP -q '\W' && usage 2 "$errMsg"
}
    

SED=$(checkTools "sed")
GREP=$(checkTools "egrep")
XARGS=$(checkTools "xargs")
PHP=$(checkTools "php")

_mode=
_pattern=
_vFlag=0
_iFlag=0
_cFlag=0
_fFlag=0
_sFlag=0

progName=$(basename $0)

case $progName in
    m2modon) _mode="on";;
    m2modoff) _mode="off";;
    *) usage 1 "$errMsg";;
esac

checkPwd

while [ "$1" != '' ]
do
    case $1 in
	-h)		shift
			usage 128
			;;
	-i)		shift
			_iFlag=1
			;;
	-c)		shift
			_cFlag=1
			;;
	-n)		shift
			_sFlag=1
			;;
	-f)		shift
			_fFlag=1
			;;
	-v)		shift
			_vFlag=1
			;;
	[_0-9a-zA-Z]*)	 arg="$1"
			shift
			checkPattern "$arg"
			_pattern="${_pattern}${arg}|"
			;;
	*)		usage 3
			;;
    esac
done

[ $_sFlag = 0 ] && {
    [ "$USER" = "apoltoratskyi" ] && {
	r=$(seq 10|shuf|head -n1)
	[ $r -eq 5 ] && {
	    sl 
	} || {
	    cat <<EOF | $GREP -v -- '-- |FORTUNE PROVIDES' | cowsay -W80 -n
Andrey,
`fortune -e -n 256 -s riddles fortunes humorists humorix-misc`

And thanks for all the coffee!
EOF
	    echo
	    echo
	    echo
	}
    }
}
getList | modToggle
#getList 

exit 0
