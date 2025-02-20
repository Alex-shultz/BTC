#!/bin/bash
##install ipfix balancer
yum install -y fast_ipfix_balancer
truncate -s0 /var/fast_ipfix_balancer/backend/.env 
echo "IPFIX_FULLFLOW_PORT_TYPE[0]=tcp
IPFIX_FULLFLOW_PORT[0]=1500
IPFIX_FULLFLOW_ROTATE_MINUTES[0]=10
IPFIX_FULLFLOW_DPI_ID[0]=-1
IPFIX_FULLFLOW_BALANCER[0]=roundrobin
IPFIX_FULLFLOW_BALANCER_SUB[0]=10.19.3.221/20401,10.19.3.222/20401,10.19.3.223/20401,10.19.3.224/20401
IPFIX_FULLFLOW_BALANCER_SUB_PROTO[0]=tcp
 
IPFIX_CLICKSTREAM_PORT_TYPE[0]=tcp
IPFIX_CLICKSTREAM_PORT[0]=1501
IPFIX_CLICKSTREAM_ROTATE_MINUTES[0]=12
IPFIX_CLICKSTREAM_DPI_ID[0]=-1
IPFIX_CLICKSTREAM_BALANCER[0]=roundrobin
IPFIX_CLICKSTREAM_BALANCER_SUB[0]=10.19.3.221/20402,10.19.3.222/20402
IPFIX_CLICKSTREAM_BALANCER_SUB_PROTO[0]=tcp
 
IPFIX_DNSFLOW_PORT_TYPE[0]=tcp
IPFIX_DNSFLOW_PORT[0]=1502
IPFIX_DNSFLOW_ROTATE_MINUTES[0]=10
IPFIX_DNSFLOW_DPI_ID[0]=-1
IPFIX_DNSFLOW_BALANCER[0]=roundrobin
IPFIX_DNSFLOW_BALANCER_SUB[0]=10.19.3.221/20403,10.19.3.222/20403
IPFIX_DNSFLOW_BALANCER_SUB_PROTO[0]=tcp
 
IPFIX_FULLFLOW_BALANCER_TASKSET[0]=61
IPFIX_CLICKSTREAM_BALANCER_TASKSET[0]=62
IPFIX_DNSFLOW_BALANCER_TASKSET[0]=63" >> /var/fast_ipfix_balancer/backend/.env

#update grub
sed -i '6s/.\{1\}$//' /etc/default/grub
sed -i  '6s/$/ default_hugepagesz=1G hugepagesz=1G hugepages=32 spectre_v2=off nopti elevator=deadline isolcpus=1-63"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
#install fastdpi
rpm --import http://vasexperts.ru/centos/RPM-GPG-KEY-vasexperts.ru
rpm -Uvh http://vasexperts.ru/centos/vasexperts-repo.noarch.rpm
yum install -y fastdpi net-tools wget sysstat rsyslog logrotate
systemctl enable fastdpi
systemctl --now enable chronyd

#import configuration
truncate -s0 /etc/dpi/fastdpi.conf 
echo "
udr=1
ctrl_port=29000
ctrl_dev=lo
scale_factor=10
num_threads=48
ipv6=1
ipv6_subnetwork=128
custom_url_black_list=http://10.1.1.111/blacklist.dict
custom_cname_black_list=http://10.1.1.111/blacklistcn.dict
custom_ip_black_list=http://10.1.1.111/blacklistip.dict
custom_sni_black_list=http://10.1.1.111/blacklistsni.dict
netflow=8
netflow_dev=lo
netflow_timeout=10
netflow_full_collector_type=2
netflow_full_collector=127.0.0.1:1500
set_packet_priority=1
support_service_18=1
ipfix_dev=lo
ipfix_tcp_collectors=127.0.0.1:1501
ajb_pcap_ind_mask=3
ipfix_dns_tcp_collectors=127.0.0.1:1502
in_dev=81-00.0:82-00.0:c1-00.0
out_dev=81-00.1:82-00.1:c1-00.1
vchannels_type=3
dpdk_engine=4
mem_ipv6_tracking_flow=32000000
mem_ipv6_tracking_ip=32000000
mem_tracking_flow=160000000
mem_tracking_ip=160000000
mem_ssl_parsers=15360000
snaplen=9200
hrbt_addr_server=10.1.1.100%bond0:3001
hrbt_timeout=10
hrbt_save_stat=1
cloud_id=bjxt8MSAYLDzGOG7EMJm
cloud_profile=test
vchannels_default=1
netflow_tos_format=1
udp_block=3
sds=1
sds_dev=lo
sds_sock_sndbuf=167772160
sds_size_sock_buf=10485760
sds_ajb_num=1
asnum_download=1
smartdrop=1
" >> /etc/dpi/fastdpi.conf
#SDS
touch /etc/dpi/fastdpi_sagents.json
echo "{
        "sd_agents" :
        [
                {
                        "ip" : "10.1.1.116",
                        "port" : 29000,
                        "speed" : "20GiBps",
                        "ifname" : "bond0",
                        "protocol" : 0,
                        "controllers" :
                        [
                                {
                                        "type" : 0,
                                        "disks" :
                                        [
                                                {
                                                        "speed" : "20GiBps",
                                                        "size"  : "44000gb",
                                                        "mount" : "/",
                                                        "typedata" : 0
                                                }
                                        ]
                                },
                                {
                                        "type" : 0,
                                        "disks" :
                                        [
                                                {
                                                        "speed" : "20GiBps",
                                                        "size"  : "44000gb",
                                                        "mount" : "/",
                                                        "typedata" : 1
                                                }
                                        ]
                                }

                        ]
                },
                {
                        "ip" : "10.1.1.116",
                        "port" : 29000,
                        "speed" : "20GiBps",
                        "ifname" : "bond0",
                        "protocol" : 0,
                        "controllers" :
                        [
                                {
                                        "type" : 0,
                                        "disks" :
                                        [
                                                {
                                                        "speed" : "20GiBps",
                                                        "size"  : "44000gb",
                                                        "mount" : "/",
                                                        "typedata" : 0
                                                }
                                        ]
                                },
                                {
                                        "type" : 0,
                                        "disks" :
                                        [
                                                {
                                                        "speed" : "20GiBps",
                                                        "size"  : "44000gb",
                                                        "mount" : "/",
                                                        "typedata" : 1
                                                }
                                        ]
                                }

                        ]
                }
        ]
}" >> /etc/dpi/fastdpi_sagents.json
service fastdpi restart
