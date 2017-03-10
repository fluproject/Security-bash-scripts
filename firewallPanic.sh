#!/bin/bash
# 
# firewallPanic.sh - Firewall Blocking all communications.
#
# USAGE: ./firewallPanic.sh 192.168.0.10
# 
# 192.168.0.10 IP Sysadmin
#

ssh_src=
ssh_sport="0:65535"
ssh_dport="0:65535"

CAT_CMD="/bin/cat"
IPTABLES_CMD="/sbin/iptables"
GREP_CMD="/bin/grep"
CUT_CMD="/usr/bin/cut"
MODPROBE_CMD="/sbin/modprobe"
LOGGER_CMD="/usr/bin/logger"

# Make sure only root can run us.
if [ ! "${UID}" = 0 ]
then
	echo >&2
	echo >&2
	echo >&2 "Only user root can run firewallPanic."
	echo >&2
	exit 1
fi

if [ ! -z "${SSH_CLIENT}" ]
then
	set -- ${SSH_CLIENT}
	ssh_src="${1}"
	ssh_sport="${2}"
	ssh_dport="${3}"
elif [ ! -z "${1}" ]
then
	ssh_src="${1}"
fi
		
${LOGGER_CMD} info "Starting PANIC mode (SSH SOURCE_IP=${ssh_src} SOURCE_PORTS=${ssh_sport} DESTINATION_PORTS=${ssh_dport})"
echo >&2
echo >&2
echo >&2 "firewallPanic.sh: Blocking all communications:"
echo >&2

${MODPROBE_CMD} ip_tables
tables=`${CAT_CMD} /proc/net/ip_tables_names`
for t in ${tables}
do
	${IPTABLES_CMD} -t "${t}" -F
	${IPTABLES_CMD} -t "${t}" -X
	${IPTABLES_CMD} -t "${t}" -Z

	# Find all default chains in this table.
	chains=`${IPTABLES_CMD} -t "${t}" -nL | ${GREP_CMD} "^Chain " | ${CUT_CMD} -d ' ' -f 2`
	for c in ${chains}
	do
		${IPTABLES_CMD} -t "${t}" -P "${c}" ACCEPT
		if [ ! -z "${ssh_src}" ]
		then
			${IPTABLES_CMD} -t "${t}" -A "${c}" -p tcp -s "${ssh_src}" --sport "${ssh_sport}" --dport "${ssh_dport}" -m conntrack --ctstate ESTABLISHED -j ACCEPT
			${IPTABLES_CMD} -t "${t}" -A "${c}" -p tcp -d "${ssh_src}" --dport "${ssh_sport}" --sport "${ssh_dport}" -m conntrack --ctstate ESTABLISHED -j ACCEPT
		fi
		if [ "${t}" != "nat" ] ; then
			${IPTABLES_CMD} -t "${t}" -A "${c}" -j DROP
		fi
	done
done
