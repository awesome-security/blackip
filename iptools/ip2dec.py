#!/usr/bin/env python

# How to use
# python ip2dec.py ip
# python ip2dec.py ipsfile

import sys
import os

def ip2int(ip):
  ip = [int(p) for p in ip.split(".")]
  return ip[0] << 24 | ip[1] << 16 | ip[2] << 8 | ip[3]


if __name__ == '__main__':
   if len(sys.argv) < 2:
       print "Error"
       exit(1)

   arg = sys.argv[1]
   if os.path.isfile(arg):
       ips = [ip.strip() for ip in open(arg).readlines()]
   else:
       ips = [arg]

   print "\n".join(str(ip2int(ip)) for ip in ips)
