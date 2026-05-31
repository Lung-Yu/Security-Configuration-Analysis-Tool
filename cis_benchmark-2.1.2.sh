#!/bin/bash

function OS_VERSION() {
    cat /etc/os-release | grep '^NAME=' | grep "CentOS" 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        # echo "CentOS"
        return 1
    fi
    cat /etc/os-release | grep '^NAME=' | grep "Ubuntu" 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        # echo "Ubuntu"
        return 0
    fi
    cat /etc/os-release | grep '^NAME=' | grep "SUSE" 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        # echo "SUSE"
        return -1
    fi
    return -1000
}

###############################
# CIS Benchmark Version 1.0.0 -
###############################
CIS_LEVEL=1
INCLUDE_UNSCORED=0
WIDTH=79
if [ $CIS_LEVEL -gt 1 ];then
  RESULT_FIELD=10
else
  RESULT_FIELD=6
fi
MSG_FIELD=$(($WIDTH - $RESULT_FIELD))
# RED=$(tput setaf 1)
# GREEN=$(tput setaf 2)
# YELLOW=$(tput setaf 3)
RED=""
GREEN=""
YELLOW=""

NC=$(tput sgr0)
PASSED_CHECKS=0
FAILED_CHECKS=0

function header() {
    local HEADING=$1
    local TEXT=$((${#HEADING}+2))
    local LBAR=5
    local RBAR=$(($WIDTH - $TEXT - $LBAR))
    echo ""
    for (( x=0; x < $LBAR; x++));do
        printf %s '#'
    done
    echo -n " $HEADING "
    for (( x=0; x < $RBAR; x++));do
        printf %s '#'
    done
    echo ""
}

function msg() {
    # printf "%-${MSG_FIELD}s" " - ${1}"
    printf "%-${MSG_FIELD}s" " ${1}"
}

function success_result() {
    PASSED_CHECKS=$((PASSED_CHECKS+1))
    local RESULT="$GREEN${1:-PASSED}$NC"
    printf ",%-${RESULT_FIELD}s\n" $RESULT
}

function failed_result() {
    FAILED_CHECKS=$((FAILED_CHECKS+1))
    local RESULT="$RED${1:-FAILED}$NC"
    printf ",%-${RESULT_FIELD}s\n" $RESULT
}

function warning_result() {
    local RESULT="$YELLOW${1:-NOT CHECKED}$NC"
    printf ",%-${RESULT_FIELD}s\n" $RESULT
}

function check_retval_eq_0() {
  RETVAL=$1
  if [ $RETVAL -eq 0 ]; then
    success_result
  else
    failed_result
  fi
}

function check_retval_ne_0() {
  RETVAL=$1
  if [ $RETVAL -ne 0 ]; then
    success_result
  else
    failed_result
  fi
}


#####################
# 2.1 Inetd services
#####################
# ENABLED_SERVICES=$(systemctl list-unit-files | awk '($2 == "enabled") {print $0}')
# header "2.1.1 - 2.1.7 Ensure inetd services diabled"
# for service in chargen-dgram chargen-stream daytime-dgram daytime-stream discard-dgram discard-stream echo-dgram echo-stream time-dgram time-stream tftp xinetd;do
#     msg "$service"
#     echo $ENABLED_SERVICES | grep $service 2>&1 > /dev/null
#     check_retval_ne_0 $?
# done

# ####################################################
# 2.2.3 - 2.2.14 Ensure Unneeded Servers not enabled
####################################################
# header "2.2.3 - 2.2.21 Ensure Following services are not enabled"
# for service in avahi-daemoncups dhcpd slapd nfs rpcbind named vsftpd httpd dovecot smb squid snmpd ypserv rsh.socket rlogin.socket rexec.socket telnet.socket tftp.socket rsyncd ntalk;do
#     check_output="$(systemctl is-enabled $service 2>&1)"
#     check_output="$(dpkg -s  $service 2>&1)"
#     msg "$service, check_output"
#     if [ "$check_output" == "disabled" -o "$check_output" == "indirect" ];then
#     success_result
#     else
#     if [[ $check_output =~ Failed.*to.*get.*unit.*file.*state.*for.* ]];then
#         success_result
#     else
#         failed_result
#     fi
#     fi
# done
OS_VERSION
os_result=$?


## Output some file for security.
if [[ $os_result -eq 0 ]];then  # Ubuntu
    auditctl -l > "$(hostname)_auditctl.txt"
elif [[ $os_result -eq 1 ]];then    #CentOS
    auditctl -l > "$(hostname)_auditctl.txt"
elif [[ $os_result -eq -1 ]];then    #SUSE
    auditctl -l > "$(hostname)_auditctl.txt"
else    # for AIX 
    # many don't have auditctl
    # auditctl -l > "$(hostname)_auditctl.txt"
    msg "4.1.17 Ensure the audit configuration is immutable, $(grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1)"
    grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1 | grep '-e 2'  2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "3.1.1 use security setting for mindiff, $(lssec -f /etc/security/user -s default -a mindiff | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a mindiff | awk '{print $3}') -ge 4 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.2 use security setting for minage, $(lssec -f /etc/security/user -s default -a minage | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minage | awk '{print $3}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.2 use security setting for maxage, $(lssec -f /etc/security/user -s default -a maxage | awk '{print $3}')"
    if [[ ($(lssec -f /etc/security/user -s default -a maxage | awk '{print $3}') -ge 1 ) && ( $(lssec -f /etc/security/user -s default -a maxage | awk '{print $3}') -le 13 ) ]];then
    #  &&
    #  [$(lssec -f /etc/security/user -s default -a maxage | awk '{print $3}') -le 13]

        success_result
    else
        failed_result
    fi

    msg "3.1.2 use security setting for minage, $(lssec -f /etc/security/user -s default -a minlen | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minlen | awk '{print $3}') -ge 8 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.2 use security setting for minage, $(lssec -f /etc/security/user -s default -a minalpha | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minalpha | awk '{print $3}') -ge 2 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.2 use security setting for minother, $(lssec -f /etc/security/user -s default -a minother | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minother | awk '{print $3}') -ge 2 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for maxrepeats, $(lssec -f /etc/security/user -s default -a maxrepeats | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a maxrepeats | awk '{print $3}') -le 2 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for histexpire, $(lssec -f /etc/security/user -s default -a histexpire | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a histexpire | awk '{print $3}') -ge 13 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for histsize, $(lssec -f /etc/security/user -s default -a histsize | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a histsize | awk '{print $3}') -ge 20 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for maxexpired, $(lssec -f /etc/security/user -s default -a maxexpired | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a maxexpired | awk '{print $3}') -ge 2 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for minloweralpha, $(lssec -f /etc/security/user -s default -a minloweralpha | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minloweralpha | awk '{print $3}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for minupperalpha, $(lssec -f /etc/security/user -s default -a minupperalpha | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minupperalpha | awk '{print $3}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for minupperalpha, $(lssec -f /etc/security/user -s default -a minupperalpha | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minupperalpha | awk '{print $3}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for mindigit, $(lssec -f /etc/security/user -s default -a mindigit | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a mindigit | awk '{print $3}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for mindigit, $(lssec -f /etc/security/user -s default -a minspecialchar | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a minspecialchar | awk '{print $3}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for logindisable, $(lssec -f /etc/security/login.cfg -s default -a logindisable | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/login.cfg -s default -a logindisable | awk '{print $3}') -le 10 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for logindisable, $(lssec -f /etc/security/login.cfg -s default -a loginreenable | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/login.cfg -s default -a loginreenable | awk '{print $3}') -ge 360 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for logindisable, $(lssec -f /etc/security/user -s default -a loginretries | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s default -a loginretries | awk '{print $3}') -le 3 ]];then
        success_result
    else
        failed_result
    fi

    msg "3.1.3 use security setting for logindisable, $(lssec -f /etc/security/user -s root -a rlogin | awk '{print $3}')"
    if [[ $(lssec -f /etc/security/user -s root -a rlogin | awk '{print $3}') -eq "False" ]];then
        success_result
    else
        failed_result
    fi
fi

# 2.2.9.Ensure FTP Server is not installed for Ubuntu

if [[ $os_result -eq 0 ]];then  # Ubuntu
    msg ">2.2.9.Ensure FTP Server is not installed, "
    sudo systemctl status vsftpd | grep 'Active:inactive' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "2.2.10.Ensure FTP Server is not installed, "
    check_output="$(systemctl is-enabled vsftpd 2>&1)"
    if [ "$check_output" == "disabled" -o "$check_output" == "indirect" ];then
        success_result
    else
        if [[ $check_output =~ Failed.*to.*get.*unit.*file.*state.*for.* ]];then
            success_result
        else
            failed_result
        fi
    fi
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "(SUSE)2.2.10.Ensure FTP Server is not installed, "
    rpm -q vsftpd 2>&1 > /dev/null
    check_retval_ne_0 $?
fi


if [[ $os_result -eq -1 ]];then # SUSE
    msg "(SUSE)2.3.2.Ensure rsh client is not installed, "
    rpm -q rsh 2>&1 > /dev/null
    check_retval_ne_0 $?
elif [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "(Ubuntu)2.3.2.Ensure rsh client is not installed, "
    sudo systemctl status rsh-client | grep 'Active:inactive' 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "(CentOS)2.3.2.Ensure rsh client is not installed, "
    rpm -q rsh 2>&1 > /dev/null
    check_retval_ne_0 $?
    
fi


if [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "2.3.4.Ensure telnet client is not installed, "
    sudo systemctl status telnet | grep 'Active:inactive' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "2.3.2.(2) Ensure telnet client is not installed, "
    rpm -q telnet 2>&1 > /dev/null
    check_retval_ne_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "2.3.4.(2) Ensure telnet client is not installed, "
    rpm -q telnet 2>&1 > /dev/null
    check_retval_ne_0 $?
fi

if [[ $os_result -eq 1 ]];then    #CentOS

    msg "4.1.8.(1) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(2) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale -w /etc/issue -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(3) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/issue.net -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(4) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/hosts -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(5) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/sysconfig/network -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 0 ]];then    # Ubuntu 

    msg "4.1.5.(1) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/hosts -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(2) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/issue.net -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(3) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-a always,exit -F arch=b64 -S sethostname,setdomainname -F key=system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE

    msg "4.1.5.(1) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(2) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale -w /etc/issue -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(3) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/issue.net -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(4) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/hosts -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?
    
    msg "4.1.5.(5) Ensure events that modify the system's network environment are collected, "
    sudo auditctl -l | grep system-locale | grep '^-w /etc/sysconfig/network -p wa -k system-locale' 2>&1 > /dev/null
    check_retval_eq_0 $?

fi


if [[ $os_result -eq 1 ]];then    #CentOS

    msg "4.1.7.(1) Ensure events that modify the system's Mandatory Access Controls are collected, "
    sudo auditctl -l | grep MAC-policy | grep '^-w /etc/selinux/ -p wa -k MAC-policy' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.7.(2) Ensure events that modify the system's Mandatory Access Controls are collected, "
    sudo auditctl -l | grep MAC-policy | grep '^-w /usr/share/selinux/ -p wa -k MAC-policy' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 0 ]];then    # Ubuntu 

    msg "4.1.6.(1) Ensure events that modify the system's Mandatory Access Controls are collected, "
    sudo auditctl -l | grep MAC-policy | grep '^-w /etc/selinux/ -p wa -k MAC-policy' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.6.(2) Ensure events that modify the system's Mandatory Access Controls are collected, "
    sudo auditctl -l | grep MAC-policy | grep '^-w /usr/share/selinux -p wa -k MAC-policy' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE
    
    msg "4.1.6.(1) Ensure events that modify the system's Mandatory Access Controls are collected, "
    sudo auditctl -l | grep MAC-policy | grep '^-w /etc/selinux/ -p wa -k MAC-policy' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.6.(2) Ensure events that modify the system's Mandatory Access Controls are collected, "
    sudo auditctl -l | grep MAC-policy | grep '^-w /usr/share/selinux -p wa -k MAC-policy' 2>&1 > /dev/null
    check_retval_eq_0 $?

fi

if [[ $os_result -eq 1 ]];then    #CentOS
    msg "4.1.4.(1) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/faillog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.4.(2) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/lastlog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "4.1.7.(1) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/faillog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.7.(2) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/lastlog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.7.(3) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/tallylog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "4.1.7.(1) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/faillog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.7.(2) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/lastlog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.7.(3) Ensure login and logout events are collected, "
    sudo auditctl -l | grep logins | grep '^-w /var/log/tallylog -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?
fi


if [[ $os_result -eq 1 ]];then    #CentOS
    msg "4.1.5.(1) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/run/utmp -p wa -k session' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(2) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/wtmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.5.(3) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/btmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "4.1.8.(1) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/utmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(2) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/wtmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(3) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/btmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "4.1.8.(1) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/utmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(2) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/wtmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.8.(3) Ensure session initiation information is collected, "
    sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/btmp -p wa -k logins' 2>&1 > /dev/null
    check_retval_eq_0 $?
fi


if [[ $os_result -eq 1 ]];then    #CentOS   ## un-check
    msg "4.1.10.(1) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?                    

    msg "4.1.10.(2) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.10.(3) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.10.(4) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 0 ]];then    # Ubuntu 

    msg "4.1.10.(1) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b64 -S open,truncate,ftruncate,creat,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -F key=access' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.10.(2) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b32 -S open,creat,truncate,ftruncate,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -F key=access' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE
    
    msg "4.1.10.(1) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.10.(2) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.10.(3) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.10.(4) Ensure unsuccessful unauthorized file access attempts are collected, "
    sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access' 2>&1 > /dev/null
    check_retval_eq_0 $?

fi

if [[ $os_result -eq 1 ]];then    #CentOS   ## un-check

    msg "4.1.14.(1) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.14.(2) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.14.(3) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.14.(4) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "4.1.13.(1) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b32 -S rename.unlink,unlinkat,renameat -F auid>=1000 -F auid!=-1 -F key=delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.13.(2) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b64 -S rename.unlink,unlinkat,renameat -F auid>=1000 -F auid!=-1 -F key=delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE

    msg "4.1.13.(1) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.13.(2) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.13.(3) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.13.(4) Ensure file deletion events by users are collected, "
    sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k delete' 2>&1 > /dev/null
    check_retval_eq_0 $?

fi


OS_VERSION
if [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "4.1.14.(1) Ensure changes to system administration scope (sudoers) is collected, "
    sudo auditctl -l | grep scope | grep '^-w /etc/sudoers -p wa -k scope' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.14.(2) Ensure changes to system administration scope (sudoers) is collected, "
    sudo auditctl -l | grep scope | grep '^-w /etc/sudoers.d/ -p wa -k scope' 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "4.1.13.(1) Ensure changes to system administration scope (sudoers) is collected, "
    sudo auditctl -l | grep scope | grep '^-w /etc/sudoers -p wa -k scope' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.13.(2) Ensure changes to system administration scope (sudoers) is collected, "
    sudo auditctl -l | grep scope | grep '^-w /etc/sudoers.d/ -p wa -k scope' 2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "4.1.14.(1) Ensure changes to system administration scope (sudoers) is collected, "
    sudo auditctl -l | grep scope | grep '^-w /etc/sudoers -p wa -k scope' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.14.(2) Ensure changes to system administration scope (sudoers) is collected, "
    sudo auditctl -l | grep scope | grep '^-w /etc/sudoers.d/ -p wa -k scope' 2>&1 > /dev/null
    check_retval_eq_0 $?
fi

OS_VERSION
if [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "4.1.15.(1) Ensure system administrator command executions (sudo) are collected, "
    sudo auditctl -l | grep actions | grep '^-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -F auid>=1000 -F auid!=-1 -F key=actions' 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.1.15.(2) Ensure system administrator command executions (sudo) are collected, "
    sudo auditctl -l | grep actions | grep '^-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -F auid>=1000 -F auid!=-1 -F key=actions' 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq 1 ]];then    #CentOS
  

elif [[ $os_result -eq -1 ]];then    #SUSE
 
fi





if [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "4.1.17 Ensure the audit configuration is immutable, $(grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1)"
    grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1 | grep '-e 2'  2>&1 > /dev/null
    check_retval_eq_0 $?

elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "4.1.17 Ensure the audit configuration is immutable, $(grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1)"
    grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1 | grep '-e 2'  2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "4.1.17 Ensure the audit configuration is immutable, $(grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1)"
    grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1 | grep '-e 2'  2>&1 > /dev/null
    check_retval_eq_0 $?
fi


if [[ $os_result -eq 0 ]];then    # Ubuntu 
    grep -E "^[^#](\s*\S+\s*)\s*action\(" /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep "target=" 2>&1 > /dev/null
    msg "4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host, $(grep -E '^[^#](\s*\S+\s*)\s*action\(' /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep 'target=')"
    check_retval_eq_0 $?
elif [[ $os_result -eq 1 ]];then    #CentOS
    grep "^*.*[^I][^I]*@" /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep '*.* @@loghost.example.com' 2>&1 > /dev/null
    msg "4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host, $(grep "^*.*[^I][^I]*@" /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep '*.* @@loghost.example.com')"
    check_retval_eq_0 $?
elif [[ $os_result -eq -1 ]];then    #SUSE
    grep "^*.*[^I][^I]*@" /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep '*.* @@loghost.example.com' 2>&1 > /dev/null
    msg "4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host, $(grep "^*.*[^I][^I]*@" /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep '*.* @@loghost.example.com')"
    check_retval_eq_0 $?
fi

if [[ $os_result -eq 0 ]];then    # Ubuntu 

    msg "5.2.1(X) Ensure /etc/ssh/sshd_config permissions are 0600 root:root,"
    if [[ $(stat /etc/ssh/sshd_config) =~ Access:.*(0600/-rw-------).*Uid:.*(.*0/.*root).*Gid:.*(.*0/.*root) ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "5.2.1(X) Ensure /etc/ssh/sshd_config permissions are 0600 root:root,"
    if [[ $(stat /etc/ssh/sshd_config) =~ Access:.*(0600/-rw-------).*Uid:.*(.*0/.*root).*Gid:.*(.*0/.*root) ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "5.2.1(X) Ensure /etc/ssh/sshd_config permissions are 0600 root:root,"
    if [[ $(stat /etc/ssh/sshd_config) =~ Access:.*(0600/-rw-------).*Uid:.*(.*0/.*root).*Gid:.*(.*0/.*root) ]];then
        success_result
    else
        failed_result
    fi
else
    # ssh_config permissions lockdown
    msg "4.2.18(X) Ensure /etc/ssh/sshd_config permissions are -rw-r--r-- root system /etc/ssh/ssh_config,"
    ls -l /etc/ssh/ssh_config | awk '{print $1 " " $3 " " $4 " " $9}' | grep "^-rw-r--r-- root system /etc/ssh/ssh_config" 2>&1 > /dev/null
    check_retval_eq_0 $?

    msg "4.2.19(X) Ensure /etc/ssh/sshd_config permissions are -rw------- root system /etc/ssh/sshd_config,"
    ls -l /etc/ssh/sshd_config | awk '{print $1 " " $3 " " $4 " " $9}' | grep "^-rw------- root system /etc/ssh/sshd_config" 2>&1 > /dev/null
    check_retval_eq_0 $?
fi

if [[ $os_result -eq 0 ]];then    # Ubuntu 
    msg "5.2.4 Ensure SSH LogLevel is set to INFO or VERBOSE, $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO')"
    grep "^LogLevel" /etc/ssh/sshd_config | grep "VERBOSE\|INFO" 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "5.2.5 Ensure SSH LogLevel is set to INFO or VERBOSE, $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO')"
    grep "^LogLevel" /etc/ssh/sshd_config | grep "VERBOSE\|INFO" 2>&1 > /dev/null
    check_retval_eq_0 $?
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "5.2.5 Ensure SSH LogLevel is set to INFO or VERBOSE, $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO')"
    grep "^LogLevel" /etc/ssh/sshd_config | grep "VERBOSE\|INFO" 2>&1 > /dev/null
    check_retval_eq_0 $?
else
    msg "4.2.12 Ensure SSH LogLevel is set to INFO or VERBOSE, $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO')"
    grep "^LogLevel[[:blank:]]" /etc/ssh/sshd_config | grep "VERBOSE\|INFO" 2>&1 > /dev/null
    check_retval_eq_0 $?
fi

if [[ $os_result -eq 0 ]];then    # Ubunt
    msg "5.2.6 Ensure SSH MaxAuthTries is set to 4 or less, $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}') -le 4 ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq 1 ]];then    #CentOS
    msg "5.2.7 Ensure SSH MaxAuthTries is set to 4 or less, $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}') -le 4 ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq -1 ]];then    #SUSE
    msg "5.2.6 Ensure SSH MaxAuthTries is set to 4 or less, $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}') -le 4 ]];then
        success_result
    else
        failed_result
    fi
else
    msg "4.2.13 Ensure SSH MaxAuthTries is set to 4 or less, $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^MaxAuthTries[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}') -le 4 ]];then
        success_result
    else
        failed_result
    fi
fi


if [[ $os_result -eq 0 ]];then    # Ubunt

    msg "5.2.7 Ensure SSH IgnoreRhosts is enabled, $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}') -eq "yes" ]];then
        success_result
    else
        failed_result
    fi

elif [[ $os_result -eq 1 ]];then    #CentOS
    
    msg "5.2.8 Ensure SSH IgnoreRhosts is enabled, $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}') -eq "yes" ]];then
        success_result
    else
        failed_result
    fi

elif [[ $os_result -eq -1 ]];then    #SUSE

    msg "5.2.7 Ensure SSH IgnoreRhosts is enabled, $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}') -eq "yes" ]];then
        success_result
    else
        failed_result
    fi
else

    msg "4.2.2 Ensure SSH IgnoreRhosts is enabled, $(grep "^PermitRootLogin[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^PermitRootLogin[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}') -eq "no" ]];then
        success_result
    else
        failed_result
    fi

    grep "^Protocol[[:blank:]]" /etc/ssh/sshd_config | grep "Protocol 2"  2>&1 > /dev/null
    msg "4.2.3 server protocol 2,"
    check_retval_eq_0 $?

    grep "^Protocol[[:blank:]]" /etc/ssh/ssh_config | grep "Protocol 2"  2>&1 > /dev/null
    msg "4.2.4 client protocol 2,"
    check_retval_eq_0 $?


    msg "4.2.6 Ensure SSH IgnoreRhosts is enabled, $(grep "^IgnoreRhosts[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^IgnoreRhosts[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}') -eq "yes" ]];then
        success_result
    else
        failed_result
    fi
fi


if [[ $os_result -eq 0 ]];then    # Ubunt

    msg "5.2.10 Ensure SSH PermitEmptyPasswords is disabled, $(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | awk '{print $2}') -eq "no" ]];then
        success_result
    else
        failed_result
    fi

elif [[ $os_result -eq 1 ]];then    #CentOS
    
    msg "5.2.11 Ensure SSH PermitEmptyPasswords is disabled, $(sudo sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitemptypasswords | awk '{print $2}')"
    if [[ $(sudo sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitemptypasswords | awk '{print $2}') -eq "no" ]];then
        success_result
    else
        failed_result
    fi

elif [[ $os_result -eq -1 ]];then    #SUSE

    msg "5.2.10 Ensure SSH PermitEmptyPasswords is disabled, $(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | awk '{print $2}') -eq "no" ]];then
        success_result
    else
        failed_result
    fi
else
    msg "4.2.7 Ensure SSH PermitEmptyPasswords is disabled, $(grep "^PermitEmptyPasswords[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^PermitEmptyPasswords[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}') -eq "no" ]];then
        success_result
    else
        failed_result
    fi

    msg "4.2.7 disallow host based authentication, $(grep '^HostbasedAuthentication[[:blank:]]' /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep '^HostbasedAuthentication[[:blank:]]' /etc/ssh/sshd_config | awk '{print $2}') -eq "no" ]];then
        success_result
    else
        failed_result
    fi

    
fi


if [[ $os_result -eq 0 ]];then    # Ubunt

    msg "5.2.15(1) Ensure SSH Idle Timeout Interval is configured:ClientAliveInterval <= 300,$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}') -le 300 ]];then
        success_result
    else
        failed_result
    fi
    msg "5.2.15(2) Ensure SSH Idle Timeout Interval is configured:ClientAliveCountMax <= 3, $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}')"
    if [[ $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}') -le 3 ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq 1 ]];then    #CentOS

    msg "5.2.13(1) Ensure SSH Idle Timeout Interval is configured:ClientAliveInterval <= 300,$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}') -le 300 ]];then
        success_result
    else
        failed_result
    fi
    msg "5.2.13(2) Ensure SSH Idle Timeout Interval is configured:ClientAliveCountMax <= 3, $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}')"
    if [[ $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}') -le 3 ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq -1 ]];then    #SUSE
    
    msg "5.2.15(1) Ensure SSH Idle Timeout Interval is configured:ClientAliveInterval <= 300,$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}') -le 300 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.2.15(2) Ensure SSH Idle Timeout Interval is configured:ClientAliveCountMax <= 3, $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}')"
    if [[ $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}') -le 3 ]];then
        success_result
    else
        failed_result
    fi
else
    msg "4.2.14(1) Ensure SSH Idle Timeout Interval is configured:ClientAliveInterval <= 300,$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')"
    if [[ $(grep "^ClientAliveCountMax[[:blank:]]" /etc/ssh/sshd_config | awk '{print $2}') -le 300 ]];then
        success_result
    else
        failed_result
    fi
    # set Idle Timeout Interval for User Login
    msg "4.2.14(2) Ensure SSH Idle Timeout Interval is configured:ClientAliveCountMax <= 3, $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}')"
    if [[ $(grep "^ClientAliveInterval[[:blank:]]" /etc/ssh/sshd_config  | awk '{print $2}') -le 0 ]];then
        success_result
    else
        failed_result
    fi

    msg "4.2.15 Ensure SSH restrict Cipher list, $(grep "^Ciphers [[:blank:]]" /etc/ssh/sshd_config)"
    grep "^Ciphers [[:blank:]]" /etc/ssh/sshd_config| grep '^Ciphers aes128-ctr,aes192-ctr,aes256-ctr' 2>&1 > /dev/null
    check_retval_eq_0 $?

fi

if [[ $os_result -eq 0 ]];then    # Ubunt

    msg "5.3.1 Ensure password creation requirements are configured minlen >= 14, $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}') -ge 14 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured dcredit=-1,$(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured ucredit=-1,$(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured lcredit=-1,$(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured ocredit=-1,$(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

elif [[ $os_result -eq 1 ]];then    #CentOS

    msg "5.4.1 Ensure password creation requirements are configured minlen >= 14, $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}') -ge 14 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1 Ensure password creation requirements are configured dcredit=-1,$(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1 Ensure password creation requirements are configured ucredit=-1,$(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1 Ensure password creation requirements are configured lcredit=-1,$(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1 Ensure password creation requirements are configured ocredit=-1,$(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi


elif [[ $os_result -eq -1 ]];then    #SUSE

    msg "5.3.1 Ensure password creation requirements are configured minlen >= 14, $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}') -ge 14 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured dcredit=-1,$(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured ucredit=-1,$(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured lcredit=-1,$(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.3.1 Ensure password creation requirements are configured ocredit=-1,$(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}')"
    if [[ $(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
        success_result
    else
        failed_result
    fi
fi


if [[ $os_result -eq 0 ]];then    # Ubunt

    grep -E "pam_(tally2|deny)\.so" /etc/pam.d/common-account | grep "\sunlock_time=([1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[5-9][0-9][0-9])"  2>&1 > /dev/null
    msg "5.3.2 Ensure lockout for failed password attempts is configured,$(grep -E 'pam_(tally2|deny)\.so' /etc/pam.d/common-account | grep '\sunlock_time=([1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[5-9][0-9][0-9])')"
    check_retval_eq_0 $?

    grep -E '^password\s+required\s+pam_pwhistory.so\s+remember=([4-9]|[1-2][0-9])' /etc/pam.d/common-password | awk '{print $4}' 2>&1 > /dev/null
    msg "5.3.3 Ensure password reuse is limited, $(grep -E '^password\s+required\s+pam_pwhistory.so\s+remember=([1-9][0-9][0-9]|[1-9][0-9]|[4-9])' /etc/pam.d/common-password | awk '{print $4}')"
    check_retval_eq_0 $?
elif [[ $os_result -eq 1 ]];then    #CentOS

    grep -E '^\s*auth\s+\S+\s+pam_(faillock|unix)\.so' /etc/pam.d/system-auth /etc/pam.d/password-auth  2>&1 > /dev/null
    msg "5.4.2 Ensure lockout for failed password attempts is configured,"
    check_retval_eq_0 $?

    grep -P '^\s*password\s+(requisite|required)\s+pam_pwhistory\.so\s+([^#]+\s+)*remember=([5-9]|[1-9][0-9]+)\b' /etc/pam.d/system-auth /etc/pam.d/password-auth  2>&1 > /dev/null
    msg "5.4.3 Ensure lockout for failed password attempts is configured"
    check_retval_eq_0 $?

elif [[ $os_result -eq -1 ]];then    #SUSE

    grep -E "pam_(tally2|deny)\.so" /etc/pam.d/common-account | grep "\sunlock_time=([1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[5-9][0-9][0-9])"  2>&1 > /dev/null
    msg "5.3.2 Ensure lockout for failed password attempts is configured,$(grep -E 'pam_(tally2|deny)\.so' /etc/pam.d/common-account | grep '\sunlock_time=([1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[5-9][0-9][0-9])')"
    check_retval_eq_0 $?

    grep -E '^password\s+required\s+pam_pwhistory.so\s+remember=([4-9]|[1-2][0-9])' /etc/pam.d/common-password | awk '{print $4}' 2>&1 > /dev/null
    msg "5.3.3 Ensure password reuse is limited, $(grep -E '^password\s+required\s+pam_pwhistory.so\s+remember=([1-9][0-9][0-9]|[1-9][0-9]|[4-9])' /etc/pam.d/common-password | awk '{print $4}')"
    check_retval_eq_0 $?

fi


if [[ $os_result -eq 0 ]];then    # Ubunt

    msg "5.4.1.1 Ensure password expiration is 365 days or less, $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
    if [[ $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -le 365 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1.1 Ensure password expiration is 1 days or more, $(grep PASS_MIN_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
    if [[ $(grep PASS_MIN_DAYS  /etc/login.defs | grep -v \# | awk '{print $2}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq 1 ]];then    #CentOS

    msg "5.4.1.1 Ensure password expiration is 365 days or less, $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
    if [[ $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -le 365 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1.1 Ensure password expiration is 1 days or more, $(grep PASS_MIN_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
    if [[ $(grep PASS_MIN_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi
elif [[ $os_result -eq -1 ]];then    #SUSE

    msg "5.4.1.1 Ensure password expiration is 365 days or less, $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
    if [[ $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -le 365 ]];then
        success_result
    else
        failed_result
    fi

    msg "5.4.1.1 Ensure password expiration is 1 days or more, $(grep PASS_MIN_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
    if [[ $(grep PASS_MIN_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -ge 1 ]];then
        success_result
    else
        failed_result
    fi
fi



