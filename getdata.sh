#!  /bin/bash

SCR_DIR="/home/sysadmin/produccion/perf_data"

function fpingcount() {
        fping -g $1 -c 1 > $SCR_DIR/tmp 2>&1
        grep avg/ $SCR_DIR/tmp | wc -l
}

function trafico_dl(){
        bd="/var/lib/cacti/rra/sw-casa_traffic_in_8.rrd"
        dl=$(rrdtool graph x -s -10m -e now DEF:v=$bd:traffic_in:AVERAGE VDEF:vm=v,AVERAGE PRINT:vm:%8.2lf | tail -n 1)
        dl_k=$(echo "$dl*8/1000;scale=5" | bc)
        #dl_k en Kbps"
        echo "$dl_k"
}

function trafico_ul(){
        bd="/var/lib/cacti/rra/sw-casa_traffic_in_8.rrd"
        ul=$(rrdtool graph x -s -10m -e now DEF:v=$bd:traffic_out:AVERAGE VDEF:vm=v,AVERAGE PRINT:vm:%8.2lf | tail -n 1)
        ul_k=$(echo "$ul*8/1000;scale=5" | bc)
        #$ul_k en Kbps"
        echo "$ul_k"
}

function test_ping(){
	ping $1 -c 1 > /dev/null
	echo $?
}

function at_home(){
 /usr/sbin/arp | grep $1 > /dev/null
 if [ $? -eq 0 ]
  then
 	echo 1
  else
       echo 0
  fi
}

function get_oid(){
  snmpget -c Community -v 2c 192.168.0.11 $1 | awk '{print $4}'
}

cpu_us=$(sar 1 1 | grep Average | awk '{print $3}')  # en %
mem_free=$(free -m | grep Mem | awk '{print $4}')  # en MB
load_avg=$(cat /proc/loadavg | awk '{print $1}')  
disk_free=$(df -h | grep /dev/sda1 | awk  '{print $4}' | tr -d G) # en GB
disk_use=$(df -h | grep /dev/sda1 | awk  '{print $3}' | tr -d G)  # en GB
disp_red=$(fpingcount 192.168.0.0/24)
upl_kbps=$(trafico_ul)
dwl_kbps=$(trafico_dl)
access_log_count=$(wc  -l /var/log/apache2/access.log | awk '{print $1}')
procesos=$(ps -ef | wc -l)
login_users=$(w | grep user | awk -F "," '{print $3}' | awk '{print $1}')
mem_use=$(free -m | grep Mem | awk '{print $3}')
swap_use=$(free -m | grep Swap | awk '{print $3}')
timbre_status=$(test_ping 192.168.0.22)
tifrem_status=$(test_ping tifrem.ddns.net)
aless_at_home=$(at_home "8c:f5:a3:a0:f0:1f")
andrea_at_home=$(at_home "74:23:44:aa:e1:59")
temp_amb=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.1)
temp_cpu=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.2)
temp_mem_1=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.4)
temp_mem_2=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.5)
temp_hd=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.8)
temp_chipset=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.9)
temp_chipset_zone=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.10)
temp_ps1=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.11)
temp_ps2=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.12)
temp_hd_controller=$(get_oid iso.3.6.1.4.1.232.6.2.6.8.1.4.0.24)
ps1_input=$(get_oid iso.3.6.1.4.1.232.6.2.9.3.1.6.0.1)
ps2_input=$(get_oid iso.3.6.1.4.1.232.6.2.9.3.1.6.0.2)
power_watt=$(get_oid iso.3.6.1.4.1.232.6.2.9.3.1.7.0.2)


echo "$aless_at_home - $andrea_at_home $timbre_status " >> $SCR_DIR/data.txt

curl -i -XPOST "http://127.0.0.1:8086/write?db=MONITOREO" --data-binary "server,metrica=cpu_us value=$cpu_us
 server,metrica=mem_free value=$mem_free
 server,metrica=load_avg value=$load_avg
 server,metrica=disk_free value=$disk_free
 server,metrica=disk_use value=$disk_use
 server,metrica=disp_red value=$disp_red
 server,metrica=upl_kbps value=$upl_kbps
 server,metrica=dwl_kbps value=$dwl_kbps
 server,metrica=access_log_count value=$access_log_count
 server,metrica=procesos value=$procesos
 server,metrica=mem_use value=$mem_use
 server,metrica=swap_use value=$swap_use
 server,metrica=timbre_status value=$timbre_status
 server,metrica=tifrem_status value=$tifrem_status
 server,metrica=aless_athome value=$aless_at_home
 server,metrica=andrea_athome value=$andrea_at_home
 server,metrica=mlogin_users value=$login_users
 esxi,metrica=temp_amb value=$temp_amb
 esxi,metrica=temp_cpu value=$temp_cpu
 esxi,metrica=temp_mem_1 value=$temp_mem_1
 esxi,metrica=temp_mem_2 value=$temp_mem_2
 esxi,metrica=temp_hd value=$temp_hd
 esxi,metrica=temp_hd_controller value=$temp_hd_controller
 esxi,metrica=temp_chipset value=$temp_chipset
 esxi,metrica=temp_chipset_zone value=$temp_chipset_zone
 esxi,metrica=temp_ps1 value=$temp_ps1
 esxi,metrica=temp_ps2 value=$temp_ps2
 esxi,metrica=ps1_input value=$ps1_input
 esxi,metrica=ps2_input value=$ps2_input
 esxi,metrica=power_watt value=$power_watt"
