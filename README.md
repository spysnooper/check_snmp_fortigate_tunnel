####
# check_snmp_fortigate_tunnel.sh

####
# Installation
/usr/lib64/nagios/plugins by default the place where you usually copy this script
# permisions that usually has this script
sudo chmod -c 755 /usr/lib64/nagios/plugins/check_snmp_fortigate_tunnel.sh
sudo chown -c root:root /usr/lib64/nagios/plugins/check_snmp_fortigate_tunnel.sh


####
# Usage
/usr/lib64/nagios/plugins/check_snmp_fortigate_tunnel.sh -H <hostaddress> -C <snmp_community_string> -A <main_tunnel_ipv4_pub_address>

# Arguments explained
<hostaddress> is Fortigate you want to query by SNMP

<snmp_community_string> the SNMP community you have configured in the Fortigate

<main_tunnel_ipv4_pub_address> the IP of the Endpoint/Gateway VPN that you want to be connected from Fortigate HOST
