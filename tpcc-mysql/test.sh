# real utilization 49%

ERROR=0

CDATE=`date '+%y%m%d'`
BENCHMARK=copytar

/etc/init.d/mysqld stop
rm -rf /mysql/*

#	echo -e "n\n\n\n\n+64G\nw\n" | fdisk /dev/sdc
#mkfs.ext4 /dev/sdc1
#mount /dev/sdc1 /mysql

echo "filecopy Statr"
cp -r ~/tpcc/data /mysql/
#mv /mysql/data_tpcc_100 /mysql/data
cd ~/MySQL/tpcc-mysql/
cp my.cnf /etc/
cp my.cnf /etc/mysql/
cp my.cnf /mysql/

cd ../mysql-5.6.14
make -j9
make install

mkdir -p /mysql/InnoDB/redoLogs
mkdir -p /mysql/InnoDB/undoLogs
mkdir -p /mysql/InnoDB/ib_data
chgrp -R mysql /mysql
chown -R mysql /mysql/data
mkdir /mysql/logs /mysql/tmp
chown mysql-lxc:mysql-lxc /mysql/tmp
chown mysql-lxc:mysql-lxc /mysql/logs

cd /mysql/scripts
#cp /mysql/share/english/errmsg.sys /usr/share/mysql/errmsg.sys
chown -R mysql-lxc:mysql-lxc /mysql
./mysql_install_db --basedir=/mysql --user=mysql-lxc --datadir=/mysql/data

cd /mysql/support-files
cp mysql.server /etc/init.d/mysqld

update-rc.d mysqld defaults
echo "/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
cd /mysql
ln -s lib lib64

rm /usr/local/bin/mysql*
ln -s /mysql/bin/mysql /usr/local/bin/mysql
ln -s /mysql/bin/mysqladmin /usr/local/bin/mysqladmin
ln -s /mysql/bin/mysqldump /usr/local/bin/mysqldump
ln -s /mysql/bin/mysql_config /usr/local/bin/mysql_config

cp /mysql/bin/mysqld_safe /usr/bin/mysqld_safe
systemctl daemon-reload
/etc/init.d/mysqld start

#echo 3 > /proc/sys/vm/drop_caches
#cd /home/somnode/MySQL/tpcc-mysql
cd /root/MySQL/tpcc-mysql
echo "FILEBENCH START"
LD_LIBRARY_PATH=/mysql/lib/ ./tpcc_start -h 0.0.0.0 -P 3306 -d tpcc100 -u root -p "" -w 100 -c 30 -r 120 -l 600 > ~/tpcc/tpcc.trace
echo "FILEBENCH END"
