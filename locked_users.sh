#!/bin/bash
echo "<<<local:sep(9)>>>"
while read i1
do 
passwd -S $i1 | awk '/LK/{print "2\tUSERACCOUNT STATUS LOCKED " $1"\t-\t" $0 }/PS/{print "0\tUSERACCOUNT STATUS PASSWORD SAVED " $1"\t-\t" $0 }/NP/{print "0\tUSERACCOUNT STATUS NO PASSWORD " $1"\t-\t" $0 }'

done <<EOF
gest
EOF



