# Port forwarding

Useful for my router setup to access pfSense from my home side LAN

ssh -L LOCAL_PORT_NUM:SECOND_ROUTER_IP:FORWARDED_PORT user@SECOND_ROUTER_WAN_IP -p PORT_SSH_IS_ON

eg. to do https, forwarded port is 443.  WAN ip is the incoming network, router IP is it's internal network.
