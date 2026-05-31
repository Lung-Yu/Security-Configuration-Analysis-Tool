#!/bin/bash

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

msg "2.2.9.Ensure FTP Server is not installed, "
sudo systemctl status vsftpd | grep 'Active:inactive' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "2.3.2.Ensure rsh client is not installed, "
sudo systemctl status rsh-client | grep 'Active:inactive' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "2.3.4.Ensure telnet client is not installed, "
sudo systemctl status telnet | grep 'Active:inactive' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.5.(1) Ensure events that modify the system's network environment are collected, "
sudo auditctl -l | grep system-locale | grep '^-w /etc/hosts -p wa -k system-locale' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.5.(2) Ensure events that modify the system's network environment are collected, "
sudo auditctl -l | grep system-locale | grep '^-w /etc/issue.net -p wa -k system-locale' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.5.(3) Ensure events that modify the system's network environment are collected, "
sudo auditctl -l | grep system-locale | grep '^-a always,exit -F arch=b64 -S sethostname,setdomainname -F key=system-locale' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.6.(1) Ensure events that modify the system's Mandatory Access Controls are collected, "
sudo auditctl -l | grep MAC-policy | grep '^-w /etc/selinux/ -p wa -k MAC-policy' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.6.(2) Ensure events that modify the system's Mandatory Access Controls are collected, "
sudo auditctl -l | grep MAC-policy | grep '^-w /usr/share/selinux -p wa -k MAC-policy' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.7.(1) Ensure login and logout events are collected, "
sudo auditctl -l | grep logins | grep '^-w /var/log/faillog -p wa -k logins' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.7.(2) Ensure login and logout events are collected, "
sudo auditctl -l | grep logins | grep '^-w /var/log/lastlog -p wa -k logins' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.7.(3) Ensure login and logout events are collected, "
sudo auditctl -l | grep logins | grep '^-w /var/log/tallylog -p wa -k logins' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.8.(1) Ensure session initiation information is collected, "
sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/btmp -p wa -k logins' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.8.(2) Ensure session initiation information is collected, "
sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/wtmp -p wa -k logins' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.8.(3) Ensure session initiation information is collected, "
sudo auditctl -l | grep -E '(session|logins)' | grep '^-w /var/log/btmp -p wa -k logins' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.10.(1) Ensure unsuccessful unauthorized file access attempts are collected, "
sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b64 -S open,truncate,ftruncate,creat,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -F key=access' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.10.(2) Ensure unsuccessful unauthorized file access attempts are collected, "
 sudo auditctl -l | grep access |  grep '^-a always,exit -F arch=b32 -S open,creat,truncate,ftruncate,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -F key=access' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.13.(1) Ensure file deletion events by users are collected, "
sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b32 -S rename.unlink,unlinkat,renameat -F auid>=1000 -F auid!=-1 -F key=delete' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.13.(2) Ensure file deletion events by users are collected, "
sudo auditctl -l | grep delete | grep '^-a always,exit -F arch=b64 -S rename.unlink,unlinkat,renameat -F auid>=1000 -F auid!=-1 -F key=delete' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.14.(1) Ensure changes to system administration scope (sudoers) is collected, "
sudo auditctl -l | grep scope | grep '^-w /etc/sudoers -p wa -k scope' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.14.(2) Ensure changes to system administration scope (sudoers) is collected, "
sudo auditctl -l | grep scope | grep '^-w /etc/sudoers.d/ -p wa -k scope' 2>&1 > /dev/null
check_retval_eq_0 $?

# msg "4.1.15 Ensure system administrator command executions (sudo) are collected, $(auditctl -l | grep actions | grep '^-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -F auid>=1000 -F auid!=-1 -F key=actions')"
msg "4.1.15.(1) Ensure system administrator command executions (sudo) are collected, "
sudo auditctl -l | grep actions | grep '^-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -F auid>=1000 -F auid!=-1 -F key=actions' 2>&1 > /dev/null
check_retval_eq_0 $?

msg "4.1.15.(2) Ensure system administrator command executions (sudo) are collected, "
sudo auditctl -l | grep actions | grep '^-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -F auid>=1000 -F auid!=-1 -F key=actions' 2>&1 > /dev/null
check_retval_eq_0 $?

# if [[ $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}') -eq "yes" ]];then
msg "4.1.17 Ensure the audit configuration is immutable, $(grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1)"
grep "^\s*[^#]" /etc/audit/rules.d/*.rules | tail -1 | grep '-e 2'  2>&1 > /dev/null
check_retval_eq_0 $?

grep -E "^[^#](\s*\S+\s*)\s*action\(" /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep "target=" 2>&1 > /dev/null
msg "4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host, $(grep -E '^[^#](\s*\S+\s*)\s*action\(' /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep 'target=')"
check_retval_eq_0 $?

##############################
# 5.2 SSH Server Configuration
##############################
#################################################################
# 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured
#################################################################
# header "5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured"
# msg "Ensure /etc/ssh/sshd_config permissions are 0600 root:root, $(stat /etc/ssh/sshd_config)"
msg "5.2.1(X) Ensure /etc/ssh/sshd_config permissions are 0600 root:root,"
if [[ $(stat /etc/ssh/sshd_config) =~ Access:.*(0600/-rw-------).*Uid:.*(.*0/.*root).*Gid:.*(.*0/.*root) ]];then
    success_result
else
    failed_result
fi

##########################################
# 5.2.4 Ensure SSH LogLevel is appropriate
##########################################
# header "5.2.4 Ensure SSH LogLevel is set to INFO or VERBOSE"
# msg 'grep "^LogLevel" /etc/ssh/sshd_config | grep "VERBOSE\|INFO"'
msg "5.2.4 Ensure SSH LogLevel is set to INFO or VERBOSE, $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO')"
grep "^LogLevel" /etc/ssh/sshd_config | grep "VERBOSE\|INFO" 2>&1 > /dev/null
check_retval_eq_0 $?

# msg "!!!!!"
# msg "5.2.4 Ensure SSH LogLevel is set to INFO or VERBOSE, $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO' | awk '{print $2}')"
# if [[ $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO' | awk '{print $2}') -eq "INFO" ] ||
# [ $(grep '^LogLevel' /etc/ssh/sshd_config | grep 'VERBOSE\|INFO' | awk '{print $2}') -eq "VERBOSE" ]];then
#     success_result
# else
#     failed_result
# fi

###################################################
# 5.2.6 Ensure SSH MaxAuthTries is set to 4 or less
###################################################
# header "5.2.6 Ensure SSH MaxAuthTries is set to 4 or less"
# msg 'grep "^MaxAuthTries" /etc/ssh/sshd_config | grep "4"'
msg "5.2.6 Ensure SSH MaxAuthTries is set to 4 or less, $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')"
if [[ $(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}') -le 4 ]];then
    success_result
else
    failed_result
fi

##########################################
# 5.2.7 Ensure SSH IgnoreRhosts is enabled
##########################################
# header "5.2.7 Ensure SSH IgnoreRhosts is enabled"
# msg 'grep "^IgnoreRhosts" /etc/ssh/sshd_config | grep "yes"'
# grep "^IgnoreRhosts" /etc/ssh/sshd_config | grep "yes" 2>&1 > /dev/null
# check_retval_eq_0 $?

msg "5.2.7 Ensure SSH IgnoreRhosts is enabled, $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}')"
if [[ $(grep "^IgnoreRhosts" /etc/ssh/sshd_config | awk '{print $2}') -eq "yes" ]];then
    success_result
else
    failed_result
fi




###################################################
# 5.2.10 Ensure SSH PermitEmptyPasswords is disabled
###################################################
# header "5.2.10 Ensure SSH PermitEmptyPasswords is disabled"
# msg 'grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | grep "no"'
# grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | grep "no" 2>&1 > /dev/null

msg "5.2.10 Ensure SSH PermitEmptyPasswords is disabled, $(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | awk '{print $2}')"
if [[ $(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | awk '{print $2}') -eq "no" ]];then
    success_result
else
    failed_result
fi


#######################################################
# 5.2.15 Ensure SSH Idle Timeout Interval is configured
#######################################################
# header "5.2.15 Ensure SSH Idle Timeout Interval is configured"
# msg 'grep "^ClientAliveInterval" /etc/ssh/sshd_config'
msg "5.2.15 Ensure SSH Idle Timeout Interval is configured:ClientAliveInterval <= 300,$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')"
if [[ $(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}') -le 300 ]];then
    success_result
else
    failed_result
fi
msg "5.2.15 Ensure SSH Idle Timeout Interval is configured:ClientAliveCountMax <= 3, $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}')"
# msg 'grep "^ClientAliveCountMax" /etc/ssh/sshd_config '
if [[ $(grep "^ClientAliveCountMax" /etc/ssh/sshd_config  | awk '{print $2}') -le 3 ]];then
    success_result
else
    failed_result
fi

###################
# 5.3 Configure PAM
###################
############################################################
# 5.3.1 Ensure password creation requirements are configured
############################################################
# header "5.3.1 Ensure password creation requirements are configured"
# printf "\n"
# msg 'grep pam_pwquality.so /etc/pam.d/password-auth'
# grep pam_pwquality.so /etc/pam.d/password-auth | grep -E "try_first_pass.*retry=3" 2>&1 > /dev/null
# check_retval_eq_0 $?

# msg 'grep pam_pwquality.so /etc/pam.d/system-auth'
# grep pam_pwquality.so /etc/pam.d/system-auth | grep -E "try_first_pass.*retry=3" 2>&1 > /dev/null
# check_retval_eq_0 $?

msg "5.3.1 Ensure password creation requirements are configured minlen >= 14, $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}')"
# grep -E ^minlen /etc/security/pwquality.conf | grep "minlen=14" 2>&1 > /dev/null
# check_retval_eq_0 $?

if [[ $(grep '^\s*minlen\s*' /etc/security/pwquality.conf | awk '{print $3}') -ge 14 ]];then
    success_result
else
    failed_result
fi


msg "5.3.1 Ensure password creation requirements are configured dcredit=-1,$(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}')"
# grep -E ^dcredit /etc/security/pwquality.conf | grep "dcredit=-1" 2>&1 > /dev/null
# check_retval_eq_0 $?
if [[ $(grep -E ^dcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
    success_result
else
    failed_result
fi

msg "5.3.1 Ensure password creation requirements are configured lcredit=-1,$(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}')"
# msg 'grep ^lcredit /etc/security/pwquality.conf'
# grep -E ^lcredit /etc/security/pwquality.conf | grep "lcredit=-1" 2>&1 > /dev/null
# check_retval_eq_0 $?
if [[ $(grep -E ^lcredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
    success_result
else
    failed_result
fi


# msg 'grep ^ocredit /etc/security/pwquality.conf'
msg "5.3.1 Ensure password creation requirements are configured ocredit=-1,$(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}')"
# grep -E ^ocredit /etc/security/pwquality.conf | grep "ocredit=-1" 2>&1 > /dev/null
# check_retval_eq_0 $?
if [[ $(grep -E ^ocredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
    success_result
else
    failed_result
fi


# msg 'grep ^ucredit /etc/security/pwquality.conf'
msg "5.3.1 Ensure password creation requirements are configured ucredit=-1,$(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}')"
# grep -E ^ucredit /etc/security/pwquality.conf | grep "ucredit=-1" 2>&1 > /dev/null
if [[ $(grep -E ^ucredit /etc/security/pwquality.conf | awk '{print $3}') -eq -1 ]];then
    success_result
else
    failed_result
fi

#################################################################
# 5.3.2 Ensure lockout for failed password attempts is configured
#################################################################
# header "5.3.2 Ensure lockout for failed password attempts is configured"
# msg '5.3.2 Ensure lockout for failed password attempts is configured,'
# grep pam_unix.so /etc/pam.d/password-auth | grep "success=1.*default=bad" 2>&1 > /dev/null
# check_retval_eq_0 $?
# # msg 'grep pam_unix.so /etc/pam.d/system-auth'
# # grep pam_unix.so /etc/pam.d/system-auth | grep "success=1.*default=bad" 2>&1 > /dev/null
# # check_retval_eq_0 $?


grep -E "pam_(tally2|deny)\.so" /etc/pam.d/common-account | grep "\sunlock_time=([1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[5-9][0-9][0-9])"  2>&1 > /dev/null
msg "5.3.2 Ensure lockout for failed password attempts is configured,$(grep -E 'pam_(tally2|deny)\.so' /etc/pam.d/common-account | grep '\sunlock_time=([1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[5-9][0-9][0-9])')"
check_retval_eq_0 $?
########################################
# 5.3.3 Ensure password reuse is limited
########################################
# header "5.3.3 Ensure password reuse is limited"
# msg "egrep '^password\s+sufficient\s+pam_unix.so' /etc/pam.d/password-auth"

grep -E '^password\s+required\s+pam_pwhistory.so\s+remember=([4-9]|[1-2][0-9])' /etc/pam.d/common-password | awk '{print $4}' 2>&1 > /dev/null
msg "5.3.3 Ensure password reuse is limited, $(grep -E '^password\s+required\s+pam_pwhistory.so\s+remember=([1-9][0-9][0-9]|[1-9][0-9]|[4-9])' /etc/pam.d/common-password | awk '{print $4}')"
check_retval_eq_0 $?




###################################
# 5.4 User Accounts and Environment
###################################
############################################
# 5.4.1 Set Shadow Password Suite Parameters 
############################################

# header "5.4.1.1 Ensure password expiration is 365 days or less"
# msg 'grep PASS_MAX_DAYS /etc/login.defs'
msg "5.4.1.1 Ensure password expiration is 365 days or less, $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
if [[ $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -le 365 ]];then
    success_result
else
    failed_result
fi
#######################################################
# 5.4.1.2 Ensure password expiration is 1 days or more
#######################################################
# header "5.4.1.1 Ensure password expiration is 1 days or more"
msg "5.4.1.1 Ensure password expiration is 1 days or more, $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}')"
# msg 'grep PASS_MAX_DAYS /etc/login.defs'
if [[ $(grep PASS_MAX_DAYS /etc/login.defs | grep -v \# | awk '{print $2}') -ge 1 ]];then
    success_result
else
    failed_result
fi
     


# ##############
# # FINAL REPORT
# ##############
# for (( x=0; x < $(($WIDTH+1)); x++));do
#     printf %s '='
# done
# printf "\n"
# printf "%$(($WIDTH - 4))s" "TOTAL CHECKS: "
# printf "%4s\n" "$(($PASSED_CHECKS + $FAILED_CHECKS))"
# printf "%$(($WIDTH - 4))s" "FAILED CHECKS: "
# printf "%4s\n" "$FAILED_CHECKS"
# printf "%$(($WIDTH - 4))s" "PASSED CHECKS: "
# printf "%4s\n" "$PASSED_CHECKS"
