#!/bin/bash
# check_snmp_fortigate_tunnel.sh
# Version 1.0.4
# Author: spysnooper

##############################################################################
# FUNCTIONS
##############################################################################
usage() {
        echo "Usage: $0 -H <hostaddress> -C <snmp_community_string> -A <main_tunnel_ipv4_pub_address>" 1>&2
        exit 3;
}
endpoints() {
  # Loop endpoints
  for (( i=1; i<=${NLINES};i++ ))
  do
    # tunnel vars
    OID_FORTIGATE_TUNNEL_NOMBRE=".1.3.6.1.4.1.12356.101.12.2.2.1.2.${i}.1"
    OID_FORTIGATE_TUNNEL_ESTADO=".1.3.6.1.4.1.12356.101.12.2.2.1.20.${i}.1"
    OID_FORTIGATE_TUNNEL_ENDPOINTA=".1.3.6.1.4.1.12356.101.12.2.2.1.6.${i}.1"
    OID_FORTIGATE_TUNNEL_ENDPOINTB=".1.3.6.1.4.1.12356.101.12.2.2.1.4.${i}.1"

    NOMBRE=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_NOMBRE} | awk -F': ' '{print $2}')
    ESTADO=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_ESTADO} | awk -F': ' '{print $2}')
    ENDPOINTA=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_ENDPOINTA} | awk -F': ' '{print $2}')
    ENDPOINTB=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_ENDPOINTB} | awk -F': ' '{print $2}')

    if [ "${ENDPOINTB}" == "${tun1}" ];then
      OUTSTR="${OUTSTR}${ESTADO} - ${NOMBRE} - ${ENDPOINTA} <-> ${ENDPOINTB}\n"
    else
      OUTSTR="UNKOWN - ${tun1} distinct of ${ENDPOINTB}, possibly some caracters are missing in -A arg\n${OUTSTR}"
      echo -ne "${OUTSTR}"
      usage
      exit 3
    fi
  done
}

##############################################################################
# CONSTANTS
##############################################################################
NAGIOS_PLUGIN_DIR='/usr/lib64/nagios/plugins'
LABEL='Estado,Tunnel,EndpointA,EndpointB'
SNMP_VERSION='1'
WARN='3,1::'
CRIT='3,1::'
TIMEOUT='10'
OID_FORTIGATE_TUNNEL_LIST='.1.3.6.1.4.1.12356.101.12.2.2.1.4'

##############################################################################
# VARIABLES
##############################################################################
NLINES=0
OUTSTR=""


##############################################################################
# MAIN
##############################################################################
# Get Args
while getopts ":H:C:A:" OPTION; do
    case "${OPTION}" in
        H)
            HOST=${OPTARG}
            ;;
        C)
            SNMP_COMUNITY=${OPTARG}
            ;;
        A)
            tun1=${OPTARG}
            ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument"
            usage
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG"
            usage
            ;;
    esac
done

# Test that needed args are present
if [ -z "${HOST}" ] || [ -z "${SNMP_COMUNITY}" ] || [ -z "${tun1}" ]; then
    usage
fi

# Number of times that tun1 appears (= number of tunnels configured)
NLINES=$( snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_LIST} | grep ${tun1} | awk -F= '{print $1}' | cut -d. -f 15 | wc -l )

case "${NLINES}" in
  0)
    OUTSTR="CRITICAL - There are no tunnel stablished to ${tun1}\n${OUTSTR}"
    echo -ne "${OUTSTR}\n"
    exit 2
    ;;
  1)
    enpoints
    OUTSTR="WARNING - There are some tunnel that fails to stablish connection to ${tun1}\n${OUTSTR}"
    echo -ne "${OUTSTR}"
    exit 1
    ;;
  *)
    endpoints
    OUTSTR="OK - Unless there are ${NLINES} tunnels stablished to ${tun1}\n${OUTSTR}"
    echo -ne "${OUTSTR}"
    exit 0
    ;;
esac
