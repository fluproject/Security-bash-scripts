#!/bin/bash
#
# sysinfotask: A simple shell script to to get information about your 
#              Linux server/desktop and perform simple tuning tasks.
# Author: @verovan
# Date: Mar 2017
#

dst_path="/opt"

git_tools="
CISOfy/lynis
a2o/snoopy
Tripwire/tripwire-open-source
bearstech/iptraf-ng
nmap/nmap
"
declare -A targz_tools
targz_tools=([IfTop]=http://www.ex-parrot.com/~pdw/iftop/download/iftop-0.17.tar.gz
  [TCPDump]=http://www.tcpdump.org/release/tcpdump-4.9.0.tar.gz)

err() {
  echo "${0##*/}: $@" >&2
}

print_usage() {
  echo ""
  echo "Usage: ${0##*/} [option] [param]"
  echo "Options:"
  echo " -i  | --info: print operating system info."
  echo " -u  | --user: print information about your user."
  echo " -w  | --who: print who is currently online in your systema."
  echo " -s  | --services: list open ports."
  echo " -f  | --firewall: check firewall default policies."
  echo " -y  | --sysctl: kernel tuning via system control variables."
  echo " -m  | --motd: change the message of the day (/etc/motd)."
  echo " -is | --issue: change the message of system identification (/etc/issue)."
  echo " -t  | --tty: empty the content of /etc/securetty."
  echo " -o  | --timeout [time]: set auto logout after a period of inactivity for all the users in your system."
  echo "       --install: install audit and performance tools."
  echo ""
  echo "Usage example: systemsec -o 360"
}

check_root() {
  local user=$(/usr/bin/id -u)
    if [ ${user} -ne 0 ]; then
      err "You need to be root (uid 0) to run this functionality."
      exit 1
    fi
}

parse_arguments() {
#while [[ $# > 0 ]]; do
  case "$1" in
    -i|--info)
      get_sys_info
    ;;
    -u|--user)
      get_user_info
    ;;
    -w|--who)
      who_is_online
    ;;
    -s|--services)
      scan
    ;;
    -f|--firewall)
      check_root
      check_firewall
    ;;
    -y|--sysctl)
      check_root
      change_flags
    ;;
    -f|--flags)
      check_root
      change_flags
    ;;
    -m|--motd)
      check_root
      change_motd
    ;;
    -is|--issue)
      check_root
      change_issue
    ;;
    -t|tty)
      check_root
      change_tty
    ;;
    -o|timeout)
      check_root
      set_timeout $2
    ;;
    --install)
      check_root
      install_tools
    ;;
    -h|--help)
      print_usage
      exit 0
    ;;
    -*)
      err "Error: Unknown option: $1."
      exit 1
    ;;
  esac
#done
}

type_cmd() {
  type $1 >/dev/null 2>&1 || { echo >&2 "$1 is required to run this functionality."; exit 1 ;}
}

get_sys_info() {
  date
    echo -e "==========OPERATING SYSTEM INFORMATION=========="
    echo -e "Hostname: $(hostname)"
    echo -e "Kernel version: $(uname -rs)"
    echo -e "Architecture: $(uname -m)"
    echo -e "CPU model: $(cat /proc/cpuinfo | awk -F: '/model name/ {print $2}' | head -1)"
    echo -e "Total memory: $(cat /proc/meminfo | awk '$1=="MemTotal:" {print int($2/1024) " KB"}')"
    (egrep '^flags.*(vmx|svm)' /proc/cpuinfo &>/dev/null) && 
    echo "The system supports virtualization." || 
    echo "The system doesn't support virtualization or it has been disbled in the BIOS."
}

get_user_info() {
	 grep $USER /etc/passwd | awk -F: '{print "Username: "$1 "\nFull name: "$5 "\nUID:\t"$3 "\nGID:\t"$4 "\nShell:\t"$7}'
}

who_is_online() {
  echo -e "=====Currently logged in users====="
  who -H
  echo -e "=====Recentlytly logged in users====="
  last | head -5
}

scan () {
  #[[ $# -ne 1 ]] && echo "Indique el nombre del host a escanear." && return 1
  for i in {1..9000} ; do #can chage this value
    #host="$1"
    port=$i
    (echo  > /dev/tcp/127.0.0.1/$port) >& /dev/null && echo "Port $port seems to be open."
  done
}

check_firewall() {
  echo -e "==========FIREWALL DEFAULT POLICIES=========="
  local chains=("INPUT OUTPUT FORWARD")
  for c in $chains; do
    if iptables -L $c | grep "(policy DROP)" 1>/dev/null; then
      echo -e "\033[01;31m [ OK ] \033[00m" "Chain $c has the correct default policy."
      else
        if iptables -L $c | grep "(policy ACCEPT)" 1>/dev/null; then
 	  echo -e "\033[01;31m [ X ] \033[00m" "Default policy for $c is ACCEPT. Change it to DROP."
 	else
 	  echo -e "\033[01;31m [ X ] \033[00m" "Default policy for $c is REJECT. Change it to DROP."
 	fi
      fi
   done
}

change_flags() {
  #0
  sed -i '{
  s/.*net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects=0/
  s/.*tcp_syncookies.*/net.ipv4.tcp_syncookies=1/
  s/.*net.ipv4.conf.all.log_martians.*/net.ipv4.conf.all.log_martians=1/
  }' /etc/sysctl.conf
  echo -e "net.ipv4.icmp_echo_ignore_all=1" >> /etc/sysctl.d/net.conf
  echo -e "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.d/net.conf
  echo -e "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.d/net.conf
  sysctl -p /etc/sysctl.conf 1>/dev/null
  sysctl -p /etc/sysctl.d/net.conf 1>/dev/null
  echo -e "Done!"
}

change_motd() {
  local motd="\nEste sistema es para el uso exclusivo de usuarios autorizados, por lo que las personas que lo\n"
  motd+="utilicen estarán sujetos al monitoreo de todas sus actividades en el mismo. Cualquier persona\n"
  motd+="que utilice este sistema permite expresamente tal monitoreo y debe estar consciente de que si este\n"
  motd+="revelara una posible actividad ilicita, el personal de sistemas proporcionara la evidencia\n"
  motd+="del monitoreo al personal de seguridad, con el fin de emprender las acciones civiles y/o legales\n"
  motd+="que correspondan.\n"
  local motd_file="/etc/motd"
  if [[ ! -a $motd_file ]]; then
    touch $motd_file
    chmod 644 $motd_file
  fi
  echo -e $motd > $motd_file
  echo -e "The new message of the day that all the users will see when log in is: \n\t$motd"
}

change_issue() {
  local issue="$(uname -s)"
  local issue_file="/etc/issue"
  if [[ ! -a $issue_file ]]; then
    touch $issue_file
    chmod 644 $issue_file
  fi
  echo -e $issue > $issue_file
  echo -e "The message all the users will see in the tty is: \n$issue"
}

change_tty() {
  : > /etc/securetty
  echo -e "Done!"
}

set_timeout() {
  if [ $1 -eq $1 2>/dev/null ] && [ -n "$1" ]; then
    #touch /etc/profile.d/tmout-settings.sh
    #echo "TMOUT=$1" >> /etc/profile.d/tmout-settings.sh
    echo -e "TMOUT=$1" >> /etc/bash.bashrc
    echo -e "readonly TMOUT" >> /etc/bash.bashrc
  else
    echo -e "Timeout must be a positive integer and non string."
    exit 1
  fi
}

install_tools() {
  type_cmd git
  type_cmd tar
  type_cmd gzip
  for at in $audit_tools; do
    tool_dir=$(echo $at | awk -F"/" '{print $2}')
    git clone git://github.com/$at.git $dst_path/$tool_dir
    sleep 5
  done
  for t in "${!targz_tools[@]}"; do
    tar_file=$(echo ${targz_tools[$t]} | awk -F"/" '{print $NF}')
    ls $dst_path/$tar_file*  && { rm -f $dst_path/$tar_file* ; echo -e "Removing old downloads...";}
    echo -e "Downloading $t..."
    wget --directory-prefix=$dst_path ${targz_tools[$t]}
    echo -e "Decompressing $t..."
    tar xzf $dst_path/$tar_file --directory=$dst_path
    echo -e ""
    sleep 1
  done
}

main() {
  parse_arguments "$@"
  exit 0
}

main "$@"

