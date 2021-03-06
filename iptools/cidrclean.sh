#!/bin/bash
### BEGIN INIT INFO
# Provides:          CIDR Clean
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts blackip update
# Description:       starts blackip using start-stop-daemon
### END INIT INFO

# by:	maravento.com and novatoz.com

route=/etc/acl
cidr=~/iptools

clear

# DOWNLOAD CIDRCLEAN
echo
echo "Download Path..."
svn export "https://github.com/maravento/blackip/trunk/tools" >/dev/null 2>&1
echo "OK"

cd $cidr

# IANA CIDR2IP
echo
echo "IANA CIDR Clean..."
echo "Warning: This operation consumes a lot of resources..."
chmod +x cidr2ip.py && python cidr2ip.py iana.txt > ianaip.txt
echo "OK"

# DOWNLOAD
echo
echo "Download Blackip..."
wget -q -c --retry-connrefused -t 0 https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz
wget -q -c --retry-connrefused -t 0 https://raw.githubusercontent.com/maravento/blackip/master/blackip.md5
echo "OK"
echo
echo "Checking Sum..."
a=$(md5sum blackip.tar.gz | awk '{print $1}')
b=$(cat blackip.md5 | awk '{print $1}')
	if [ "$a" = "$b" ]
	then 
		echo "Sum Matches"
        cat blackip.tar.gz | tar xzf -
	else
		echo "Bad Sum. Abort"
		echo "Blackip: Abort $date Check Internet Connection" >> /var/log/syslog
		exit
fi

# DEBBUGGING IANA
# https://en.wikipedia.org/wiki/Reserved_IP_addresses
# http://stackoverflow.com/a/35114656/3776858
echo
echo "Excluding IANA Reserved addresses from Blackip"
chmod +x debug.py && python debug.py
echo "OK"

# CIDR Clean
# https://superuser.com/questions/1148263/exclude-ips-from-a-range-to-avoid-conflict
echo
echo "Blackip CIDR Clean"
echo "Warning: This operation takes days. Be patient..."

common() {

  D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
  declare -i c=0                              # set integer attribute

  # read and convert IPs to binary
  IFS=./ read -r a1 a2 a3 a4 m <<< "$1"
  b1="${D2B[$a1]}${D2B[$a2]}${D2B[$a3]}${D2B[$a4]}"

  IFS=./ read -r a1 a2 a3 a4 m <<< "$2"
  b2="${D2B[$a1]}${D2B[$a2]}${D2B[$a3]}${D2B[$a4]}"

  # find number of same bits ($c) in both IPs from left, use $c as counter
  for ((i=0;i<32;i++)); do
    [[ ${b1:$i:1} == ${b2:$i:1} ]] && c=c+1 || break
  done    

  # create string with zeros
  for ((i=$c;i<32;i++)); do
    fill="${fill}0"
  done    

  # append string with zeros to string with identical bits to fill 32 bit again
  new="${b1:0:$c}${fill}"

  # convert binary $new to decimal IP with netmask
  new="$((2#${new:0:8})).$((2#${new:8:8})).$((2#${new:16:8})).$((2#${new:24:8}))/$c"
  echo "$new"
}

out="out.txt"
grep -vxFf <(
  grep -v / "$out" | while IFS= read -r ip1; do
    grep / "$out" | while IFS=/ read -r ip2 mask2; do
      out=$(common "$ip2/$mask2" "$ip1/32")
      out_mask="${out#*/}"
      if [[ $out_mask -ge $mask2 ]]; then   # -ge: greater-than-or-equal
        echo "$ip1"
      fi
    done
  done
) "$out" > clean.txt
sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n clean.txt | uniq > $route/blackip.txt
cd ..
rm -rf $cidr
echo "Done"
