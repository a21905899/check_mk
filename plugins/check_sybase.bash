#!/usr/bin/env bash


if [ `uname -s` == "SunOS" ] ; then
  GREP=/usr/bin/egrep
  CHECK_MK_CFG_DIR=/etc/check_mk
else
  GREP=/usr/bin/egrep
  # todo: anpassen, falls mal nicht auf Suse
  CHECK_MK_CFG_DIR=/etc/check_mk
fi


source $CHECK_MK_CFG_DIR/check_sybase.conf

PATH=$PATH:$SYBASE/$SYBASE_ASE/bin
PATH=$PATH:$SYBASE/$SYBASE_OCS/bin
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SYBASE/$SYBASE_ASE/lib:$SYBASE/$SYBASE_OCS/lib
LANG=C

export SYBASE SYBASE_ASE PATH LD_LIBRARY_PATH SQL_TIMEOUT SYBASE_USER SYBASE_PASSWORD SYBASE_SERVER GREP CHECK_MK_CFG_DIR LANG

sql () {
  SQLOUT=`echo -e "$1 \ngo\n" | isql -U $SYBASE_USER -P $SYBASE_PASSWORD -b -w 1024 -s "," -S $SYBASE_SERVER 2>/dev/null`
  SQLEXIT=$?
  if [ $SQLEXIT -eq 0 ] ; then
    SQLERR=`echo $SQLOUT | $GREP -e "Msg .*, Level .*, State .*"`
    if [ "$SQLERR" ] ; then
       SQLEXIT=1
    fi
  fi
}

condout () {
  
  if [ $SQLEXIT -eq 0 ] ; then
    echo "$SQLOUT" | $GREP -v -e '^$' | $GREP -v -e "rows? affected" | $GREP -v "return status" | sed "s@^@$SYBASE_SERVER @"
  fi
}


echo "<<<sybase_databases:sep(44)>>>"

# https://benohead.com/sybase-size-of-data-and-log-segments-for-all-databases/

sql 'select db_name(d.dbid) as db_name,
sum(case when u.segmap != 4 then u.size/1048576.*@@maxpagesize end ) as data_size,
sum(case when u.segmap != 4 then size - curunreservedpgs(u.dbid, u.lstart, u.unreservedpgs) end/1048576.*@@maxpagesize) as data_used,
sum(case when u.segmap = 4 then u.size/1048576.*@@maxpagesize end) as log_size,
sum(case when u.segmap = 4 then u.size/1048576.*@@maxpagesize end) - lct_admin("logsegment_freepages",d.dbid)/1048576.*@@maxpagesize as log_used,
status, status2, status3, status4
from master..sysdatabases d, master..sysusages u
where u.dbid = d.dbid  and d.status != 256
group by d.dbid'

condout

echo "<<<sybase_users:sep(44)>>>"
sql 'select count(status),status from master..sysprocesses group by status'
condout
sql 'select c.value, b.name from master.dbo.sysconfigures b, master.dbo.syscurconfigs c where b.config = c.config and (b.name="number of user connections" or b.name="max online engines")'
condout

echo "<<<sybase_locks:sep(44)>>>"
sql 'select distinct type , count(type) from master..syslocks group by type'
if echo "$SQLOUT" |grep "(0 rows affected)" > /dev/null ; then
  SQLOUT=",0,0" # fake for inventory
fi
condout

# http://www.petersap.nl/SybaseWiki/index.php?title=MDA_tables_-_queries_for_data_caches
echo "<<<sybase_cache:sep(44)>>>"
sql 'select CacheName,
       convert(numeric(4,1),100-((convert(numeric(12,2),PhysicalReads)/convert(numeric(12,2),CacheSearches))*100))
       PhysicalWrites
       from monDataCache
       where   PhysicalReads <= CacheSearches
       order   by CacheName'
condout

