#!/bin/sh

HERE=`pwd`
(cd ~; tar cfz $HERE/dotssh.tgz .ssh)
mcrypt -m ECB -a rijndael-128 dotssh.tgz
uuencode dotssh.tgz.nc dotssh.tgz.nc > cruft.uue
rm -f dotssh.tgz*
