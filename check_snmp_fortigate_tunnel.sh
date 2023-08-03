#!/bin/bash
# check_snmp_fortigate_tunnel.sh
# Version 1.0.7
# Author: SpySnooper

##############################################################################
# FUNCTIONS
##############################################################################
usage() {
        echo "Usage: $0 -H <hostaddress> -C <snmp_community_string> -A <main_tunnel_ipv4_pub_address>" 1>&2
        exit 3;
}
endpoints() {
    TUNNEL_STATE=0
    # tunnel vars
    OID_FORTIGATE_TUNNEL_NAME=".1.3.6.1.4.1.12356.101.12.2.2.1.2.${i}.1"
    OID_FORTIGATE_TUNNEL_STATE=".1.3.6.1.4.1.12356.101.12.2.2.1.20.${i}.1"
    OID_FORTIGATE_TUNNEL_ENDPOINTA=".1.3.6.1.4.1.12356.101.12.2.2.1.6.${i}.1"
    OID_FORTIGATE_TUNNEL_ENDPOINTB=".1.3.6.1.4.1.12356.101.12.2.2.1.4.${i}.1"

    TUNNEL_NAME=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_NAME} | awk -F': ' '{print $2}'| cut -d\" -f2)
    TUNNEL_STATE=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_STATE} | awk -F': ' '{print $2}')
    ENDPOINTA=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_ENDPOINTA} | awk -F': ' '{print $2}')
    ENDPOINTB=$(snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_ENDPOINTB} | awk -F': ' '{print $2}')

    if [ "${ENDPOINTB}" == "${tun1}" ];then
      if [ "${OUTSTR}" == "" ];then
        OUTSTR="${TUNNEL_STATE} - ${TUNNEL_NAME} - ${ENDPOINTA} <-> ${ENDPOINTB}"
      else
        OUTSTR="${OUTSTR}, ${TUNNEL_STATE} - ${TUNNEL_NAME} - ${ENDPOINTA} <-> ${ENDPOINTB}"
      fi

      if [ "${OUTPERF}" == "" ];then
        OUTPERF="'${TUNNEL_NAME} (${ENDPOINTA} <-> ${ENDPOINTB})'=${TUNNEL_STATE};1;3"
      else
        OUTPERF="${OUTPERF} '${TUNNEL_NAME} (${ENDPOINTA} <-> ${ENDPOINTB})'=${TUNNEL_STATE};1;3"
      fi

      case ${TUNNEL_STATE} in
        2)
          FINALSTATE=$(( ${FINALSTATE}+1 )) # sum 1 when is UP
          ;;
        *)
          FINALSTATE=$(( ${FINALSTATE}+0 )) # sum 0 when STATE not equal 2
          ;;
      esac
      
    else
      OUTSTR="UNKOWN - ${tun1} distinct of ${ENDPOINTB}, possibly some caracters are missing in -A arg"
      echo -ne "${OUTSTR}"
      usage
      exit 3
    fi
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
OUTPERF=""
FINALSTATE=0

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

# ENsure needed args are present
if [ -z "${HOST}" ] || [ -z "${SNMP_COMUNITY}" ] || [ -z "${tun1}" ]; then
    usage
fi

# Number of times that tun1 appears (= number of tunnels configured)
NTUNNELS=$( snmpwalk -On -v ${SNMP_VERSION} -c ${SNMP_COMUNITY} ${HOST} ${OID_FORTIGATE_TUNNEL_LIST} | grep ${tun1} | awk -F= '{print $1}' | cut -d. -f 15 | wc -l )

for (( i=1; i<=${NTUNNELS};i++ ))
do
  endpoints
done

case "${FINALSTATE}" in
  0)
    OUTSTR="CRITICAL - There are no tunnel stablished to ${tun1}"
    echo -ne "${OUTSTR} | ${OUTPERF}"
    exit 2
    ;;
  1)
    OUTSTR="WARNING - There are some tunnel that fails to stablish connection to ${tun1}"
    echo -ne "${OUTSTR} | ${OUTPERF}"
    exit 1
    ;;
  [2-99]*)
    # mas de 1 tunnel con estado=2 (UP)
    OUTSTR="OK - At least ${NTUNNELS} tunnels stablished to ${tun1}"
    echo -ne "${OUTSTR} | ${OUTPERF}"
    exit 0
    ;;
esac
